program nft_registry.aleo;

struct CollectionMetadata:
    collection_id as field;
    base_uri as [field; 4u32];
    metadata_uri as [field; 4u32];

struct Data:
    metadata as [field; 4u32];

struct Approval:
    collection_id as field;
    approver as address;
    spender as address;

struct NFTId:
    collection_id as field;
    nft_commit as field;

struct NFTContent:
    data as Data;
    edition as scalar;

record NFT:
    owner as address.private;
    collection_id as field.private;
    data as Data.private;
    edition as scalar.private;

record Authorization:
    owner as address.private;
    collection_id as field.private;

record NFTView:
    owner as address.private;
    data as Data.private;
    edition as scalar.private;
    is_view as boolean.public;


mapping nft_ids:
	key as field.public;
	value as NFTId.public;


mapping nft_owners:
	key as field.public;
	value as address.public;


mapping for_all_approvals:
	key as field.public;
	value as boolean.public;


mapping nft_approvals:
	key as field.public;
	value as field.public;


mapping registered_collections:
	key as field.public;
	value as CollectionMetadata.public;


mapping collection_admins:
	key as field.public;
	value as address.public;


mapping nft_contents:
	key as field.public;
	value as NFTContent.public;


function register_collection:
    input r0 as field.public;
    input r1 as [field; 4u32].public;
    input r2 as [field; 4u32].public;
    cast r0 r1 r2 into r3 as CollectionMetadata;
    async register_collection r3 self.caller into r4;
    output r4 as nft_registry.aleo/register_collection.future;

finalize register_collection:
    input r0 as CollectionMetadata.public;
    input r1 as address.public;
    contains registered_collections[r0.collection_id] into r2;
    not r2 into r3;
    assert.eq r3 true;
    set r0 into registered_collections[r0.collection_id];
    set r1 into collection_admins[r0.collection_id];




function mint_authorization_as_signer:
    input r0 as field.public;
    input r1 as Data.private;
    input r2 as scalar.private;
    cast self.signer r0 into r3 as Authorization.record;
    async mint_authorization_as_signer r0 self.caller into r4;
    output r3 as Authorization.record;
    output r4 as nft_registry.aleo/mint_authorization_as_signer.future;

finalize mint_authorization_as_signer:
    input r0 as field.public;
    input r1 as address.public;
    get collection_admins[r0] into r2;
    assert.eq r2 r1;




function update_admin:
    input r0 as field.public;
    input r1 as address.public;
    async update_admin r0 self.caller r1 into r2;
    output r2 as nft_registry.aleo/update_admin.future;

finalize update_admin:
    input r0 as field.public;
    input r1 as address.public;
    input r2 as address.public;
    get collection_admins[r0] into r3;
    assert.eq r3 r1;
    set r2 into collection_admins[r0];




function update_collection_data:
    input r0 as field.public;
    input r1 as [field; 4u32].public;
    input r2 as [field; 4u32].public;
    cast r0 r1 r2 into r3 as CollectionMetadata;
    async update_collection_data r0 self.caller r3 into r4;
    output r4 as nft_registry.aleo/update_collection_data.future;

finalize update_collection_data:
    input r0 as field.public;
    input r1 as address.public;
    input r2 as CollectionMetadata.public;
    get collection_admins[r0] into r3;
    assert.eq r3 r1;
    set r2 into registered_collections[r0];



function burn_authorization:
    input r0 as Authorization.record;
    assert.eq true true;





function auth_mint_private:
    input r0 as Authorization.record;
    input r1 as address.private;
    input r2 as Data.private;
    input r3 as scalar.private;
    cast r0.owner r0.collection_id into r4 as Authorization.record;
    cast r1 r0.collection_id r2 r3 into r5 as NFT.record;
    hash.bhp256 r2 into r6 as field;
    commit.bhp256 r6 r3 into r7 as field;
    cast r5.collection_id r7 into r8 as NFTId;
    hash.bhp256 r8 into r9 as field;
    async auth_mint_private r9 r8 into r10;
    output r4 as Authorization.record;
    output r5 as NFT.record;
    output r10 as nft_registry.aleo/auth_mint_private.future;

finalize auth_mint_private:
    input r0 as field.public;
    input r1 as NFTId.public;
    contains nft_ids[r0] into r2;
    not r2 into r3;
    assert.eq r3 true;
    set r1 into nft_ids[r0];



function auth_burn_private:
    input r0 as Authorization.record;
    input r1 as NFT.record;
    assert.eq r0.collection_id r1.collection_id;
    cast r0.owner r0.collection_id into r2 as Authorization.record;
    output r2 as Authorization.record;



function mint_private:
    input r0 as address.private;
    input r1 as field.private;
    input r2 as Data.private;
    input r3 as scalar.private;
    cast r0 r1 r2 r3 into r4 as NFT.record;
    hash.bhp256 r2 into r5 as field;
    commit.bhp256 r5 r3 into r6 as field;
    cast r4.collection_id r6 into r7 as NFTId;
    hash.bhp256 r7 into r8 as field;
    async mint_private r1 self.caller r8 r7 into r9;
    output r4 as NFT.record;
    output r9 as nft_registry.aleo/mint_private.future;

