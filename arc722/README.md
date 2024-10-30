# Aleo NFT Registry

ARC722 defines a registry for NFTs to extend ARC721 standard, as ARC21 does for ARC20 fungible tokens.

More over, ARC722 can be implemented with any 'Data' struct, allowing abitrary on-chain NFT data.

## Registry list enforcement

1. Explorers could maintain a list of valid ARC722 implementations.
2. Wallets could feature adding registry program, as metamask does for token contracts.

Collections would then be identified by pairs: (registry_program_id, token_id).
