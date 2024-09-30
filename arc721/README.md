# New ARC0721 discussion

### 1. Strings

Both **`array`** and **`struct`** usage involve the same amount of constraints.

> #### Question #1
>
> Should we use array representation for strings instead of struct?

Both **`field`** and **`u128`** involve the same amount of constraints but fields can store roughly **`252 bits`** instead of **`128`**.

> #### Question #2
>
> Should we use **`[field; 4]`** instead of **`[u128; 4]`** ?

For what follows strings will be represented by symbol: **`string`**.

### 2. Onchain Metadata

For more general proof usecases, like proving your age, having some of the metadata accessible directly onchain might be necessary.

```rust
struct attribute {
    trait_type: string,
    _value: string,
}

struct data {
    metadata: string, // URL of offchain metadata JSON
    (optional) name: string,
    (optional) image: string, // URL of image
    (optional) attributes: [attribute; 4],
    // (optional) ...
}

record NFT {
    private owner: address,
    private data: data, // or field (hash of data)
    private edition: scalar,
}
```

Offchain metadata JSON could include all [the remaining metadata object fields](https://aleo-public.s3.us-west-2.amazonaws.com/testnet3/privacy-pride/1.json).

Then they could be merged, for instance in javascript:

```typescript
const all_nft_data = {
    ...await (await fetch(nft.data.metadata)).json(),
    ...nft.data,
}
```

> ### Question #3
>
> Do you see another way to have some NFT attributes onchain?

> ### Question #4
>
> If this is the standard, should data be hashed or put directly put into data attribute of the NFT record?
>
>

### 3. Public/private NFT owner

To implement a marketplace keeping lister address private, **`transfer_private_to_public`** is necessary. As using **`convert_private_to_public`** followed by **`transfer_public`** would compromise lister address.

> ### Question #5
>
> Should we update **`convert_private_to_public`** to  **`transfer_private_to_public`** with an additional **`to (address)`** argument?

### 4. Public/private NFT data

For NFT with public owner, data obfuscation can currently be achieved using a random edition scalar, although:

> ### Question #6
>
> With the current standard, for  publicly owned NFTs, how are wallets/dApps supposed to know the NFT data and edition if it was never shared offchain?

> ### Question #7
>
> Should we Integrate to **`transfer_public`** an output record containing NFT data like the following?

```rust
record NFTView {
    private owner: address,
    private data: data, // or field (hash of data)
    private edition: scalar,
}

async transition transfer_public(
    public data: [u128; 4],
    public edition: scalar,
    public to: address,
) -> (Future, NFTView) {
    let data_hash: field = BHP256::hash_to_field(data);
    let token_commit: field = BHP256::commit_to_field(
        data_hash, edition
    );
    let caller: address = self.caller;
    let transfer_public_future: Future = finalize_transfer_public(
            to, token_commit, caller,
    );
    let nft_data: NFTView = NFTView {
        owner: to
        data: data,
        edition: scalar,
    }
    return (
        transfer_public_future,
        nft_data
    );
}
async function finalize_transfer_public(
    public to: address,
    public token_commit: field,
    public caller: address,
) {
    let owner: address = nft_owners.get(token_commit);
    assert_eq(caller, owner);
    nft_approvals.remove(token_commit);
    nft_owners.set(token_commit, to);
}
```

> ### Question #8
>
> Should we include in the standard the possibility of (a subset of?) the data being made public using specific transitions ?

```rust
transition publish_data_private(
    private nft: NFT,
) -> (NFT, public data, public scalar) {
    return (
        NFT {
            owner: to,
            data: nft.data,
            edition: nft.scalar,
        },
        nft.data,
        nft.scalar
    );
}
```

If it's just a subset can be made public this means only some onchain attributes should be made public (lets call them publicizable attributes ?).

> ### Question #9
>
> Should this be included in a mapping for ease of use for DApp/wallets?

> ### Question #10
>
> Should we Integrate a transition to obfuscate back again the NFT data by updating the edition as the following?

```rust
transition update_edition_private(
    private nft: NFT,
    private edition: scalar,
) -> NFT {
    return NFT {
        owner: to,
        data: nft.data,
        edition: scalar,
    };
}
```

This allows to change the NFT identifier (tokenEditionHash or token_commit).
