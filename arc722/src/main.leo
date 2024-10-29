/*

    Collection registry for NFTs with public/private data and public/private owner.

*/


program nft_registry.aleo {
    struct CollectionMetadata {
        collection_id: field,
        base_uri: [field; 4],
        metadata_uri: [field; 4]
    }

    struct Approval {
        collection_id: field,
        approver: address,
        spender: address,
    }

    struct NFTId {
        collection_id: field,
        nft_commit: field
    }

    struct NFTContent {
        data: field,
        edition: scalar
    }

    record NFT {
        private owner: address,
        private collection_id: field,
        private data: field,
        private edition: scalar,
    }

    record Authorization {
        private owner: address,
        private collection_id: field
    }

    record NFTView {
        private owner: address,
        private data: field,
        private edition: scalar,
        public is_view: bool,
    }

    mapping nft_ids: field => NFTId; 
    // hash(NFTId) => NFTId

    mapping nft_owners: field => address;
    // hash(NFTId) => NFT owner

    mapping for_all_approvals: field => bool; 
    // hash(Approval) => Is approved

    mapping nft_approvals: field => field; 
    // hash(NFTId) => hash(Approval)

    mapping registered_collections: field => CollectionMetadata;
    // Collection ID => Collection Metadata

    mapping collection_admins: field => address;
    // Collection ID => Collection Admin

    mapping nft_contents: field => NFTContent;
    // commit(data, edition) => (data, edition)


    inline commit_nft(
        nft_data: field,
        nft_edition: scalar
    ) -> field {
        let data_hash: field = BHP256::hash_to_field(nft_data);
        let commitment: field = BHP256::commit_to_field(data_hash, nft_edition);
        return commitment;
    }
    
    inline hash_nft_id(
        collection_id: field,
        nft_data: field,
        nft_edition: scalar,
    ) -> field {
        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let nft_id: NFTId = NFTId {
            collection_id: collection_id,
            nft_commit: nft_commit
        };
        let nft_id_hash: field = BHP256::hash_to_field(nft_id);
        return nft_id_hash;
    }

    inline hash_approval(
        collection_id: field,
        approver: address,
        spender: address,
    ) -> field {
        let apvl: Approval = Approval {
            collection_id: collection_id,
            approver: approver,
            spender: spender
        };
        let apvl_hash: field = BHP256::hash_to_field(apvl);
        return apvl_hash;
    }

    /*
        *********************************************************************
        ******************** Called by collection admin *********************
        *********************************************************************
    */

    async transition register_collection(
        public collection_id: field,
        public base_uri: [field; 4],
        public metadata_uri: [field; 4]
    ) -> Future {
        let collection: CollectionMetadata = CollectionMetadata {
            collection_id: collection_id,
            base_uri: base_uri,
            metadata_uri: metadata_uri
        };
        return finalize_register_collection(collection, self.caller);
    }
    async function finalize_register_collection(
        collection: CollectionMetadata,
        admin: address
    ) {
        let collection_exists: bool = registered_collections.contains(collection.collection_id);
        assert(collection_exists.not());
        registered_collections.set(collection.collection_id, collection);
        collection_admins.set(collection.collection_id, admin);
    }


    async transition mint_authorization_as_signer(
        public collection_id: field,
        private nft_data: field,
        private nft_edition: scalar,
    ) -> (Authorization, Future) {
        let authorization: Authorization = Authorization {
            owner: self.signer,
            collection_id: collection_id,
        };
        let mint_authorization_future: Future = 
            finalize_mint_authorization_as_signer(collection_id, self.caller);
        return (authorization, mint_authorization_future);
    }
    async function finalize_mint_authorization_as_signer(
        collection_id: field,
        caller: address
    ) {
        let admin: address = collection_admins.get(collection_id);
        assert_eq(admin, caller);
    }


    async transition update_admin(
        public collection_id: field,
        public new_admin: address
    ) -> Future {
        let update_admin_future: Future = 
            finalize_update_admin(collection_id, self.caller, new_admin);
        return update_admin_future;
    }
    async function finalize_update_admin(
        collection_id: field,
        caller: address,
        new_admin: address
    ) {
        let admin: address = collection_admins.get(collection_id);
        assert_eq(admin, caller);
        collection_admins.set(collection_id, new_admin);
    }


    transition burn_authorization(authorization: Authorization) {
        assert(true);
    }


    async transition auth_mint_private(
        authorization: Authorization,
        private recipient: address,
        private nft_data: field,
        private nft_edition: scalar,
    ) -> (Authorization, NFT, Future) {
        let new_authorization: Authorization = Authorization {
            owner: authorization.owner,
            collection_id: authorization.collection_id,
        };
        let nft: NFT = NFT {
            owner: recipient,
            collection_id: authorization.collection_id,
            data: nft_data,
            edition: nft_edition
        };
        
        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let nft_id: NFTId = NFTId {
            collection_id: nft.collection_id,
            nft_commit: nft_commit
        };
        let nft_id_hash: field = BHP256::hash_to_field(nft_id);

        let auth_mint_private_future: Future = 
            finalize_auth_mint_private(nft_id_hash, nft_id);
        return (new_authorization, nft, auth_mint_private_future);
    }
    async function finalize_auth_mint_private(
        nft_id_hash: field,
        nft_id: NFTId
    ) {
        assert(nft_ids.contains(nft_id_hash).not());
        nft_ids.set(nft_id_hash, nft_id);
    }


    transition auth_burn_private(
        authorization: Authorization,
        nft: NFT
    ) -> Authorization {
        assert_eq(authorization.collection_id, nft.collection_id);
        let new_authorization: Authorization = Authorization {
            owner: authorization.owner,
            collection_id: authorization.collection_id,
        };
        return new_authorization;
    }


    async transition mint_private(
        private recipient: address,
        private collection_id: field,
        private nft_data: field,
        private nft_edition: scalar,
    ) -> (NFT, Future) {
        let nft: NFT = NFT {
            owner: recipient,
            collection_id: collection_id,
            data: nft_data,
            edition: nft_edition
        };
        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let nft_id: NFTId = NFTId {
            collection_id: nft.collection_id,
            nft_commit: nft_commit
        };
        let nft_id_hash: field = BHP256::hash_to_field(nft_id);
        let mint_future: Future = 
            finalize_mint_private(collection_id, self.caller, nft_id_hash, nft_id);
        return (nft, mint_future);
    }
    async function finalize_mint_private(
        collection_id: field,
        caller: address,
        nft_id_hash: field,
        nft_id: NFTId
    ) {
        let admin: address = collection_admins.get(collection_id);
        assert_eq(admin, caller);
        assert(nft_ids.contains(nft_id_hash).not());
        nft_ids.set(nft_id_hash, nft_id);
    }


    async transition burn_private(
        nft: NFT
    ) -> Future {
        let burn_authorization_future: Future = 
            finalize_burn_private(nft.collection_id, self.caller);
        return burn_authorization_future;
    }
    async function finalize_burn_private(
        collection_id: field,
        caller: address
    ) {
        let admin: address = collection_admins.get(collection_id);
        assert_eq(admin, caller);
    }


    async transition auth_mint_public(
        authorization: Authorization,
        public recipient: address,
        private nft_data: field,
        private nft_edition: scalar,
    ) -> (NFTView, Authorization, Future) {
        let new_authorization: Authorization = Authorization {
            owner: authorization.owner,
            collection_id: authorization.collection_id,
        };
        let nft_view: NFTView = NFTView {
            owner: recipient,
            data: nft_data,
            edition: nft_edition,
            is_view: true
        };
        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let nft_id: NFTId = NFTId {
            collection_id: authorization.collection_id,
            nft_commit: nft_commit
        };
        let nft_id_hash: field = BHP256::hash_to_field(nft_id);

        let auth_mint_public_future: Future = 
            finalize_auth_mint_public(nft_id_hash, nft_id, recipient);
        return (nft_view, new_authorization, auth_mint_public_future);
    }
    async function finalize_auth_mint_public(
        nft_id_hash: field,
        nft_id: NFTId,
        recipient: address
    ) {
        assert(nft_ids.contains(nft_id_hash).not());
        nft_ids.set(nft_id_hash, nft_id);
        nft_owners.set(nft_id_hash, recipient);
    }


    async transition mint_public(
        public recipient: address,
        public collection_id: field,
        private nft_data: field,
        private nft_edition: scalar,
    ) -> (NFTView, Future) {
        let nft_view: NFTView = NFTView {
            owner: recipient,
            data: nft_data,
            edition: nft_edition,
            is_view: true
        };
        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let nft_id: NFTId = NFTId {
            collection_id: collection_id,
            nft_commit: nft_commit
        };
        let nft_id_hash: field = BHP256::hash_to_field(nft_id);

        let mint_public_future: Future = 
            finalize_mint_public(collection_id, self.caller, nft_id_hash, nft_id, recipient);
        return (nft_view, mint_public_future);
    }
    async function finalize_mint_public(
        collection_id: field,
        caller: address,
        nft_id_hash: field,
        nft_id: NFTId,
        recipient: address,
    ) {
        let admin: address = collection_admins.get(collection_id);
        assert_eq(admin, caller);
        assert(nft_ids.contains(nft_id_hash).not());
        nft_ids.set(nft_id_hash, nft_id);
        nft_owners.set(nft_id_hash, recipient);
    }
    /*
        *********************************************************************
        ********************** Called by token owner ************************
        *********************************************************************
    */


    transition transfer_private(
        private nft: NFT,
        private recipient: address,
    ) -> NFT {
        return NFT {
            owner: recipient,
            collection_id: nft.collection_id,
            data: nft.data,
            edition: nft.edition,
        };
    }
    

    async transition transfer_private_to_public(
        nft: NFT,
        public recipient: address,
    ) -> (NFTView, Future) {
        let nft_view: NFTView = NFTView {
            owner: recipient,
            data: nft.data,
            edition: nft.edition,
            is_view: true
        };
        let nft_id_hash: field = hash_nft_id(nft.collection_id, nft.data, nft.edition);
        let transfer_private_to_public_future: Future =
            finalize_transfer_private_to_public(
                recipient, nft_id_hash
            );
        return (
            nft_view,
            transfer_private_to_public_future
        );
    }
    async function finalize_transfer_private_to_public(
        recipient: address,
        nft_id_hash: field,
    ){
        nft_owners.set(
            nft_id_hash,
            recipient,
        );
    }


    async transition transfer_public(
        private collection_id: field,
        private nft_data: field,
        private nft_edition: scalar,
        public recipient: address,
    ) -> (NFTView, Future) {
        let caller: address = self.caller;
        let nft_view: NFTView = NFTView {
            owner: recipient,
            data: nft_data,
            edition: nft_edition,
            is_view: true
        };
        let nft_id_hash: field = hash_nft_id(collection_id, nft_data, nft_edition);
        let transfer_public_future: Future = finalize_transfer_public(
             recipient, nft_id_hash, caller,
        );
        return (
            nft_view,
            transfer_public_future
        );
    }
    async function finalize_transfer_public(
        recipient: address,
        nft_id_hash: field,
        caller: address,
    ) {
        let owner: address = nft_owners.get(nft_id_hash);
        assert_eq(caller, owner);
        nft_approvals.remove(nft_id_hash);
        nft_owners.set(nft_id_hash, recipient);
    }


    async transition transfer_public_as_signer(
        private collection_id: field,
        private nft_data: field,
        private nft_edition: scalar,
        public recipient: address,
    ) -> (NFTView, Future) {
        let signer: address = self.signer;
        let nft_view: NFTView = NFTView {
            owner: recipient,
            data: nft_data,
            edition: nft_edition,
            is_view: true
        };

        let nft_id_hash: field = hash_nft_id(collection_id, nft_data, nft_edition);
        let transfer_public_as_signer_future: Future = finalize_transfer_public_as_signer(
             recipient, nft_id_hash, signer,
        );
        return (
            nft_view,
            transfer_public_as_signer_future
        );
    }
    async function finalize_transfer_public_as_signer(
        recipient: address,
        nft_id_hash: field,
        signer: address,
    ) {
        let owner: address = nft_owners.get(nft_id_hash);
        assert_eq(signer, owner);
        nft_approvals.remove(nft_id_hash);
        nft_owners.set(nft_id_hash, recipient);
    }


    async transition transfer_public_to_private(
        private collection_id: field,
        private nft_data: field,
        private nft_edition: scalar,
        private recipient: address,
    ) -> (NFT, Future) {
        let nft_id_hash: field = hash_nft_id(collection_id, nft_data, nft_edition);
        let caller: address = self.caller;
        let finalize_future: Future = finalize_transfer_public_to_private(
            caller, nft_id_hash,
        );
        let received_nft: NFT = NFT {
            owner: recipient,
            collection_id: collection_id,
            data: nft_data,
            edition: nft_edition,
        };
        return (received_nft, finalize_future);
    }
    async function finalize_transfer_public_to_private(
        caller: address,
        nft_id_hash: field,
    ){
        let owner: address = nft_owners.get(nft_id_hash);
        assert_eq(caller, owner);
        nft_approvals.remove(nft_id_hash);
        nft_owners.remove(nft_id_hash);
    }


    async transition set_for_all_approval(
        private collection_id: field,
        private spender: address,
        public new_value: bool,
    ) -> Future {
        let apvl_hash: field = hash_approval(collection_id, self.caller, spender);
        return finalize_set_for_all_approval(
            apvl_hash, new_value
        );
    }
    async function finalize_set_for_all_approval(
        apvl_hash: field,
        new_value: bool,
    ){
        for_all_approvals.set(apvl_hash, new_value);
    }

    
    async transition approve_public(
        private collection_id: field,
        private spender: address,
        private nft_data: field,
        private nft_edition: scalar,
    ) -> Future {
        let nft_id_hash: field = hash_nft_id(collection_id, nft_data, nft_edition);
        let apvl_hash: field = hash_approval(collection_id, self.caller, spender);

        return finalize_approve_public(
            self.caller, apvl_hash, nft_id_hash,
        );
    }
    async function finalize_approve_public(
        caller: address,
        apvl_hash: field,
        nft_id_hash: field,
    ){
        let owner: address = nft_owners.get(nft_id_hash);
        assert_eq(owner, caller);
        nft_approvals.set(nft_id_hash, apvl_hash);
    }


    async transition unapprove_public(
        private collection_id: field,
        private nft_data: field,
        private nft_edition: scalar,
    ) -> Future {
        let nft_id_hash: field = hash_nft_id(collection_id, nft_data, nft_edition);

        return finalize_unapprove_public(
            self.caller, nft_id_hash,
        );
    }
    async function finalize_unapprove_public(
        caller: address,
        nft_id_hash: field,
    ){
        let owner: address = nft_owners.get(nft_id_hash);
        assert_eq(owner, caller);
        nft_approvals.remove(nft_id_hash);
    }


    async transition transfer_from_public(
        private collection_id: field,
        public from: address,
        public recipient: address,
        private nft_data: field,
        private nft_edition: scalar,
    ) -> (NFTView, Future) {
        let nft_id_hash: field = hash_nft_id(collection_id, nft_data, nft_edition);
        let apvl_hash: field = hash_approval(collection_id, from, self.caller);
        let transfer_from_public_future: Future =
            finalize_transfer_from_public(apvl_hash, from, recipient, nft_id_hash);

        let nft_view: NFTView = NFTView {
            owner: recipient,
            data: nft_data,
            edition: nft_edition,
            is_view: true
        };
        return (
            nft_view,
            transfer_from_public_future
        );
    }
    async function finalize_transfer_from_public(
        apvl_hash: field,
        from: address,
        recipient: address,
        nft_id_hash: field,
    ) {
        assert(
            nft_approvals.contains(nft_id_hash)
            || for_all_approvals.get_or_use(apvl_hash, false)
        );

        let owner: address = nft_owners.get(nft_id_hash);
        assert_eq(from, owner);
        
        nft_approvals.remove(nft_id_hash);
        nft_owners.set(nft_id_hash, recipient);
    }


    async transition update_edition_private(
        private nft: NFT,
        private new_edition: scalar,
    ) -> (NFT, Future) {
        let out_nft: NFT = NFT {
            owner: nft.owner,
            collection_id: nft.collection_id,
            data: nft.data,
            edition: new_edition,
        };

        let nft_commit: field = commit_nft(nft.data, new_edition);
        let nft_id: NFTId = NFTId {
            collection_id: nft.collection_id,
            nft_commit: nft_commit
        };
        let nft_id_hash: field = BHP256::hash_to_field(nft_id);
        let update_edition_private_future: Future = finalize_update_edition_private(
            nft_id_hash, nft_id
        );
        return (out_nft, update_edition_private_future);
    }
    async function finalize_update_edition_private(
        nft_id_hash: field, nft_id: NFTId
    ) {
        assert(nft_ids.contains(nft_id_hash).not());
        nft_ids.set(nft_id_hash, nft_id);
    }


    async transition publish_nft_content(
        public nft_data: field,
        public nft_edition: scalar,
    ) -> Future {
        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let public_data: NFTContent = NFTContent {
            data: nft_data,
            edition: nft_edition
        };
        let publish_nft_content_future: Future = finalize_publish_nft_content(
            nft_commit,
            public_data
        );
        return publish_nft_content_future;
    }
    async function finalize_publish_nft_content(
        nft_commit: field,
        public_data: NFTContent
    ) {
        nft_contents.set(nft_commit, public_data);
    }
}