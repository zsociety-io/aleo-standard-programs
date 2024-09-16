
import credits.aleo;


program credits_ttl_wrapper.aleo {
    async transition transfer_public(
        public ttl: u32,
        public receiver: address,
        public amount: u64
    ) -> Future {
        let credits_future: Future = credits.aleo/transfer_public(
            receiver,
            amount
        );
        return finalize_transfer_public(ttl, credits_future);
    }
    async function finalize_transfer_public(ttl: u32, credits_future: Future){
        assert(block.height <= ttl);
        credits_future.await();
    }


    async transition transfer_public_as_signer(
        public ttl: u32,
        public receiver: address,
        public amount: u64
    ) -> Future {
        let credits_future: Future = credits.aleo/transfer_public_as_signer(
            receiver,
            amount
        );
        return finalize_transfer_public_as_signer(ttl, credits_future);
    }
    async function finalize_transfer_public_as_signer(ttl: u32, credits_future: Future){
        assert(block.height <= ttl);
        credits_future.await();
    }


    async transition transfer_private_to_public(
        public ttl: u32,
        private spent_credits: credits.aleo/credits,
        public receiver: address,
        public amount: u64
    ) -> (credits.aleo/credits, Future) {
        let (change_credits, credits_future): (
            credits.aleo/credits, Future
        ) = credits.aleo/transfer_private_to_public(
            spent_credits,
            receiver,
            amount
        );
        return (
            change_credits,
            finalize_transfer_private_to_public(ttl, credits_future)
        );
    }
    async function finalize_transfer_private_to_public(
        ttl: u32, credits_future: Future
    ){
        assert(block.height <= ttl);
        credits_future.await();
    }


    async transition transfer_private(
        public ttl: u32,
        private spent_credits: credits.aleo/credits,
        private receiver: address,
        private amount: u64
    ) -> (credits.aleo/credits, credits.aleo/credits, Future) {
        let (
            change_credits, minted_credits
        ): (
            credits.aleo/credits, credits.aleo/credits
        ) = credits.aleo/transfer_private(
            spent_credits,
            receiver,
            amount
        );
        return (
            change_credits,
            minted_credits,
            finalize_transfer_private(ttl)
        );
    }
    async function finalize_transfer_private(
        ttl: u32
    ){
        assert(block.height <= ttl);
    }


    async transition transfer_public_to_private(
        public ttl: u32,
        private receiver: address,
        public amount: u64
    ) -> (credits.aleo/credits, Future) {
        let (
            minted_credits, credits_future
        ): (
            credits.aleo/credits, Future
        ) = credits.aleo/transfer_public_to_private(
            receiver,
            amount
        );
        return (
            minted_credits,
            finalize_transfer_public_to_private(ttl, credits_future)
        );
    }
    async function finalize_transfer_public_to_private(
        ttl: u32,
        credits_future: Future
    ){
        assert(block.height <= ttl);
        credits_future.await();
    }


    async transition join(
        public ttl: u32,
        private spent_credits1: credits.aleo/credits,
        private spent_credits2: credits.aleo/credits
    ) -> (credits.aleo/credits, Future) {
        let joined_credits: credits.aleo/credits = credits.aleo/join(
            spent_credits1,
            spent_credits2
        );
        return (
            joined_credits,
            finalize_join(ttl)
        );
    }
    async function finalize_join(
        ttl: u32
    ){
        assert(block.height <= ttl);
    }


    async transition split(
        public ttl: u32,
        private spent_credits: credits.aleo/credits,
        private amount: u64,
    ) -> (credits.aleo/credits, credits.aleo/credits, Future) {
        let (
            minted_credits1,
            minted_credits2
        ): (
            credits.aleo/credits,
            credits.aleo/credits
        ) = credits.aleo/split(
            spent_credits,
            amount
        );
        return (
            minted_credits1,
            minted_credits2,
            finalize_split(ttl)
        );
    }
    async function finalize_split(
        ttl: u32
    ){
        assert(block.height <= ttl);
    }

    
    async transition bond_public(
        public ttl: u32,
        public validator: address,
        public withdrawal: address,
        public amount: u64
    ) -> Future {
        let credits_future: Future = credits.aleo/bond_public(
            validator,
            withdrawal,
            amount
        );
        return finalize_bond_public(ttl, credits_future);
    }
    async function finalize_bond_public(
        ttl: u32, credits_future: Future
    ){
        assert(block.height <= ttl);
        credits_future.await();
    }
    

    async transition bond_validator(
        public ttl: u32,
        public withdrawal: address,
        public amount: u64,
        public commission: u8,
    ) -> Future {
        let credits_future: Future = credits.aleo/bond_validator(
            withdrawal,
            amount,
            commission
        );
        return finalize_bond_validator(ttl, credits_future);
    }
    async function finalize_bond_validator(
        ttl: u32, credits_future: Future
    ){
        assert(block.height <= ttl);
        credits_future.await();
    }


    async transition unbond_public(
        public ttl: u32,
        public staker: address,
        public amount: u64
    ) -> Future {
        let credits_future: Future = credits.aleo/unbond_public(
            staker,
            amount
        );
        return finalize_unbond_public(ttl, credits_future);
    }
    async function finalize_unbond_public(
        ttl: u32, credits_future: Future
    ){
        assert(block.height <= ttl);
        credits_future.await();
    }


    async transition claim_unbond_public(
        public ttl: u32,
        public staker: address
    ) -> Future {
        let credits_future: Future = credits.aleo/claim_unbond_public(
            staker
        );
        return finalize_claim_unbond_public(ttl, credits_future);
    }
    async function finalize_claim_unbond_public(
        ttl: u32, credits_future: Future
    ){
        assert(block.height <= ttl);
        credits_future.await();
    }


    async transition set_validator_state(
        public ttl: u32,
        public is_open: bool
    ) -> Future {
        let credits_future: Future = credits.aleo/set_validator_state(
            is_open
        );
        return finalize_set_validator_state(ttl, credits_future);
    }
    async function finalize_set_validator_state(
        ttl: u32, credits_future: Future
    ){
        assert(block.height <= ttl);
        credits_future.await();
    }
}
