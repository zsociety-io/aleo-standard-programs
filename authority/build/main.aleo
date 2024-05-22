program authority.aleo;



mapping authority:
	key as boolean.public;
	value as address.public;


function transfer_authority:
    input r0 as address.public;
    async transfer_authority self.caller r0 into r1;
    output r1 as authority.aleo/transfer_authority.future;

finalize transfer_authority:
    input r0 as address.public;
    input r1 as address.public;
    get.or_use authority[true] aleo1wamjqlka7d0gazlxdys6n8e8zeee3ymedwvw8elvh7529kwd45rq0plgax into r2;
    assert.eq r0 r2;
    set r1 into authority[true];




function assert_authority:
    input r0 as address.public;
    async assert_authority r0 into r1;
    output r1 as authority.aleo/assert_authority.future;

finalize assert_authority:
    input r0 as address.public;
    get.or_use authority[true] aleo1wamjqlka7d0gazlxdys6n8e8zeee3ymedwvw8elvh7529kwd45rq0plgax into r1;
    assert.eq r0 r1;

