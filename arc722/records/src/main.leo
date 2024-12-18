/*

    Collection registry for NFTs with public/private data and public/private owner.

*/


program nft_records.aleo {
    struct Data {
        metadata: field
    }

    record NFT {
        private owner: address,
        private collection_id: field,
        private data: Data,
        private edition: scalar,
    }

    record NFTView {
        private owner: address,
        private data: Data,
        private edition: scalar,
        public is_view: bool,
    }


    transition mint_nft(
        private owner: address,
        private collection_id: field,
        private data: Data,
        private edition: scalar,
    ) -> NFT {
        assert(self.caller == nft_registry.aleo || self.caller == nft_collections.aleo);
        return NFT{
            owner: owner,
            collection_id: collection_id,
            data: data,
            edition: edition
        };
    }


    transition burn_nft(
        nft: NFT
    ){
        assert_eq(self.caller, nft_registry.aleo);
    }


    transition transfer_nft(
        nft: NFT,
        private recipient: address,
    ) -> NFT {
        assert_eq(self.caller, nft_registry.aleo);
        return NFT {
            owner: recipient,
            collection_id: nft.collection_id,
            data: nft.data,
            edition: nft.edition,
        };
    }


    transition update_nft_edition(
        nft: NFT,
        private new_edition: scalar,
    ) -> NFT {
        assert_eq(self.caller, nft_registry.aleo);
        return NFT {
            owner: nft.owner,
            collection_id: nft.collection_id,
            data: nft.data,
            edition: new_edition,
        };
    }


    transition mint_nft_view(
        private owner: address,
        private data: Data,
        private edition: scalar,
    ) -> NFTView {
        assert(self.caller == nft_registry.aleo || self.caller == nft_collections.aleo);
        return NFTView{
            owner: owner,
            data: data,
            edition: edition,
            is_view: true
        };
    }

}