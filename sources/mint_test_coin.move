module MintToken::mint_test_coin {
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_account;

    /// Resource that holds mint capability in the module account for controlled minting
    struct MintCapHolder has key {
        cap: coin::MintCapability<Coin>,
    }

    /// The Coin type for the test token
    struct Coin has store, drop, key {}

    /// Initialize the coin with metadata and publishing account as admin.
    public entry fun init_module(account: &signer) {
        // Ensure this is only called once by the module address
        let module_addr = @MintToken;
        let caller = signer::address_of(account);
        assert!(caller == module_addr, 1);

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<Coin>(
            account,
            b"Mint Test Coin",
            b"MINT",
            6,
            true
        );

        // Save mint cap under module to control minting
        move_to(account, MintCapHolder { cap: mint_cap });

        // Register standard capabilities to module for completeness
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_freeze_cap(freeze_cap);

        // Also register the module to hold its own coin store so it can receive tokens
        coin::register<Coin>(account);
    }

    /// Mint to the caller's account after ensuring they are registered
    public entry fun mint(account: &signer, amount: u64) {
        let caller_addr = signer::address_of(account);
        if (!coin::is_account_registered<Coin>(caller_addr)) {
            coin::register<Coin>(account);
        }
        mint_to_internal(account, caller_addr, amount);
    }

    /// Mint to any recipient address (module address must sign)
    public entry fun mint_to(account: &signer, recipient: address, amount: u64) {
        let module_addr = @MintToken;
        assert!(signer::address_of(account) == module_addr, 2);
        mint_to_internal(account, recipient, amount);
    }

    fun mint_to_internal(account: &signer, recipient: address, amount: u64) {
        let MintCapHolder { cap } = borrow_global<MintCapHolder>(@MintToken);
        let coins = coin::mint<Coin>(amount, &cap);
        aptos_account::deposit_coins<Coin>(recipient, coins);
    }
}
