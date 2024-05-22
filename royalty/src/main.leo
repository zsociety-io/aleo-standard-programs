/*

The 'royalty' program.

*/

import authority.aleo;

program royalty.aleo {
    struct Share {
        holder: address,
        permyriad: u8, // 1 permyriad = 0.01%
    }

    mapping royalties: u8 => Share; // index => share

    async transition set_royalty(
        public index: u8,
        public value: Share,
    ) -> Future {
        let assert_authority_future: Future = authority.aleo/assert_authority(
            self.caller
        );
        return finalize_set_royalty(
            index,
            value.holder,
            value.permyriad,
            assert_authority_future
        );
    }
    async function finalize_set_royalty(
        index: u8,
        holder: address,
        permyriad: u8,
        assert_authority_future: Future
    ){
        assert_authority_future.await();
        let share: Share = Share {
            holder: holder,
            permyriad: permyriad
        };
        royalties.set(index, share);
    }


    async transition unset_royalty(public index: u8) -> Future {
        let assert_authority_future: Future = authority.aleo/assert_authority(
            self.caller
        );
        return finalize_unset_royalty(
            index, assert_authority_future
        );
    }
    async function finalize_unset_royalty(
        index: u8, assert_authority_future: Future
    ){
        assert_authority_future.await();
        royalties.remove(index);
    }
}