finalize mint_private:
    input r0 as field.public;
    input r1 as address.public;
    input r2 as field.public;
    input r3 as NFTId.public;
    get collection_admins[r0] into r4;
    assert.eq r4 r1;
    contains nft_ids[r2] into r5;
    not r5 into r6;
    assert.eq r6 true;
    set r3 into nft_ids[r2];




function burn_private:
    input r0 as NFT.record;
    async burn_private r0.collection_id self.caller into r1;
    output r1 as nft_registry.aleo/burn_private.future;

finalize burn_private:
    input r0 as field.public;
    input r1 as address.public;
    get collection_admins[r0] into r2;
    assert.eq r2 r1;




function auth_mint_public:
    input r0 as Authorization.record;
    input r1 as address.public;
    input r2 as Data.private;
    input r3 as scalar.private;
    cast r0.owner r0.collection_id into r4 as Authorization.record;
    cast r1 r2 r3 true into r5 as NFTView.record;
    hash.bhp256 r2 into r6 as field;
    commit.bhp256 r6 r3 into r7 as field;
    cast r0.collection_id r7 into r8 as NFTId;
    hash.bhp256 r8 into r9 as field;
    async auth_mint_public r9 r8 r1 into r10;
    output r5 as NFTView.record;
    output r4 as Authorization.record;
    output r10 as nft_registry.aleo/auth_mint_public.future;

finalize auth_mint_public:
    input r0 as field.public;
    input r1 as NFTId.public;
    input r2 as address.public;
    contains nft_ids[r0] into r3;
    not r3 into r4;
    assert.eq r4 true;
    set r1 into nft_ids[r0];
    set r2 into nft_owners[r0];




function mint_public:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as Data.private;
    input r3 as scalar.private;
    cast r0 r2 r3 true into r4 as NFTView.record;
    hash.bhp256 r2 into r5 as field;
    commit.bhp256 r5 r3 into r6 as field;
    cast r1 r6 into r7 as NFTId;
    hash.bhp256 r7 into r8 as field;
    async mint_public r1 self.caller r8 r7 r0 into r9;
    output r4 as NFTView.record;
    output r9 as nft_registry.aleo/mint_public.future;

finalize mint_public:
    input r0 as field.public;
    input r1 as address.public;
    input r2 as field.public;
    input r3 as NFTId.public;
    input r4 as address.public;
    get collection_admins[r0] into r5;
    assert.eq r5 r1;
    contains nft_ids[r2] into r6;
    not r6 into r7;
    assert.eq r7 true;
    set r3 into nft_ids[r2];
    set r4 into nft_owners[r2];



function transfer_private:
    input r0 as NFT.record;
    input r1 as address.private;
    cast r1 r0.collection_id r0.data r0.edition into r2 as NFT.record;
    output r2 as NFT.record;





function transfer_private_to_public:
    input r0 as NFT.record;
    input r1 as address.public;
    cast r1 r0.data r0.edition true into r2 as NFTView.record;
    hash.bhp256 r0.data into r3 as field;
    commit.bhp256 r3 r0.edition into r4 as field;
    cast r0.collection_id r4 into r5 as NFTId;
    hash.bhp256 r5 into r6 as field;
    async transfer_private_to_public r1 r6 into r7;
    output r2 as NFTView.record;
    output r7 as nft_registry.aleo/transfer_private_to_public.future;

finalize transfer_private_to_public:
    input r0 as address.public;
    input r1 as field.public;
    set r0 into nft_owners[r1];




function transfer_public:
    input r0 as field.private;
    input r1 as Data.private;
    input r2 as scalar.private;
    input r3 as address.public;
    cast r3 r1 r2 true into r4 as NFTView.record;
    hash.bhp256 r1 into r5 as field;
    commit.bhp256 r5 r2 into r6 as field;
    cast r0 r6 into r7 as NFTId;
    hash.bhp256 r7 into r8 as field;
    async transfer_public r3 r8 self.caller into r9;
    output r4 as NFTView.record;
    output r9 as nft_registry.aleo/transfer_public.future;

finalize transfer_public:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as address.public;
    get nft_owners[r1] into r3;
    assert.eq r2 r3;
    remove nft_approvals[r1];
    set r0 into nft_owners[r1];




function transfer_public_as_signer:
    input r0 as field.private;
    input r1 as Data.private;
    input r2 as scalar.private;
    input r3 as address.public;
    cast r3 r1 r2 true into r4 as NFTView.record;
    hash.bhp256 r1 into r5 as field;
    commit.bhp256 r5 r2 into r6 as field;
    cast r0 r6 into r7 as NFTId;
    hash.bhp256 r7 into r8 as field;
    async transfer_public_as_signer r3 r8 self.signer into r9;
    output r4 as NFTView.record;
    output r9 as nft_registry.aleo/transfer_public_as_signer.future;

finalize transfer_public_as_signer:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as address.public;
    get nft_owners[r1] into r3;
    assert.eq r2 r3;
    remove nft_approvals[r1];
    set r0 into nft_owners[r1];




