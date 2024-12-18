/*

    Collection registry for NFTs with public/private data and public/private owner.

*/

import nft_records.aleo;


program nft_registry.aleo {
    const ADMIN_NFTS_COLLECTION_ID: field = 0field;
    const ADMIN_NFTS_EDITION: scalar = 0scalar;

    struct Data {
        metadata: field
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


    mapping nft_ids: field => NFTId; 
    // hash(NFTId) => NFTId

    mapping nft_owners: field => address;
    // hash(NFTId) => NFT owner

    mapping for_all_approvals: field => bool; 
    // hash(Approval) => Is approved

    mapping nft_approvals: field => field; 
    // hash(NFTId) => hash(Approval)

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


    inline field_nft_data(collection_id: field) -> Data {
        return Data {
            metadata: collection_id
        };
    }

    inline hash_admin_nft_id(collection_id: field) -> field {
        let nft_data: Data = field_nft_data(collection_id);
        let admin_nft_id_hash: field = hash_nft_id(
            ADMIN_NFTS_COLLECTION_ID,
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


    async transition set_collection_admin(
        private collection_id: field,
        public admin: address,
        public set_admin_owner: bool,
    ) -> Future {
        assert_eq(self.caller, nft_collections.aleo);
        let nft_data: Data = field_nft_data(collection_id);
        let admin_nft_commit: field = commit_nft(nft_data, ADMIN_NFTS_EDITION);
        let admin_nft_id: NFTId = NFTId {
            collection_id: ADMIN_NFTS_COLLECTION_ID,
            nft_commit: admin_nft_commit
        };
        let admin_nft_id_hash: field = BHP256::hash_to_field(admin_nft_id);

        return finalize_set_collection_admin(
             admin_nft_id_hash, admin_nft_id, admin, set_admin_owner
        );
    }
    async function finalize_set_collection_admin(
        admin_nft_id_hash: field,
        admin_nft_id: NFTId,
        admin: address,
        set_admin_owner: bool
    ) {
        assert(nft_ids.contains(admin_nft_id_hash).not());
        nft_ids.set(admin_nft_id_hash, admin_nft_id);
        if(set_admin_owner){
            nft_owners.set(admin_nft_id_hash, admin);
        }
    }


    async transition mint_private(
        admin_nft: nft_records.aleo/NFT,
        private recipient: address,
        private nft_data: Data,
        private nft_edition: scalar,
    ) -> (nft_records.aleo/NFT, Future) {
        assert_eq(admin_nft.collection_id, ADMIN_NFTS_COLLECTION_ID);
        let collection_id: field = admin_nft.data.metadata;

        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let nft_id: NFTId = NFTId {
            collection_id: collection_id,
            nft_commit: nft_commit
        };
        let nft_id_hash: field = BHP256::hash_to_field(nft_id);
        let minted_nft: nft_records.aleo/NFT = nft_records.aleo/mint_nft(
            recipient,
            collection_id,
            nft_data,
            nft_edition
        );
        let mint_private_future: Future = 
            finalize_mint_private(nft_id_hash, nft_id);
        return (minted_nft, mint_private_future);
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
    ) -> (nft_records.aleo/NFT, Future) {
        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let nft_id: NFTId = NFTId {
            collection_id: collection_id,
            nft_commit: nft_commit
        };
        let nft_id_hash: field = BHP256::hash_to_field(nft_id);
        let minted_nft: nft_records.aleo/NFT = nft_records.aleo/mint_nft(
            recipient,
            collection_id,
            nft_data,
            nft_edition
        );
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
        admin_nft: nft_records.aleo/NFT,
        public recipient: address,
        private nft_data: Data,
        private nft_edition: scalar,
    ) -> (nft_records.aleo/NFTView, Future) {
        assert_eq(admin_nft.collection_id, ADMIN_NFTS_COLLECTION_ID);
        let collection_id: field = admin_nft.data.metadata;
        let nft_view: nft_records.aleo/NFTView = 
            nft_records.aleo/mint_nft_view(
                recipient, nft_data, nft_edition
            );
        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let nft_id: NFTId = NFTId {
            collection_id: collection_id,
            nft_commit: nft_commit
        };
        let nft_id_hash: field = BHP256::hash_to_field(nft_id);

        let mint_public_as_private_future: Future = 
            finalize_mint_public_as_private(nft_id_hash, nft_id, recipient);
        return (nft_view, mint_public_as_private_future);
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
    ) -> (nft_records.aleo/NFTView, Future) {
        let nft_view: nft_records.aleo/NFTView = 
            nft_records.aleo/mint_nft_view(
                recipient, nft_data, nft_edition
            );
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
        admin_nft: nft_records.aleo/NFT,
        nft: nft_records.aleo/NFT
    ) {
        assert_eq(admin_nft.collection_id, ADMIN_NFTS_COLLECTION_ID);
        let collection_id: field = admin_nft.data.metadata;
        assert_eq(collection_id, nft.collection_id);
        nft_records.aleo/burn_nft(nft);
    }


    async transition burn_private_as_public(
        nft: nft_records.aleo/NFT
    ) -> Future {
        let admin_nft_id_hash: field = hash_admin_nft_id(nft.collection_id);
        nft_records.aleo/burn_nft(nft);
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
        admin_nft: nft_records.aleo/NFT,
        private nft_data: Data,
        private nft_edition: scalar,
    ) -> Future {
        assert_eq(admin_nft.collection_id, ADMIN_NFTS_COLLECTION_ID);
        let collection_id: field = admin_nft.data.metadata;
        let nft_id_hash: field = hash_nft_id(
            collection_id, nft_data, nft_edition
        );
        let burn_public_as_private_future: Future = 
            finalize_burn_public_as_private(
                collection_id, self.caller, nft_id_hash
            );
        return burn_public_as_private_future;
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
        let burn_public_future: Future = 
            finalize_burn_public(self.caller, nft_id_hash, admin_nft_id_hash);
        return burn_public_future;
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
        nft: nft_records.aleo/NFT,
        private recipient: address,
    ) -> nft_records.aleo/NFT {
        return nft_records.aleo/transfer_nft(
            nft,
            recipient
        );
    }
    

    async transition transfer_private_to_public(
        nft: nft_records.aleo/NFT,
        public recipient: address,
    ) -> (nft_records.aleo/NFTView, Future) {
        nft_records.aleo/burn_nft(nft);
        let nft_view: nft_records.aleo/NFTView = 
            nft_records.aleo/mint_nft_view(
                recipient, nft.data, nft.edition
            );
        let nft_id_hash: field = hash_nft_id(nft.collection_id, nft.data, nft.edition);
        let transfer_private_to_public_future: Future =
            fin_transfer_private_to_public(
                recipient, nft_id_hash
            );
        return (
            nft_view,
            transfer_private_to_public_future
        );
    }
    async function fin_transfer_private_to_public(
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
    ) -> (nft_records.aleo/NFTView, Future) {
        let caller: address = self.caller;
        let nft_view: nft_records.aleo/NFTView = 
            nft_records.aleo/mint_nft_view(
                recipient, nft_data, nft_edition
            );

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
    ) -> (nft_records.aleo/NFTView, Future) {
        let nft_view: nft_records.aleo/NFTView = 
            nft_records.aleo/mint_nft_view(
                recipient, nft_data, nft_edition
            );

        let nft_id_hash: field = hash_nft_id(collection_id, nft_data, nft_edition);
        let transfer_public_as_signer_future: Future = fin_transfer_public_as_signer(
             recipient, nft_id_hash, self.signer,
        );
        return (
            nft_view,
            transfer_public_as_signer_future
        );
    }
    async function fin_transfer_public_as_signer(
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
    ) -> (nft_records.aleo/NFT, Future) {
        let nft_id_hash: field = hash_nft_id(collection_id, nft_data, nft_edition);
        let caller: address = self.caller;
        let received_nft: nft_records.aleo/NFT = nft_records.aleo/mint_nft(
            recipient,
            collection_id,
            nft_data,
            nft_edition
        );
        let finalize_future: Future = fin_transfer_public_to_private(
            caller, nft_id_hash,
        );
        return (received_nft, finalize_future);
    }
    async function fin_transfer_public_to_private(
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
    ) -> (nft_records.aleo/NFTView, Future) {
        let nft_id_hash: field = hash_nft_id(collection_id, nft_data, nft_edition);
        let apvl_hash: field = hash_approval(collection_id, from, self.caller);
        let nft_view: nft_records.aleo/NFTView = 
            nft_records.aleo/mint_nft_view(
                recipient, nft_data, nft_edition
            );
        let transfer_from_public_future: Future =
            finalize_transfer_from_public(apvl_hash, from, recipient, nft_id_hash);
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
    ) -> (nft_records.aleo/NFT, Future) {
        let nft_id_hash: field = hash_nft_id(collection_id, nft_data, nft_edition);
        let apvl_hash: field = hash_approval(collection_id, from, self.signer);
        let nft: nft_records.aleo/NFT = nft_records.aleo/mint_nft(
            recipient,
            collection_id,
            nft_data,
            nft_edition
        );
        let transfer_from_public_to_private_future: Future =
            fin_trans_from_pb_to_private(
                apvl_hash, from, nft_id_hash
            );
        return (
            nft,
            transfer_from_public_to_private_future
        );
    }
    async function fin_trans_from_pb_to_private(
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