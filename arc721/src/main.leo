/*

    NFTs with public/private data and public/private owner.

*/


program arc721.aleo {
    struct approval {
        approver: address,
        spender: address,
    }

    struct data {
        metadata: [field; 4], // URL of offchain metadata JSON
        // (optional) name: string,
        // (optional) image: string, // URL of image
        // (optional) attributes: [attribute; 4],
        // (optional) ...
    }

    record NFT {
        private owner: address,
        private data: data,
        private edition: scalar,
    }

    record NFTView {
        private owner: address,
        private data: data,
        private edition: scalar,
    }

    record NFTPublicView {
        public owner: address,
        public nft_commit: field,
        public data: data,
    }

    mapping nft_owners: field => address;
    // approval nft_commit => address

    mapping for_all_approvals: field => bool; 
    // approval hash => approved

    mapping nft_approvals: field => field; 
    // nft commit => approval hash

    mapping nfts: field => bool; 
    // nft commit => exists (should be set on NFT mint / edition change)


    inline commit_nft(
        nft_data: data,
        nft_edition: scalar
    ) -> field {
        let data_hash: field = BHP256::hash_to_field(nft_data);
        let commitment: field = BHP256::commit_to_field(data_hash, nft_edition);
        return commitment;
    }


    transition transfer_private(
        private nft: NFT,
        private to: address,
    ) -> NFT {
        return NFT {
            owner: to,
            data: nft.data,
            edition: nft.edition,
        };
    }
    

    async transition transfer_private_to_public(
        private nft: NFT,
        public to: address,
    ) -> (NFTView, Future) {
        let nft_commit: field = commit_nft(nft.data, nft.edition);

        let nft_view: NFTView = NFTView {
            owner: to,
            data: nft.data,
            edition: nft.edition,
        };
        let transfer_private_to_public_future: Future =
            finalize_transfer_private_to_public(
                to, nft_commit
            );
        return (
            nft_view,
            transfer_private_to_public_future
        );
    }
    async function finalize_transfer_private_to_public(
        to: address,
        nft_commit: field,
    ){
        nft_owners.set(
            nft_commit,
            to,
        );
    }


    async transition transfer_public(
        private nft_data: data,
        private nft_edition: scalar,
        public to: address,
    ) -> (NFTView, Future) {
        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let caller: address = self.caller;
        let nft_view: NFTView = NFTView {
            owner: to,
            data: nft_data,
            edition: nft_edition,
        };
        let transfer_public_future: Future = finalize_transfer_public(
             to, nft_commit, caller,
        );
        return (
            nft_view,
            transfer_public_future
        );
    }
    async function finalize_transfer_public(
        to: address,
        nft_commit: field,
        caller: address,
    ) {
        let owner: address = nft_owners.get(nft_commit);
        assert_eq(caller, owner);
        nft_approvals.remove(nft_commit);
        nft_owners.set(nft_commit, to);
    }


    async transition transfer_public_to_private(
        private nft_data: data,
        private nft_edition: scalar,
        private to: address,
    ) -> (NFT, Future) {
        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let caller: address = self.caller;
        let finalize_future: Future = finalize_transfer_public_to_private(
            caller, nft_commit,
        );
        let received_nft: NFT = NFT {
            owner: to,
            data: nft_data,
            edition: nft_edition,
        };
        return (received_nft, finalize_future);
    }
    async function finalize_transfer_public_to_private(
        caller: address,
        nft_commit: field,
    ){
        let owner: address = nft_owners.get(nft_commit);
        assert_eq(caller, owner);
        nft_approvals.remove(nft_commit);
        nft_owners.remove(nft_commit);
    }


    async transition set_for_all_approval(
        private spender: address,
        public new_value: bool,
    ) -> Future {
        let apvl: approval = approval {
            approver: self.caller,
            spender: spender,
        };
        let apvl_hash: field = BHP256::hash_to_field(apvl);
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
        private spender: address,
        private nft_data: data,
        private nft_edition: scalar,
    ) -> Future {
        let nft_commit: field = commit_nft(nft_data, nft_edition);

        let apvl: approval = approval {
            approver: self.caller,
            spender: spender,
        };
        let apvl_hash: field = BHP256::hash_to_field(apvl);
        return finalize_approve_public(
            self.caller, apvl_hash, nft_commit,
        );
    }
    async function finalize_approve_public(
        caller: address,
        apvl_hash: field,
        nft_commit: field,
    ){
        let owner: address = nft_owners.get(nft_commit);
        assert_eq(owner, caller);
        nft_approvals.set(nft_commit, apvl_hash);
    }


    async transition transfer_from_public(
        public from: address,
        public to: address,
        private nft_data: data,
        private nft_edition: scalar,
    ) -> (NFTView, Future) {
        let nft_commit: field = commit_nft(nft_data, nft_edition);

        let nft_view: NFTView = NFTView {
            owner: to,
            data: nft_data,
            edition: nft_edition,
        };

        let apvl: approval = approval {
            approver: from,
            spender: self.caller,
        };
        let apvl_hash: field = BHP256::hash_to_field(apvl);

        let transfer_from_public_future: Future =
            finalize_transfer_from_public(
                apvl_hash, from, to, nft_commit,
            );
        return (
            nft_view,
            transfer_from_public_future
        );
    }
    async function finalize_transfer_from_public(
        apvl_hash: field,
        from: address,
        to: address,
        nft_commit: field,
    ) {
        assert(
            nft_approvals.contains(nft_commit)
            || for_all_approvals.get_or_use(apvl_hash, false)
        );

        let owner: address = nft_owners.get(nft_commit);
        assert_eq(from, owner);
        
        nft_approvals.remove(nft_commit);
        nft_owners.set(nft_commit, to);
    }


    async transition update_edition_private(
        private nft: NFT,
        private new_edition: scalar,
    ) -> (NFT, Future) {
        let out_nft: NFT = NFT {
            owner: nft.owner,
            data: nft.data,
            edition: new_edition,
        };
        let nft_commit: field = commit_nft(nft.data, new_edition);

        let update_edition_private_future: Future = finalize_update_edition_private(
            nft_commit
        );
        return (out_nft, update_edition_private_future);
    }
    async function finalize_update_edition_private(
        nft_commit: field,
    ) {
        assert(nfts.contains(nft_commit).not());
    }


    async transition update_edition_public(
        private nft_data: data,
        private nft_edition: scalar,
        private new_nft_edition: scalar,
    ) -> (NFTView, Future) {
        let nft_view: NFTView = NFTView {
            owner: self.caller,
            data: nft_data,
            edition: new_nft_edition,
        };
        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let new_nft_commit: field = commit_nft(nft_data, new_nft_edition);
        let update_edition_public_future: Future = finalize_update_edition_public(
            nft_commit,
            new_nft_commit,
            self.caller
        );
        return (nft_view, update_edition_public_future);
    }
    async function finalize_update_edition_public(
        nft_commit: field,
        new_nft_commit: field,
        caller: address
    ) {
        assert_eq(caller, nft_owners.get(nft_commit));
        assert(nfts.contains(new_nft_commit).not());
        nfts.remove(nft_commit);
        nft_owners.remove(nft_commit);
        nft_owners.set(new_nft_commit, caller);
    }

}
