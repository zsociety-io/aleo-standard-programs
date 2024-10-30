# ARC-0722

**Title:** Aleo NFT Registry<br/>
**Authors:** Capncrunch<br/>
**Discussion:** ARC-0722 Aleo NFT Registry<br/>
**Topic:** Application<br/>
**Status:** Draft<br/>
**Created:** 2024-10-14<br/>

## Abstract

The Aleo NFT Registry extends ARC721 standard, defining a registry for NFTs through ARC722 standard, similar to how ARC21 builds on ARC20 for fungible tokens.

Moreover, ARC722 can be implemented with any `Data` struct type, allowing abitrary on-chain NFT data.

[An example implementation is available here](./src/main.leo), with `Data` defined as:

```rust
struct Data {
    metadata: [field; 4]
}
```

## Enforcing Registry list

Here are two possible ways of registry program enforcement.

1. Explorers could maintain a list of valid ARC722 implementations.
2. Wallets could allow to add custom registry programs, similar to how MetaMask allows adding custom token contracts.

Feel free to make any suggestions.

NFT collections are then identified by the unique pair: `(registry_program_id, collection_id)`.
