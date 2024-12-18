/*

    Collection registry for NFTs with public/private data and public/private owner.

*/
import nft_registry.aleo;
import nft_records.aleo;


program nft_collections.aleo {
    const ADMIN_NFTS_COLLECTION_ID: field = 0field;
    const ADMIN_NFTS_EDITION: scalar = 0scalar;

    struct CollectionMetadata {
        collection_id: field,
        base_uri: [field; 4],
        metadata_uri: [field; 4]
    }

    struct Data {
        metadata: field
    }

    struct Approval {
        collection_id: field,
        approver: address,
        spender: address,
    }

    struct NFTId {
        collection_id: field,
        nft_commit: field
    }


    mapping registered_collections: field => CollectionMetadata;
    // Collection ID => Collection Metadata


    inline commit_nft(
        nft_data: Data,
        nft_edition: scalar
    ) -> field {
        let data_hash: field = BHP256::hash_to_field(nft_data);
        let commitment: field = BHP256::commit_to_field(data_hash, nft_edition);
        return commitment;
    }
    
    inline hash_nft_id(
        collection_id: field,
        nft_data: Data,
        nft_edition: scalar,
    ) -> field {
        let nft_commit: field = commit_nft(nft_data, nft_edition);
        let nft_id: NFTId = NFTId {
            collection_id: collection_id,
            nft_commit: nft_commit
        };
        let nft_id_hash: field = BHP256::hash_to_field(nft_id);
        return nft_id_hash;
    }

    inline null_metadata() -> [field; 4] {
        return [0field, 0field, 0field, 0field];
    }

    inline field_nft_data(collection_id: field) -> Data {
        return Data {
            metadata: collection_id
        };
    }

    inline hash_admin_nft_id(collection_id: field) -> field {
        let nft_data: Data = field_nft_data(collection_id);
        let admin_nft_id_hash: field = hash_nft_id(
            ADMIN_NFTS_COLLECTION_ID,
            nft_data,
            ADMIN_NFTS_EDITION
        );
        return admin_nft_id_hash;
    }

    
    async transition initialize() -> Future {
        let registry_future: Future = nft_registry.aleo/set_collection_admin(
            ADMIN_NFTS_COLLECTION_ID,
            nft_registry.aleo,
            true
        );
        return finalize_initialize(
            registry_future
        );
    }
    async function finalize_initialize(
        registry_future: Future
    ) {
        let collection: CollectionMetadata = CollectionMetadata {
            collection_id: ADMIN_NFTS_COLLECTION_ID,
            base_uri: null_metadata(),
            metadata_uri: null_metadata()
        };
        // Register collection for "admin" NFTs.
        let collection_exists: bool = registered_collections.contains(
            ADMIN_NFTS_COLLECTION_ID
        );
        assert(collection_exists.not());
        registered_collections.set(
            ADMIN_NFTS_COLLECTION_ID, collection
        );

        registry_future.await();
    }


    async transition register_collection_public(
        public collection_id: field,
        public base_uri: [field; 4],
        public metadata_uri: [field; 4]
    ) -> (nft_records.aleo/NFTView, Future) {
        assert(collection_id != 0field);
        let collection: CollectionMetadata = CollectionMetadata {
            collection_id: collection_id,
            base_uri: base_uri,
            metadata_uri: metadata_uri
        };
        let nft_data: Data = field_nft_data(collection_id);
        let admin_nft_view: nft_records.aleo/NFTView = 
            nft_records.aleo/mint_nft_view(
                self.caller, nft_data, ADMIN_NFTS_EDITION
            );
        // Compute details of "admin" NFT of the collection, recipient is the caller.
        let registry_future: Future = nft_registry.aleo/set_collection_admin(
            collection_id,
            self.caller,
            true
        );
        let register_collection_public_future: Future = 
            fin_register_collection_public(
                collection, registry_future
            );
        return (admin_nft_view, register_collection_public_future);
    }
    async function fin_register_collection_public(
        collection: CollectionMetadata,
        registry_future: Future
    ) {
        // Check collection does not exist yet
        let collection_exists: bool = registered_collections.contains(
            collection.collection_id
        );
        assert(collection_exists.not());
        // Register collection
        registered_collections.set(collection.collection_id, collection);
        registry_future.await();
    }


    async transition register_collection_private(
        public collection_id: field,
        public base_uri: [field; 4],
        public metadata_uri: [field; 4]
    ) -> (nft_records.aleo/NFT, Future) {
        assert(collection_id != 0field);
        let collection: CollectionMetadata = CollectionMetadata {
            collection_id: collection_id,
            base_uri: base_uri,
            metadata_uri: metadata_uri
        };
        // Mint "admin" NFT of the collection, recipient is the signer.
        let nft_data: Data = field_nft_data(collection_id);

        let admin_nft: nft_records.aleo/NFT = nft_records.aleo/mint_nft(
            self.signer,
            ADMIN_NFTS_COLLECTION_ID,
            nft_data,
            ADMIN_NFTS_EDITION
        );
        let registry_future: Future = nft_registry.aleo/set_collection_admin(
            collection_id,
            aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc,
            false
        );

        let register_collection_private_future: Future = 
            fin_register_collection_private(
                collection, registry_future
            );
        return (admin_nft, register_collection_private_future);
    }
    async function fin_register_collection_private(
        collection: CollectionMetadata,
        registry_future: Future
    ) {
        // Check collection does not exist yet
        let collection_exists: bool = registered_collections.contains(
            collection.collection_id
        );
        assert(collection_exists.not());

        // Register collection
        registered_collections.set(collection.collection_id, collection);

        registry_future.await();
    }


    async transition update_collection_private(
        admin_nft: nft_records.aleo/NFT,
        public new_base_uri: [field; 4],
        public new_metadata_uri: [field; 4]
    ) -> Future {
        assert_eq(admin_nft.collection_id, ADMIN_NFTS_COLLECTION_ID);
        let collection_id: field = admin_nft.data.metadata;

        let new_collection_data: CollectionMetadata = CollectionMetadata {
            collection_id: collection_id,
            base_uri: new_base_uri,
            metadata_uri: new_metadata_uri
        };
        let update_collection_future: Future = 
            fin_update_collection_private(new_collection_data);
        return update_collection_future;
    }
    async function fin_update_collection_private(
        new_collection_data: CollectionMetadata
    ) {
        registered_collections.set(
            new_collection_data.collection_id, new_collection_data
        );
    }


    async transition update_collection_public(
        public collection_id: field,
        public new_base_uri: [field; 4],
        public new_metadata_uri: [field; 4]
    ) -> Future {
        let new_collection_data: CollectionMetadata = CollectionMetadata {
            collection_id: collection_id,
            base_uri: new_base_uri,
            metadata_uri: new_metadata_uri
        };
        let admin_nft_id_hash: field = hash_admin_nft_id(collection_id);
        let update_collection_public_future: Future = 
            fin_update_collection_public(
                collection_id, self.caller, admin_nft_id_hash, new_collection_data
            );
        return update_collection_public_future;
    }
    async function fin_update_collection_public(
        collection_id: field,
        caller: address,
        admin_nft_id_hash: field,
        new_collection_data: CollectionMetadata
    ) {
        let admin: address = nft_registry.aleo/nft_owners.get(admin_nft_id_hash);
        assert_eq(admin, caller);
        registered_collections.set(collection_id, new_collection_data);
    }
}