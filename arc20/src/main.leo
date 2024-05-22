/*
    Leo implementation of ARC0020 specified at:
    https://aleo.up.railway.app/p/20
*/

program arc20.aleo {
    const name: u128 = 0u128;           // Token name
    const symbol: u64 = 0u64;           // Token symbol
    const decimals: u8 = 0u8;           // Token decimals
    const total_supply: u64 = 0u64;     // Token maximum supply

    record token {
        private owner: address,
        private amount: u64,
    }

    struct approval {
        approver: address,
        spender: address,
    }

    struct metadata {
        name: u128,
        symbol: u64,
        decimals: u8,
        total_supply: u64,
    }

    mapping account: address => u64;
    mapping approvals: field => u64;

    transition get_metadata () -> metadata {
        return metadata {
            name: name,
            symbol: symbol,
            decimals: decimals,
            total_supply: total_supply,
        };
    }

    async transition approve_public(
        private spender: address, // spender
        public amount: u64, // amount spender is allowed to withdraw from approver
    ) -> Future {
        let apvl: approval = approval {
            approver: self.caller,
            spender: spender,
        };
        let apvl_hash: field = BHP256::hash_to_field(apvl);
        return finalize_approve_public(apvl_hash, amount);
    }
    async function finalize_approve_public (apvl_hash: field, amount: u64) {
        let approved: u64 = approvals.get_or_use(apvl_hash, 0u64);
        approved += amount;
        approvals.set(apvl_hash, approved);
    }

    async transition unapprove_public(
        private spender: address, // spender
        public amount: u64, // amount spender is allowed to withdraw from approver
    ) -> Future {
        let apvl: approval = approval {
            approver: self.caller,
            spender: spender,
        };
        let apvl_hash: field = BHP256::hash_to_field(apvl);
        return finalize_unapprove_public(apvl_hash, amount);
    }
    async function finalize_unapprove_public (apvl_hash: field, amount: u64) {
        let approved: u64 = approvals.get(apvl_hash);
        approved -= amount;
        approvals.set(apvl_hash, approved);
    }

    async transition transfer_from_public(
        public approver: address, // from the approver
        public receiver: address, // to the receiver
        public amount: u64, // amount to transfer
    ) -> Future {
        let apvl: approval = approval{
            approver: approver,
            spender: self.caller,
        };
        let apvl_hash: field = BHP256::hash_to_field(apvl);
        return finalize_transfer_from_public(
            apvl_hash,
            approver,
            receiver,
            amount,
        );
    }
    async function finalize_transfer_from_public(
        apvl_hash: field, approver: address, receiver: address, amount: u64,
    ) {
        let approved: u64 = approvals.get(apvl_hash);
        approved -= amount;
        approvals.set(apvl_hash, approved);

        let from_balance: u64 = account.get(approver);
        from_balance -= amount;
        account.set(approver, from_balance);

        let to_balance: u64 = account.get_or_use(receiver, 0u64);
        to_balance += amount;
        account.set(receiver, to_balance);
    }

    async transition transfer_public(
        public receiver: address, // to the receiver
        public amount: u64, // amount to transfer
    ) -> Future {
        return finalize_transfer_public(
            self.caller,
            receiver,
            amount,
        );
    }
    async function finalize_transfer_public(
        caller: address, receiver: address, amount: u64,
    ) {
        let from_balance: u64 = account.get(caller);
        from_balance -= amount;
        account.set(caller, from_balance);

        let to_balance: u64 = account.get_or_use(receiver, 0u64);
        to_balance += amount;
        account.set(receiver, to_balance);
    }

    transition transfer_private(
        private consumed_token: token, // token record to consume
        private receiver: address, // to the receiver
        private amount: u64, // amount to transfer
    ) -> (token, token) {
        let sender_token: token = token {
            owner: consumed_token.owner,
            amount: consumed_token.amount - amount,
        };
        let receiver_token: token = token {
            owner: receiver,
            amount: amount,
        };
        return (sender_token, receiver_token);
    }

    async transition transfer_private_to_public(
        private consumed_token: token, // token record to consume
        public receiver: address, // to the receiver
        public amount: u64, // amount to transfer
    ) -> (token, Future) {
        let sender_token: token = token {
            owner: consumed_token.owner,
            amount: consumed_token.amount - amount,
        };
        let finalize_future: Future = finalize_transfer_private_to_public(
            receiver,
            amount,
        );
        return (sender_token, finalize_future);
    }
    async function finalize_transfer_private_to_public(
        receiver: address, amount: u64,
    ) {
        let to_balance: u64 = account.get(receiver);
        to_balance += amount;
        account.set(receiver, to_balance);
    }

    async transition transfer_public_to_private(
        private receiver: address, // to the receiver
        public amount: u64, // amount to transfer
    ) -> (token, Future) {
        let receiver_token: token = token {
            owner: receiver,
            amount: amount,
        };
        let finalize_future: Future = finalize_transfer_public_to_private(
            self.caller,
            amount,
        );
        return (receiver_token, finalize_future);
    }
    async function finalize_transfer_public_to_private(
        caller: address, amount: u64,
    ) {
        let from_balance: u64 = account.get(caller);
        from_balance -= amount;
        account.set(caller, from_balance);
    }
}
