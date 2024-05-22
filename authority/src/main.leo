/*

    The 'authority' program.
    Defines an authority address for programs that import this program.

*/

program authority.aleo {
    const initial_authority: address = aleo1wamjqlka7d0gazlxdys6n8e8zeee3ymedwvw8elvh7529kwd45rq0plgax;


    mapping authority: bool => address; // true => authority


    async transition transfer_authority(
        public to: address,
    ) -> Future {
        let caller: address = self.caller;
        return finalize_transfer_authority(caller, to);
    }
    async function finalize_transfer_authority(
        public from: address, public to: address
    ){
        let current_authority: address = authority.get_or_use(true, initial_authority);
        assert_eq(from, current_authority);
        authority.set(true, to);
    }


    async transition assert_authority(public asserted: address) -> Future {
        return finalize_assert_authority(asserted);
    }
    async function finalize_assert_authority(public asserted: address){
        let current_authority: address = authority.get_or_use(
            true, initial_authority
        );
        assert_eq(asserted, current_authority);
    }
}
