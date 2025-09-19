module MintToken::mint_test_coin {
    use std::signer;
    use std::string;
    use aptos_framework::coin;
    use aptos_framework::aptos_account;

    /// Resource that holds mint capability in the module account for controlled minting
    struct MintCapHolder has key {
        cap: coin::MintCapability<Coin>,
    }

    /// Resource that holds coin metadata that can be updated
    struct CoinMetadata has key {
        name: string::String,
        symbol: string::String,
        decimals: u8,
        is_mintable: bool,
    }

    /// The Coin type for the test token
    struct Coin has store, drop, key {}

    /// Initialize the coin with metadata and publishing account as admin.
    fun init_module(account: &signer) {
        // Ensure this is only called once by the module address
        let module_addr = @MintToken;
        let caller = signer::address_of(account);
        assert!(caller == module_addr, 1);

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<Coin>(
            account,
            string::utf8(b"USDC Coin"),
            string::utf8(b"USDC"),
            6,
            true
        );

        // Save mint cap under module to control minting
        move_to(account, MintCapHolder { cap: mint_cap });

        // Initialize metadata resource
        move_to(account, CoinMetadata {
            name: string::utf8(b"USDC Coin"),
            symbol: string::utf8(b"USDC"),
            decimals: 6,
            is_mintable: true,
        });

        // Register standard capabilities to module for completeness
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_freeze_cap(freeze_cap);

        // Also register the module to hold its own coin store so it can receive tokens
        coin::register<Coin>(account);
    }

    /// Mint to the caller's account after ensuring they are registered
    public entry fun mint(account: &signer, amount: u64) acquires MintCapHolder, CoinMetadata {
        let caller_addr = signer::address_of(account);
        if (!coin::is_account_registered<Coin>(caller_addr)) {
            coin::register<Coin>(account);
        };
        
        // Check if minting is allowed
        let metadata = borrow_global<CoinMetadata>(@MintToken);
        assert!(metadata.is_mintable, 5);
        
        mint_to_internal(account, caller_addr, amount);
    }

    /// Mint to any recipient address (module address must sign)
    public entry fun mint_to(account: &signer, recipient: address, amount: u64) acquires MintCapHolder, CoinMetadata {
        let module_addr = @MintToken;
        assert!(signer::address_of(account) == module_addr, 2);
        
        // Check if minting is allowed
        let metadata = borrow_global<CoinMetadata>(@MintToken);
        assert!(metadata.is_mintable, 5);
        
        mint_to_internal(account, recipient, amount);
    }

    fun mint_to_internal(_account: &signer, recipient: address, amount: u64) acquires MintCapHolder {
        let holder = borrow_global<MintCapHolder>(@MintToken);
        let coins = coin::mint<Coin>(amount, &holder.cap);
        aptos_account::deposit_coins<Coin>(recipient, coins);
    }

    /// Update coin metadata (only module address can call)
    public entry fun update_metadata(
        account: &signer,
        new_name: string::String,
        new_symbol: string::String,
        new_decimals: u8,
        new_is_mintable: bool
    ) acquires CoinMetadata {
        let module_addr = @MintToken;
        assert!(signer::address_of(account) == module_addr, 3);
        
        let metadata = borrow_global_mut<CoinMetadata>(@MintToken);
        metadata.name = new_name;
        metadata.symbol = new_symbol;
        metadata.decimals = new_decimals;
        metadata.is_mintable = new_is_mintable;
    }

    /// Get current coin metadata
    public fun get_metadata(): (string::String, string::String, u8, bool) acquires CoinMetadata {
        let metadata = borrow_global<CoinMetadata>(@MintToken);
        (metadata.name, metadata.symbol, metadata.decimals, metadata.is_mintable)
    }

    /// Check if minting is currently allowed
    public fun is_mintable(): bool acquires CoinMetadata {
        let metadata = borrow_global<CoinMetadata>(@MintToken);
        metadata.is_mintable
    }

    /// Pause/unpause minting
    public entry fun set_mintable(account: &signer, mintable: bool) acquires CoinMetadata {
        let module_addr = @MintToken;
        assert!(signer::address_of(account) == module_addr, 4);
        
        let metadata = borrow_global_mut<CoinMetadata>(@MintToken);
        metadata.is_mintable = mintable;
    }
}
