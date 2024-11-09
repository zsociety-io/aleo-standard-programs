/*

    Collection registry for NFTs with public/private data and public/private owner.

*/


program nft_registry.aleo {
    const ADMIN_NFTS_RESERVED_COLLECTION_ID: field = 0field;
    const ADMIN_NFTS_EDITION: scalar = 0scalar;

    struct CollectionMetadata {
        collection_id: field,
        base_uri: [field; 4],
        metadata_uri: [field; 4]
    }

    struct Data {
        metadata: [field; 4]
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
        data: Data,
        edition: scalar
    }

    record NFT {
        private owner: address,
        private collection_id: field,
        private data: Data,
        private edition: scalar,
    }

    record Authorization {
        private owner: address,
        private collection_id: field
    }

    record NFTView {
        private owner: address,
        private data: Data,
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

    mapping nft_contents: field => NFTContent;
    // commit(data, edition) => (data, edition)


    inline commit_nft(
        nft_data: Data,
        nft_edition: scalar
    ) -> field {
        let data_hash: field = BHP256::hash_to_field(nft_data);
        let commitment: field = BHP256::commit_to_field(data_hash, nft_edition);
        return commitment;
    }
    
    inline hash_nft_id(
        collection_id: field,
        nft_data: Data,
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

    inline null_metadata() -> [field; 4] {
        return [0field, 0field, 0field, 0field];
    }

    inline field_nft_data(collection_id: field) -> Data {
        return Data {
            metadata: [collection_id, 0field, 0field, 0field]
        };
    }

    inline hash_admin_nft_id(collection_id: field) -> field {
        let nft_data: Data = field_nft_data(collection_id);
        let admin_nft_id_hash: field = hash_nft_id(
            ADMIN_NFTS_RESERVED_COLLECTION_ID,
            nft_data,
            ADMIN_NFTS_EDITION
        );
        return admin_nft_id_hash;
    }


    /*
        *********************************************************************
        ******************** Called by collection admin *********************
        *********************************************************************
    */

    async transition initialize() -> Future {
        let field_nft_data: Data = field_nft_data(ADMIN_NFTS_RESERVED_COLLECTION_ID);
        let admin_nft_commit: field = commit_nft(field_nft_data, ADMIN_NFTS_EDITION);
        let admin_nft_id: NFTId = NFTId {
            collection_id: ADMIN_NFTS_RESERVED_COLLECTION_ID,
            nft_commit: admin_nft_commit
        };
        let admin_nft_id_hash: field = BHP256::hash_to_field(admin_nft_id);

        return finalize_initialize(
             admin_nft_id_hash, admin_nft_id
        );
    }
    async function finalize_initialize(
        admin_nft_id_hash: field,
        admin_nft_id: NFTId,
    ) {
        let collection: CollectionMetadata = CollectionMetadata {
            collection_id: ADMIN_NFTS_RESERVED_COLLECTION_ID,
            base_uri: null_metadata(),
            metadata_uri: null_metadata()
        };
        // Register collection for "admin" NFTs.
        let collection_exists: bool = registered_collections.contains(
            ADMIN_NFTS_RESERVED_COLLECTION_ID
        );
        assert(collection_exists.not());
        registered_collections.set(
            ADMIN_NFTS_RESERVED_COLLECTION_ID, collection
        );

        // Mint "admin" NFT of the "admin" NFTs collection
        // Recipient is the registry program itself.
        assert(nft_ids.contains(admin_nft_id_hash).not());
        nft_ids.set(admin_nft_id_hash, admin_nft_id);
        nft_owners.set(admin_nft_id_hash, self.address);
    }


    async transition register_collection_public(
        public collection_id: field,
        public base_uri: [field; 4],
        public metadata_uri: [field; 4]
    ) -> (NFTView, Future) {
        assert(collection_id != 0field);
        let collection: CollectionMetadata = CollectionMetadata {
            collection_id: collection_id,
            base_uri: base_uri,
            metadata_uri: metadata_uri
        };

        let nft_data: Data = field_nft_data(collection_id);
        let admin_nft_view: NFTView = NFTView {
            owner: self.caller,
            data: nft_data,
            edition: ADMIN_NFTS_EDITION,
            is_view: true
        };

        // Compute details of "admin" NFT of the collection, recipient is the caller.
        let nft_commit: field = commit_nft(nft_data, ADMIN_NFTS_EDITION);
        let nft_id: NFTId = NFTId {
            collection_id: ADMIN_NFTS_RESERVED_COLLECTION_ID,
            nft_commit: nft_commit
        };
        let nft_id_hash: field = BHP256::hash_to_field(nft_id);
        let register_collection_public_future: Future = 
            finalize_register_collection_public(
                collection, nft_id_hash, nft_id, self.caller
            );
        return (admin_nft_view, register_collection_public_future);
    }
    async function finalize_register_collection_public(
        collection: CollectionMetadata,
        nft_id_hash: field,
        nft_id: NFTId,
        admin: address
    ) {
        // Check collection does not exist yet
        let collection_exists: bool = registered_collections.contains(
            collection.collection_id
        );
        assert(collection_exists.not());

        // Register collection
        registered_collections.set(collection.collection_id, collection);

        // Check that "admin" NFT of the collection does not exist yet (redundant)
        assert(nft_ids.contains(nft_id_hash).not());

        // Register "admin" NFT of the collection.
        nft_ids.set(nft_id_hash, nft_id);
        // Mint "admin" NFT of the collection, recipient is the caller.
        nft_owners.set(nft_id_hash, admin);
    }


    async transition register_collection_private(
        public collection_id: field,
        public base_uri: [field; 4],
        public metadata_uri: [field; 4]
    ) -> (NFT, Future) {
        assert(collection_id != 0field);
        let collection: CollectionMetadata = CollectionMetadata {
            collection_id: collection_id,
            base_uri: base_uri,
            metadata_uri: metadata_uri
        };
        // Mint "admin" NFT of the collection, recipient is the signer.
        let nft_data: Data = field_nft_data(collection_id);
        let admin_nft: NFT = NFT {
            owner: self.signer,
            collection_id: ADMIN_NFTS_RESERVED_COLLECTION_ID,
            data: nft_data,
            edition: ADMIN_NFTS_EDITION
        };
        let nft_commit: field = commit_nft(nft_data, ADMIN_NFTS_EDITION);
        let nft_id: NFTId = NFTId {
            collection_id: ADMIN_NFTS_RESERVED_COLLECTION_ID,
            nft_commit: nft_commit
        };
        let nft_id_hash: field = BHP256::hash_to_field(nft_id);

        let register_collection_private_future: Future = 
            finalize_register_collection_private(
                collection, nft_id_hash, nft_id
            );
        return (admin_nft, register_collection_private_future);
    }
    async function finalize_register_collection_private(
        collection: CollectionMetadata,
        nft_id_hash: field,
        nft_id: NFTId,
    ) {
        // Check collection does not exist yet
        let collection_exists: bool = registered_collections.contains(
            collection.collection_id
        );
        assert(collection_exists.not());

        // Register collection
        registered_collections.set(collection.collection_id, collection);

        // Register "admin" NFT of the collection.
        assert(nft_ids.contains(nft_id_hash).not());
        nft_ids.set(nft_id_hash, nft_id);
    }


    async transition update_collection_private(
        admin_nft: NFT,
        public new_base_uri: [field; 4],
        public new_metadata_uri: [field; 4]
    ) -> (NFT, Future) {
        assert_eq(admin_nft.collection_id, ADMIN_NFTS_RESERVED_COLLECTION_ID);
        let collection_id: field = admin_nft.data.metadata[0u8];

        let new_admin_nft: NFT = NFT {
            owner: admin_nft.owner,
            collection_id: admin_nft.collection_id,
            data: admin_nft.data,
            edition: admin_nft.edition
        };
        let new_collection_data: CollectionMetadata = CollectionMetadata {
            collection_id: collection_id,
            base_uri: new_base_uri,
            metadata_uri: new_metadata_uri
        };
        let update_collection_future: Future = 
            finalize_update_collection_private(new_collection_data);
        return (new_admin_nft, update_collection_future);
    }
    async function finalize_update_collection_private(
        new_collection_data: CollectionMetadata
    ) {
        registered_collections.set(
            new_collection_data.collection_id, new_collection_data
        );
    }


    async transition update_collection_public(
        public collection_id: field,
        public new_base_uri: [field; 4],
        public new_metadata_uri: [field; 4]
    ) -> Future {
        let new_collection_data: CollectionMetadata = CollectionMetadata {
            collection_id: collection_id,
            base_uri: new_base_uri,
            metadata_uri: new_metadata_uri
        };
        let admin_nft_id_hash: field = hash_admin_nft_id(collection_id);
        let update_collection_public_future: Future = 
            finalize_update_collection_public(
                collection_id, self.caller, admin_nft_id_hash, new_collection_data
            );
        return update_collection_public_future;
    }
    async function finalize_update_collection_public(
        collection_id: field,
        caller: address,
        admin_nft_id_hash: field,
        new_collection_data: CollectionMetadata
    ) {
        let admin: address = nft_owners.get(admin_nft_id_hash);
        assert_eq(admin, caller);
        registered_collections.set(collection_id, new_collection_data);
    }


    async transition mint_private(
        admin_nft: NFT,
        private recipient: address,
        private nft_data: Data,
        private nft_edition: scalar,
    ) -> (NFT, NFT, Future) {
        assert_eq(admin_nft.collection_id, ADMIN_NFTS_RESERVED_COLLECTION_ID);
        let collection_id: field = admin_nft.data.metadata[0u8];

        let new_admin_nft: NFT = NFT {
            owner: admin_nft.owner,
            collection_id: admin_nft.collection_id,
            data: admin_nft.data,
            edition: admin_nft.edition
        };
        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let nft_id: NFTId = NFTId {
            collection_id: collection_id,
            nft_commit: nft_commit
        };
        let nft_id_hash: field = BHP256::hash_to_field(nft_id);
        let minted_nft: NFT = NFT {
            owner: recipient,
            collection_id: collection_id,
            data: nft_data,
            edition: nft_edition
        };

        let mint_private_future: Future = 
            finalize_mint_private(nft_id_hash, nft_id);
        return (minted_nft, new_admin_nft, mint_private_future);
    }
    async function finalize_mint_private(
        nft_id_hash: field,
        nft_id: NFTId
    ) {
        assert(nft_ids.contains(nft_id_hash).not());
        nft_ids.set(nft_id_hash, nft_id);
    }


    async transition mint_private_as_public(
        private recipient: address,
        private collection_id: field,
        private nft_data: Data,
        private nft_edition: scalar,
    ) -> (NFT, Future) {
        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let nft_id: NFTId = NFTId {
            collection_id: collection_id,
            nft_commit: nft_commit
        };
        let nft_id_hash: field = BHP256::hash_to_field(nft_id);
        let minted_nft: NFT = NFT {
            owner: recipient,
            collection_id: collection_id,
            data: nft_data,
            edition: nft_edition
        };

        let admin_nft_id_hash: field = hash_admin_nft_id(collection_id);
        let mint_private_as_public_future: Future = 
            finalize_mint_private_as_public(
                nft_id_hash, nft_id, admin_nft_id_hash, self.caller
            );
        return (minted_nft, mint_private_as_public_future);
    }
    async function finalize_mint_private_as_public(
        nft_id_hash: field,
        nft_id: NFTId,
        admin_nft_id_hash: field,
        caller: address
    ) {
        assert(nft_ids.contains(nft_id_hash).not());
        nft_ids.set(nft_id_hash, nft_id);
        let admin: address = nft_owners.get(admin_nft_id_hash);
        assert_eq(admin, caller);
    }


    async transition mint_public_as_private(
        admin_nft: NFT,
        public recipient: address,
        private nft_data: Data,
        private nft_edition: scalar,
    ) -> (NFTView, NFT, Future) {
        assert_eq(admin_nft.collection_id, ADMIN_NFTS_RESERVED_COLLECTION_ID);
        let collection_id: field = admin_nft.data.metadata[0u8];
        let new_admin_nft: NFT = NFT {
            owner: admin_nft.owner,
            collection_id: admin_nft.collection_id,
            data: admin_nft.data,
            edition: admin_nft.edition
        };

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

        let mint_public_as_private_future: Future = 
            finalize_mint_public_as_private(nft_id_hash, nft_id, recipient);
        return (nft_view, new_admin_nft, mint_public_as_private_future);
    }
    async function finalize_mint_public_as_private(
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
        private nft_data: Data,
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

        let admin_nft_id_hash: field = hash_admin_nft_id(collection_id);

        let mint_public_future: Future = 
            finalize_mint_public(
                self.caller, nft_id_hash, nft_id, recipient, admin_nft_id_hash
            );
        return (nft_view, mint_public_future);
    }
    async function finalize_mint_public(
        caller: address,
        nft_id_hash: field,
        nft_id: NFTId,
        recipient: address,
        admin_nft_id_hash: field
    ) {
        let admin: address = nft_owners.get(admin_nft_id_hash);
        assert_eq(admin, caller);
        assert(nft_ids.contains(nft_id_hash).not());
        nft_ids.set(nft_id_hash, nft_id);
        nft_owners.set(nft_id_hash, recipient);
    }


    transition burn_private(
        admin_nft: NFT,
        nft: NFT
    ) -> NFT {
        assert_eq(admin_nft.collection_id, ADMIN_NFTS_RESERVED_COLLECTION_ID);
        let collection_id: field = admin_nft.data.metadata[0u8];
        assert_eq(collection_id, nft.collection_id);
        let new_admin_nft: NFT = NFT {
            owner: admin_nft.owner,
            collection_id: admin_nft.collection_id,
            data: admin_nft.data,
            edition: admin_nft.edition
        };
        return new_admin_nft;
    }


    async transition burn_private_as_public(
        nft: NFT
    ) -> Future {
        let admin_nft_id_hash: field = hash_admin_nft_id(nft.collection_id);
        let burn_private_as_public_future: Future = 
            finalize_burn_private_as_public(
                self.caller, admin_nft_id_hash
            );
        return burn_private_as_public_future;
    }
    async function finalize_burn_private_as_public(
        caller: address,
        admin_nft_id_hash: field
    ) {
        let admin: address = nft_owners.get(admin_nft_id_hash);
        assert_eq(admin, caller);
    }


    async transition burn_public_as_private(
        admin_nft: NFT,
        private nft_data: Data,
        private nft_edition: scalar,
    ) -> (NFT, Future) {
        assert_eq(admin_nft.collection_id, ADMIN_NFTS_RESERVED_COLLECTION_ID);
        let collection_id: field = admin_nft.data.metadata[0u8];
        let new_admin_nft: NFT = NFT {
            owner: admin_nft.owner,
            collection_id: admin_nft.collection_id,
            data: admin_nft.data,
            edition: admin_nft.edition
        };
        let nft_id_hash: field = hash_nft_id(
            collection_id, nft_data, nft_edition
        );
        let burn_public_as_private_future: Future = 
            finalize_burn_public_as_private(
                collection_id, self.caller, nft_id_hash
            );
        return (new_admin_nft, burn_public_as_private_future);
    }
    async function finalize_burn_public_as_private(
        collection_id: field,
        caller: address,
        nft_id_hash: field,
    ) {
        let owner: address = nft_owners.get(nft_id_hash);
        assert_eq(caller, owner);
        nft_approvals.remove(nft_id_hash);
        nft_owners.remove(nft_id_hash);
    }


    async transition burn_public(
        private collection_id: field,
        private nft_data: Data,
        private nft_edition: scalar,
    ) -> Future {
        let nft_id_hash: field = hash_nft_id(
            collection_id, nft_data, nft_edition
        );
        let admin_nft_id_hash: field = hash_admin_nft_id(collection_id);
        let burn_authorization_future: Future = 
            finalize_burn_public(self.caller, nft_id_hash, admin_nft_id_hash);
        return burn_authorization_future;
    }
    async function finalize_burn_public(
        caller: address,
        nft_id_hash: field,
        admin_nft_id_hash: field
    ) {
        let admin: address = nft_owners.get(admin_nft_id_hash);
        assert_eq(admin, caller);

        let owner: address = nft_owners.get(nft_id_hash);
        assert_eq(caller, owner);
        nft_approvals.remove(nft_id_hash);
        nft_owners.remove(nft_id_hash);
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
        private nft_data: Data,
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
        private nft_data: Data,
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
        private nft_data: Data,
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
        private nft_data: Data,
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
        private nft_data: Data,
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
        private nft_data: Data,
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


    async transition transfer_from_public_to_private(
        private collection_id: field,
        public from: address,
        public recipient: address,
        private nft_data: Data,
        private nft_edition: scalar,
    ) -> (NFT, Future) {
        let nft_id_hash: field = hash_nft_id(collection_id, nft_data, nft_edition);
        let apvl_hash: field = hash_approval(collection_id, from, self.signer);
        let transfer_from_public_to_private_future: Future =
            finalize_transfer_from_public_to_private(
                apvl_hash, from, nft_id_hash
            );

        let nft: NFT = NFT {
            owner: recipient,
            collection_id: collection_id,
            data: nft_data,
            edition: nft_edition
        };
        return (
            nft,
            transfer_from_public_to_private_future
        );
    }
    async function finalize_transfer_from_public_to_private(
        apvl_hash: field,
        from: address,
        nft_id_hash: field,
    ) {
        assert(
            nft_approvals.contains(nft_id_hash)
            || for_all_approvals.get_or_use(apvl_hash, false)
        );

        let owner: address = nft_owners.get(nft_id_hash);
        assert_eq(from, owner);
        
        nft_approvals.remove(nft_id_hash);
        nft_owners.remove(nft_id_hash);
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
        public nft_data: Data,
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
