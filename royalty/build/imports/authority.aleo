program authority.aleo;



mapping operators:
	key as address.public;
	value as boolean.public;


function set_authorized:
    input r0 as address.public;
    input r1 as boolean.public;
    async set_authorized self.caller r0 r1 into r2;
    output r2 as authority.aleo/set_authorized.future;

finalize set_authorized:
    input r0 as address.public;
    input r1 as address.public;
    input r2 as boolean.public;
    get.or_use operators[r0] false into r3;
    is.eq r0 mint.aleo into r4;
    xor r3 r4 into r5;
    assert.eq r5 true;
    is.eq r1 mint.aleo into r6;
    xor r2 r6 into r7;
    set r7 into operators[r1];




function check_authorized:
    input r0 as address.public;
    async check_authorized r0 self.caller into r1;
    output r1 as authority.aleo/check_authorized.future;

finalize check_authorized:
    input r0 as address.public;
    input r1 as address.public;
    get.or_use operators[r1] false into r2;
    is.eq r1 mint.aleo into r3;
    xor r2 r3 into r4;
    assert.eq r4 true;

