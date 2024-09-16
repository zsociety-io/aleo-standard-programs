import credits.aleo;
program credits_ttl_wrapper.aleo;




function bond_validator:
    input r0 as u32.public;
    input r1 as address.public;
    input r2 as u64.public;
    input r3 as u8.public;
    call credits.aleo/bond_validator r1 r2 r3 into r4;
    async bond_validator r0 r4 into r5;
    output r5 as credits_ttl_wrapper.aleo/bond_validator.future;

finalize bond_validator:
    input r0 as u32.public;
    input r1 as credits.aleo/bond_validator.future;
    lte block.height r0 into r2;
    assert.eq r2 true;
    await r1;




function bond_public:
    input r0 as u32.public;
    input r1 as address.public;
    input r2 as address.public;
    input r3 as u64.public;
    call credits.aleo/bond_public r1 r2 r3 into r4;
    async bond_public r0 r4 into r5;
    output r5 as credits_ttl_wrapper.aleo/bond_public.future;

finalize bond_public:
    input r0 as u32.public;
    input r1 as credits.aleo/bond_public.future;
    lte block.height r0 into r2;
    assert.eq r2 true;
    await r1;




function unbond_public:
    input r0 as u32.public;
    input r1 as address.public;
    input r2 as u64.public;
    call credits.aleo/unbond_public r1 r2 into r3;
    async unbond_public r0 r3 into r4;
    output r4 as credits_ttl_wrapper.aleo/unbond_public.future;

finalize unbond_public:
    input r0 as u32.public;
    input r1 as credits.aleo/unbond_public.future;
    lte block.height r0 into r2;
    assert.eq r2 true;
    await r1;




function claim_unbond_public:
    input r0 as u32.public;
    input r1 as address.public;
    call credits.aleo/claim_unbond_public r1 into r2;
    async claim_unbond_public r0 r2 into r3;
    output r3 as credits_ttl_wrapper.aleo/claim_unbond_public.future;

finalize claim_unbond_public:
    input r0 as u32.public;
    input r1 as credits.aleo/claim_unbond_public.future;
    lte block.height r0 into r2;
    assert.eq r2 true;
    await r1;




function set_validator_state:
    input r0 as u32.public;
    input r1 as boolean.public;
    call credits.aleo/set_validator_state r1 into r2;
    async set_validator_state r0 r2 into r3;
    output r3 as credits_ttl_wrapper.aleo/set_validator_state.future;

finalize set_validator_state:
    input r0 as u32.public;
    input r1 as credits.aleo/set_validator_state.future;
    lte block.height r0 into r2;
    assert.eq r2 true;
    await r1;




function transfer_public:
    input r0 as u32.public;
    input r1 as address.public;
    input r2 as u64.public;
    call credits.aleo/transfer_public r1 r2 into r3;
    async transfer_public r0 r3 into r4;
    output r4 as credits_ttl_wrapper.aleo/transfer_public.future;

finalize transfer_public:
    input r0 as u32.public;
    input r1 as credits.aleo/transfer_public.future;
    lte block.height r0 into r2;
    assert.eq r2 true;
    await r1;




function transfer_public_as_signer:
    input r0 as u32.public;
    input r1 as address.public;
    input r2 as u64.public;
    call credits.aleo/transfer_public_as_signer r1 r2 into r3;
    async transfer_public_as_signer r0 r3 into r4;
    output r4 as credits_ttl_wrapper.aleo/transfer_public_as_signer.future;

finalize transfer_public_as_signer:
    input r0 as u32.public;
    input r1 as credits.aleo/transfer_public_as_signer.future;
    lte block.height r0 into r2;
    assert.eq r2 true;
    await r1;




function transfer_private:
    input r0 as u32.public;
    input r1 as credits.aleo/credits.record;
    input r2 as address.private;
    input r3 as u64.private;
    call credits.aleo/transfer_private r1 r2 r3 into r4 r5;
    async transfer_private r0 into r6;
    output r4 as credits.aleo/credits.record;
    output r5 as credits.aleo/credits.record;
    output r6 as credits_ttl_wrapper.aleo/transfer_private.future;

finalize transfer_private:
    input r0 as u32.public;
    lte block.height r0 into r1;
    assert.eq r1 true;




function transfer_private_to_public:
    input r0 as u32.public;
    input r1 as credits.aleo/credits.record;
    input r2 as address.public;
    input r3 as u64.public;
    call credits.aleo/transfer_private_to_public r1 r2 r3 into r4 r5;
    async transfer_private_to_public r0 r5 into r6;
    output r4 as credits.aleo/credits.record;
    output r6 as credits_ttl_wrapper.aleo/transfer_private_to_public.future;

finalize transfer_private_to_public:
    input r0 as u32.public;
    input r1 as credits.aleo/transfer_private_to_public.future;
    lte block.height r0 into r2;
    assert.eq r2 true;
    await r1;




function transfer_public_to_private:
    input r0 as u32.public;
    input r1 as address.private;
    input r2 as u64.public;
    call credits.aleo/transfer_public_to_private r1 r2 into r3 r4;
    async transfer_public_to_private r0 r4 into r5;
    output r3 as credits.aleo/credits.record;
    output r5 as credits_ttl_wrapper.aleo/transfer_public_to_private.future;

finalize transfer_public_to_private:
    input r0 as u32.public;
    input r1 as credits.aleo/transfer_public_to_private.future;
    lte block.height r0 into r2;
    assert.eq r2 true;
    await r1;




function join:
    input r0 as u32.public;
    input r1 as credits.aleo/credits.record;
    input r2 as credits.aleo/credits.record;
    call credits.aleo/join r1 r2 into r3;
    async join r0 into r4;
    output r3 as credits.aleo/credits.record;
    output r4 as credits_ttl_wrapper.aleo/join.future;

finalize join:
    input r0 as u32.public;
    lte block.height r0 into r1;
    assert.eq r1 true;




function split:
    input r0 as u32.public;
    input r1 as credits.aleo/credits.record;
    input r2 as u64.private;
    call credits.aleo/split r1 r2 into r3 r4;
    async split r0 into r5;
    output r3 as credits.aleo/credits.record;
    output r4 as credits.aleo/credits.record;
    output r5 as credits_ttl_wrapper.aleo/split.future;

finalize split:
    input r0 as u32.public;
    lte block.height r0 into r1;
    assert.eq r1 true;

