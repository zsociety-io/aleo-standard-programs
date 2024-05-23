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
        let check_authorized_future: Future = authority.aleo/check_authorized(
            self.caller
        );
        return finalize_set_royalty(
            index,
            value.holder,
            value.permyriad,
            check_authorized_future
        );
    }
    async function finalize_set_royalty(
        index: u8,
        holder: address,
        permyriad: u8,
        check_authorized_future: Future
    ){
        check_authorized_future.await();
        let share: Share = Share {
            holder: holder,
            permyriad: permyriad
        };
        royalties.set(index, share);
    }


    async transition unset_royalty(public index: u8) -> Future {
        let check_authorized_future: Future = authority.aleo/check_authorized(
            self.caller
        );
        return finalize_unset_royalty(
            index, check_authorized_future
        );
    }
    async function finalize_unset_royalty(
        index: u8, check_authorized_future: Future
    ){
        check_authorized_future.await();
        royalties.remove(index);
    }
}
