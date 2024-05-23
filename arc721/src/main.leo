// The 'arc721' program.

/*
To discuss:
1.  For data attribute, why not use [field; 4] instead of [u128; 4].
    Same constraints, (ex: 12 for hard coded equality assertion), but:
      + [u128; 4]: 252bits
      + [field; 4] 128bits

2.
*/

import authority.aleo;
import royalty.aleo;


program arc721.aleo {
    record NFT {
        owner: address,
        data: [u128; 4],
        edition: scalar,
    }

    struct approval {
        approver: address,
        spender: address,
    }

    mapping nft_owners: field => address;
    mapping for_all_approvals: field => bool; // approval hash => approved
    mapping nft_approvals: field => field; // token commit => approval hash


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
    ) -> Future {
        let data_hash: field = BHP256::hash_to_field(nft.data);
        let token_commit: field = BHP256::commit_to_field(
            data_hash, nft.edition
        );
        return finalize_transfer_private_to_public(
             to, token_commit,
        );
    }
    async function finalize_transfer_private_to_public(
        public to: address,
        public token_commit: field,
    ){
        nft_owners.set(
            token_commit,
            to,
        );
    }


    async transition transfer_public(
        public data: [u128; 4],
        public edition: scalar,
        public to: address,
    ) -> Future {
        let data_hash: field = BHP256::hash_to_field(data);
        let token_commit: field = BHP256::commit_to_field(
            data_hash, edition
        );
        let caller: address = self.caller;
        return finalize_transfer_public(
             to, token_commit, caller,
        );
    }
    async function finalize_transfer_public(
        public to: address,
        public token_commit: field,
        public caller: address,
    ) {
        let owner: address = nft_owners.get(token_commit);
        assert_eq(caller, owner);
        nft_approvals.remove(token_commit);
        nft_owners.set(token_commit, to);
    }


    async transition transfer_public_to_private(
        public data: [u128; 4],
        public edition: scalar,
        private to: address,
    ) -> (NFT, Future) {
        let data_hash: field = BHP256::hash_to_field(data);
        let token_commit: field = BHP256::commit_to_field(
            data_hash, edition
        );
        let caller: address = self.caller;
        let finalize_future: Future = finalize_transfer_public_to_private(
            caller, token_commit,
        );
        let received_nft: NFT = NFT {
            owner: to,
            data: data,
            edition: edition,
        };
        return (received_nft, finalize_future);
    }
    async function finalize_transfer_public_to_private(
        public caller: address,
        public token_commit: field,
    ){
        let owner: address = nft_owners.get(token_commit);
        assert_eq(caller, owner);
        nft_approvals.remove(token_commit);
        nft_owners.remove(token_commit);
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
        public apvl_hash: field,
        public new_value: bool,
    ){
        for_all_approvals.set(apvl_hash, new_value);
    }

    
    async transition approve_public(
        private spender: address,
        private data: [u128; 4],
        private edition: scalar,
    ) -> Future {
        let data_hash: field = BHP256::hash_to_field(data);
        let token_commit: field = BHP256::commit_to_field(
            data_hash, edition
        );

        let apvl: approval = approval {
            approver: self.caller,
            spender: spender,
        };
        let apvl_hash: field = BHP256::hash_to_field(apvl);
        return finalize_approve_public(
            self.caller, apvl_hash, token_commit,
        );
    }
    async function finalize_approve_public(
        public caller: address,
        public apvl_hash: field,
        public token_commit: field,
    ){
        let owner: address = nft_owners.get(token_commit);
        assert_eq(owner, caller);
        nft_approvals.set(token_commit, apvl_hash);
    }


    async transition transfer_from_public(
        public from: address,
        public to: address,
        private data: [u128; 4],
        private edition: scalar,
    ) -> Future {
        let data_hash: field = BHP256::hash_to_field(data);
        let token_commit: field = BHP256::commit_to_field(
            data_hash, edition
        );

        let apvl: approval = approval {
            approver: from,
            spender: self.caller,
        };
        let apvl_hash: field = BHP256::hash_to_field(apvl);
        return finalize_transfer_from_public(
             apvl_hash, from, to, token_commit,
        );
    }
    async function finalize_transfer_from_public(
        public apvl_hash: field,
        public from: address,
        public to: address,
        public token_commit: field,
    ) {
        assert(
            nft_approvals.contains(token_commit)
            || for_all_approvals.get_or_use(apvl_hash, false)
        );

        let owner: address = nft_owners.get(token_commit);
        assert_eq(from, owner);
        
        nft_approvals.remove(token_commit);
        nft_owners.set(token_commit, to);
    }
}
