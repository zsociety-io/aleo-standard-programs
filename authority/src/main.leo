/*

    The 'authority' program.
    Defines an authority address for programs that import this program.

*/

program authority.aleo {
    const initial_authorized: address = mint.aleo;

    // caller => (authorized xor is_caller_initial_authorized)
    mapping operators: address => bool;


    async transition set_authorized(
        public operator: address,
        public is_authorized: bool,
    ) -> Future {
        let caller: address = self.caller;
        return finalize_set_authorized(caller, operator, is_authorized);
    }
    async function finalize_set_authorized(
        public caller: address, public operator: address, public is_authorized: bool,
    ){
        let is_caller_authorized: bool = (
            operators
                .get_or_use(caller, false)
                .xor(caller == initial_authorized)
        );
        assert(is_caller_authorized);
        
        operators.set(
            operator,
            is_authorized.xor(operator == initial_authorized)
        );
    }

    async transition check_authorized(public asserted: address) -> Future {
        let caller: address = self.caller;
        return finalize_check_authorized(asserted, caller);
    }
    async function finalize_check_authorized(public asserted: address, public caller: address){
        let is_caller_authorized: bool = (
            operators
                .get_or_use(caller, false)
                .xor(caller == initial_authorized)
        );
        assert(is_caller_authorized);
    }
}
