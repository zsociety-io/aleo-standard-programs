import authority.aleo;
program royalty.aleo;

struct Share:
    holder as address;
    permyriad as u8;


mapping royalties:
	key as u8.public;
	value as Share.public;


function set_royalty:
    input r0 as u8.public;
    input r1 as Share.public;
    call authority.aleo/check_authorized self.caller into r2;
    async set_royalty r0 r1.holder r1.permyriad r2 into r3;
    output r3 as royalty.aleo/set_royalty.future;

finalize set_royalty:
    input r0 as u8.public;
    input r1 as address.public;
    input r2 as u8.public;
    input r3 as authority.aleo/check_authorized.future;
    await r3;
    cast r1 r2 into r4 as Share;
    set r4 into royalties[r0];




function unset_royalty:
    input r0 as u8.public;
    call authority.aleo/check_authorized self.caller into r1;
    async unset_royalty r0 r1 into r2;
    output r2 as royalty.aleo/unset_royalty.future;

finalize unset_royalty:
    input r0 as u8.public;
    input r1 as authority.aleo/check_authorized.future;
    await r1;
    remove royalties[r0];

