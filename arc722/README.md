# Aleo NFT Registry

The Aleo NFT Registry builds on the ARC721 standard, defining a registry for NFTs through the new ARC722 standard, similar to how ARC21 extends ARC20 for fungible tokens.

Moreover, ARC722 can be implemented with any 'Data' struct type, allowing abitrary on-chain NFT data.

## Registry list enforcement

1. Explorers could maintain a list of valid ARC722 implementations.
2. Wallets could allow to add custom registry programs, similar to how MetaMask allows adding custom token contracts.

Collections would then be identified by pairs: `(registry_program_id, token_id)`.
