//:!:>moon
module MEME::meme {
    use aptos_std::type_info;
    use std::signer;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::string;
    use std::error;
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability};

    //
    // Errors
    //

    const ENO_CAPABILITIES: u64 = 1;
    const ERR_NOT_OWNER: u64 = 1111;
    const MINT_OUT_OF_SUPPLY: u64 = 1112;
    const ALREADYED_INIT: u64 = 1114;
    //
    // Data structures
    //

    struct MEME {}

    /// Account has no capabilities (burn/mint).
    /// Capabilities resource storing mint and burn capabilities.
    /// The resource is stored on the account that initialized coin `CoinType`.
    struct Capabilities<phantom CoinType> has key {
        burn_cap: BurnCapability<CoinType>,
        freeze_cap: FreezeCapability<CoinType>,
        mint_cap: MintCapability<CoinType>,
        max_supply:u64,
    }

    //
    // Public functions
    //

    /// Withdraw an `amount` of coin `CoinType` from `account` and burn it.
    public entry fun burn(
        account: &signer,
        amount: u64,
    ) acquires Capabilities {
        let account_addr = signer::address_of(account);

        assert!(
            exists<Capabilities<MEME>>(account_addr),
            error::not_found(ALREADYED_INIT),
        );

        let capabilities = borrow_global<Capabilities<MEME>>(account_addr);

        let to_burn = coin::withdraw<MEME>(account, amount);
        coin::burn(to_burn, &capabilities.burn_cap);
    }


    /// Create new coins `CoinType` and deposit them into dst_addr's account.
    fun mint(
        account: &signer,
        dst_addr: address,
        amount: u64,
    ) acquires Capabilities {
        let account_addr = signer::address_of(account);
        assert!(
            exists<Capabilities<MEME>>(account_addr),
            error::not_found(ENO_CAPABILITIES),
        );
        let capabilities = borrow_global<Capabilities<MEME>>(account_addr);
        let coins_minted = coin::mint(amount, &capabilities.mint_cap);
        coin::deposit(dst_addr, coins_minted);
    }

    /// Creating a resource that stores balance of `CoinType` on user's account, withdraw and deposit event handlers.
    /// Required if user wants to start accepting deposits of `CoinType` in his account.
    public entry fun register<CoinType>(account: &signer) {
        coin::register<CoinType>(account);
    }

    //
    // Tests
    //


    public entry fun owner_deploy(sender: &signer,name: vector<u8>,symbol: vector<u8>,decimals: u8,max_supply:u64,monitor_supply: bool) acquires Capabilities {
        let type_info = type_info::type_of<MEME>();
        let type_infos = type_info::account_address(&type_info);
        assert!(
            type_infos == signer::address_of(sender),
            ERR_NOT_OWNER
        );
        assert!(
            !coin::is_coin_initialized<MEME>(),
            ALREADYED_INIT
        );
        coin::transfer<AptosCoin>(sender,@admin_account,100000000);

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<MEME>(
            sender,
            string::utf8(name),
            string::utf8(symbol),
            decimals,
            monitor_supply,
        );
        coin::register<MEME>(sender);

        move_to(sender, Capabilities<MEME> {
            burn_cap,
            freeze_cap,
            mint_cap,
            max_supply,
        });

        mint(sender,signer::address_of(sender),max_supply);
    }
}
//<:!:moon