function transfer_public_to_private:
    input r0 as field.private;
    input r1 as Data.private;
    input r2 as scalar.private;
    input r3 as address.private;
    hash.bhp256 r1 into r4 as field;
    commit.bhp256 r4 r2 into r5 as field;
    cast r0 r5 into r6 as NFTId;
    hash.bhp256 r6 into r7 as field;
    async transfer_public_to_private self.caller r7 into r8;
    cast r3 r0 r1 r2 into r9 as NFT.record;
    output r9 as NFT.record;
    output r8 as nft_registry.aleo/transfer_public_to_private.future;

finalize transfer_public_to_private:
    input r0 as address.public;
    input r1 as field.public;
    get nft_owners[r1] into r2;
    assert.eq r0 r2;
    remove nft_approvals[r1];
    remove nft_owners[r1];






function set_for_all_approval:
    input r0 as field.private;
    input r1 as address.private;
    input r2 as boolean.public;
    cast r0 self.caller r1 into r3 as Approval;
    hash.bhp256 r3 into r4 as field;
    async set_for_all_approval r4 r2 into r5;
    output r5 as nft_registry.aleo/set_for_all_approval.future;

finalize set_for_all_approval:
    input r0 as field.public;
    input r1 as boolean.public;
    set r1 into for_all_approvals[r0];




function approve_public:
    input r0 as field.private;
    input r1 as address.private;
    input r2 as Data.private;
    input r3 as scalar.private;
    hash.bhp256 r2 into r4 as field;
    commit.bhp256 r4 r3 into r5 as field;
    cast r0 r5 into r6 as NFTId;
    hash.bhp256 r6 into r7 as field;
    cast r0 self.caller r1 into r8 as Approval;
    hash.bhp256 r8 into r9 as field;
    async approve_public self.caller r9 r7 into r10;
    output r10 as nft_registry.aleo/approve_public.future;

finalize approve_public:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as field.public;
    get nft_owners[r2] into r3;
    assert.eq r3 r0;
    set r1 into nft_approvals[r2];




function unapprove_public:
    input r0 as field.private;
    input r1 as Data.private;
    input r2 as scalar.private;
    hash.bhp256 r1 into r3 as field;
    commit.bhp256 r3 r2 into r4 as field;
    cast r0 r4 into r5 as NFTId;
    hash.bhp256 r5 into r6 as field;
    async unapprove_public self.caller r6 into r7;
    output r7 as nft_registry.aleo/unapprove_public.future;

finalize unapprove_public:
    input r0 as address.public;
    input r1 as field.public;
    get nft_owners[r1] into r2;
    assert.eq r2 r0;
    remove nft_approvals[r1];




function transfer_from_public:
    input r0 as field.private;
    input r1 as address.public;
    input r2 as address.public;
    input r3 as Data.private;
    input r4 as scalar.private;
    hash.bhp256 r3 into r5 as field;
    commit.bhp256 r5 r4 into r6 as field;
    cast r0 r6 into r7 as NFTId;
    hash.bhp256 r7 into r8 as field;
    cast r0 r1 self.caller into r9 as Approval;
    hash.bhp256 r9 into r10 as field;
    async transfer_from_public r10 r1 r2 r8 into r11;
    cast r2 r3 r4 true into r12 as NFTView.record;
    output r12 as NFTView.record;
    output r11 as nft_registry.aleo/transfer_from_public.future;

finalize transfer_from_public:
    input r0 as field.public;
    input r1 as address.public;
    input r2 as address.public;
    input r3 as field.public;
    contains nft_approvals[r3] into r4;
    get.or_use for_all_approvals[r0] false into r5;
    or r4 r5 into r6;
    assert.eq r6 true;
    get nft_owners[r3] into r7;
    assert.eq r1 r7;
    remove nft_approvals[r3];
    set r2 into nft_owners[r3];




function update_edition_private:
    input r0 as NFT.record;
    input r1 as scalar.private;
    cast r0.owner r0.collection_id r0.data r1 into r2 as NFT.record;
    hash.bhp256 r0.data into r3 as field;
    commit.bhp256 r3 r1 into r4 as field;
    cast r0.collection_id r4 into r5 as NFTId;
    hash.bhp256 r5 into r6 as field;
    async update_edition_private r6 r5 into r7;
    output r2 as NFT.record;
    output r7 as nft_registry.aleo/update_edition_private.future;

finalize update_edition_private:
    input r0 as field.public;
    input r1 as NFTId.public;
    contains nft_ids[r0] into r2;
    not r2 into r3;
    assert.eq r3 true;
    set r1 into nft_ids[r0];




function publish_nft_content:
    input r0 as Data.public;
    input r1 as scalar.public;
    hash.bhp256 r0 into r2 as field;
    commit.bhp256 r2 r1 into r3 as field;
    cast r0 r1 into r4 as NFTContent;
    async publish_nft_content r3 r4 into r5;
    output r5 as nft_registry.aleo/publish_nft_content.future;

finalize publish_nft_content:
    input r0 as field.public;
    input r1 as NFTContent.public;
    set r1 into nft_contents[r0];

