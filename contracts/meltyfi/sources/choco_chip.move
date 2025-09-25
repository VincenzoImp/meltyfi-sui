/// ChocoChip - Governance token for MeltyFi Protocol
/// ERC-20 equivalent implementation using Sui's Coin standard
module meltyfi::choco_chip {
    use std::option;
    use std::vector;
    use sui::object::{Self, UID};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url;
    use sui::event;
    use sui::balance::{Self, Balance};

    // ======== Types ========

    /// The ChocoChip token type
    public struct CHOCO_CHIP has drop {}

    /// Minting capability for ChocoChip tokens - shared object for protocol access
    public struct ChocolateFactory has key {
        id: UID,
        /// Treasury capability for minting/burning
        treasury_cap: TreasuryCap<CHOCO_CHIP>,
        /// Total supply tracking
        total_supply: u64,
        /// Authorized minters (protocol contracts)
        authorized_minters: vector<address>,
    }

    /// Admin capability for managing the factory
    public struct FactoryAdmin has key, store {
        id: UID,
    }

    // ======== Events ========

    public struct ChocolateMinted has copy, drop {
        recipient: address,
        amount: u64,
        reason: vector<u8>, // "lottery_participation", "winner_bonus", etc.
    }

    public struct ChocolateBurned has copy, drop {
        amount: u64,
        burner: address,
    }

    public struct MinterAuthorized has copy, drop {
        minter: address,
        admin: address,
    }

    // ======== Constants ========

    const DECIMALS: u8 = 9;
    const SYMBOL: vector<u8> = b"CHOCO";
    const NAME: vector<u8> = b"ChocoChip";
    const DESCRIPTION: vector<u8> = b"MeltyFi Protocol Governance Token - Sweet rewards for participating in the chocolate factory lending protocol";
    const ICON_URL: vector<u8> = b"https://ipfs.io/ipfs/QmChocoChipIcon123"; // Replace with actual IPFS hash

    // Error codes
    const ENotAuthorized: u64 = 1;
    const EAlreadyAuthorized: u64 = 2;
    const EInvalidAmount: u64 = 3;

    // ======== Initialization ========

    /// Initialize the ChocoChip token and chocolate factory
    fun init(witness: CHOCO_CHIP, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<CHOCO_CHIP>(
            witness,
            DECIMALS,
            SYMBOL,
            NAME,
            DESCRIPTION,
            option::some(url::new_unsafe_from_bytes(ICON_URL)),
            ctx
        );

        // Create the chocolate factory as a shared object
        let factory = ChocolateFactory {
            id: object::new(ctx),
            treasury_cap,
            total_supply: 0,
            authorized_minters: vector::empty(),
        };

        // Create admin capability
        let admin_cap = FactoryAdmin {
            id: object::new(ctx),
        };

        // Freeze metadata to prevent changes
        transfer::public_freeze_object(metadata);
        
        // Share the factory so protocols can access it
        transfer::share_object(factory);
        
        // Transfer admin capability to the deployer
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    // ======== Public Functions ========

    /// Mint ChocoChip tokens - restricted to authorized minters (protocol contracts)
    public fun mint(
        factory: &mut ChocolateFactory,
        amount: u64,
        recipient: address,
        reason: vector<u8>,
        ctx: &mut TxContext
    ): Coin<CHOCO_CHIP> {
        // Verify caller is authorized
        let caller = tx_context::sender(ctx);
        assert!(is_authorized_minter(factory, caller), ENotAuthorized);
        assert!(amount > 0, EInvalidAmount);

        // Mint the tokens
        let coin = coin::mint(&mut factory.treasury_cap, amount, ctx);
        factory.total_supply = factory.total_supply + amount;

        // Emit event
        event::emit(ChocolateMinted {
            recipient,
            amount,
            reason,
        });

        coin
    }

    /// Convenience function to mint and transfer in one call
    public fun mint_and_transfer(
        factory: &mut ChocolateFactory,
        amount: u64,
        recipient: address,
        reason: vector<u8>,
        ctx: &mut TxContext
    ) {
        let coin = mint(factory, amount, recipient, reason, ctx);
        transfer::public_transfer(coin, recipient);
    }

    /// Burn ChocoChip tokens to reduce supply
    public fun burn(
        factory: &mut ChocolateFactory,
        coin: Coin<CHOCO_CHIP>,
        ctx: &mut TxContext
    ): u64 {
        let amount = coin::value(&coin);
        coin::burn(&mut factory.treasury_cap, coin);
        
        factory.total_supply = factory.total_supply - amount;

        event::emit(ChocolateBurned {
            amount,
            burner: tx_context::sender(ctx),
        });

        amount
    }

    /// Split a coin into smaller denominations
    public fun split(
        coin: &mut Coin<CHOCO_CHIP>,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<CHOCO_CHIP> {
        coin::split(coin, amount, ctx)
    }

    /// Join two coins together
    public fun join(
        coin1: &mut Coin<CHOCO_CHIP>,
        coin2: Coin<CHOCO_CHIP>
    ) {
        coin::join(coin1, coin2);
    }

    /// Convert coin to balance
    public fun into_balance(coin: Coin<CHOCO_CHIP>): Balance<CHOCO_CHIP> {
        coin::into_balance(coin)
    }

    /// Convert balance to coin
    public fun from_balance(
        balance: Balance<CHOCO_CHIP>,
        ctx: &mut TxContext
    ): Coin<CHOCO_CHIP> {
        coin::from_balance(balance, ctx)
    }

    // ======== Admin Functions ========

    /// Authorize a new minter (typically protocol contracts)
    public fun authorize_minter(
        factory: &mut ChocolateFactory,
        _: &FactoryAdmin,
        new_minter: address,
        ctx: &mut TxContext
    ) {
        assert!(!is_authorized_minter(factory, new_minter), EAlreadyAuthorized);
        
        vector::push_back(&mut factory.authorized_minters, new_minter);

        event::emit(MinterAuthorized {
            minter: new_minter,
            admin: tx_context::sender(ctx),
        });
    }

    /// Remove minter authorization
    public fun revoke_minter(
        factory: &mut ChocolateFactory,
        _: &FactoryAdmin,
        minter: address,
    ) {
        let (found, index) = vector::index_of(&factory.authorized_minters, &minter);
        if (found) {
            vector::remove(&mut factory.authorized_minters, index);
        };
    }

    /// Emergency mint for initial distribution (admin only)
    public fun admin_mint(
        factory: &mut ChocolateFactory,
        _: &FactoryAdmin,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let coin = coin::mint(&mut factory.treasury_cap, amount, ctx);
        factory.total_supply = factory.total_supply + amount;

        event::emit(ChocolateMinted {
            recipient,
            amount,
            reason: b"admin_mint",
        });

        transfer::public_transfer(coin, recipient);
    }

    // ======== View Functions ========

    /// Check if an address is authorized to mint
    public fun is_authorized_minter(factory: &ChocolateFactory, minter: address): bool {
        vector::contains(&factory.authorized_minters, &minter)
    }

    /// Get total supply
    public fun total_supply(factory: &ChocolateFactory): u64 {
        factory.total_supply
    }

    /// Get list of authorized minters
    public fun get_authorized_minters(factory: &ChocolateFactory): vector<address> {
        factory.authorized_minters
    }

    /// Get token decimals
    public fun decimals(): u8 {
        DECIMALS
    }

    /// Get token symbol as string
    public fun symbol(): vector<u8> {
        SYMBOL
    }

    /// Get token name
    public fun name(): vector<u8> {
        NAME
    }

    /// Get coin value
    public fun value(coin: &Coin<CHOCO_CHIP>): u64 {
        coin::value(coin)
    }

    /// Create zero coin
    public fun zero(ctx: &mut TxContext): Coin<CHOCO_CHIP> {
        coin::zero<CHOCO_CHIP>(ctx)
    }

    // ======== Helper Functions for Protocol Integration ========

    /// Standard reward amount for lottery participation
    public fun participation_reward_amount(): u64 {
        100_000_000 // 0.1 CHOCO per participation
    }

    /// Bonus reward for lottery winners
    public fun winner_bonus_amount(): u64 {
        1_000_000_000 // 1 CHOCO bonus for winners
    }

    /// Calculate rewards based on SUI amount (used in core protocol)
    public fun calculate_reward_amount(sui_amount: u64): u64 {
        // 100 CHOCO per 1 SUI
        (sui_amount / 1_000_000_000) * 100_000_000_000
    }

    // ======== Test Functions ========

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext): (ChocolateFactory, FactoryAdmin) {
        let witness = CHOCO_CHIP {};
        let (treasury_cap, metadata) = coin::create_currency<CHOCO_CHIP>(
            witness,
            DECIMALS,
            SYMBOL,
            NAME,
            DESCRIPTION,
            option::none(),
            ctx
        );

        transfer::public_freeze_object(metadata);

        let factory = ChocolateFactory {
            id: object::new(ctx),
            treasury_cap,
            total_supply: 0,
            authorized_minters: vector::empty(),
        };

        let admin_cap = FactoryAdmin {
            id: object::new(ctx),
        };

        (factory, admin_cap)
    }

    #[test_only]
    public fun mint_for_testing(
        factory: &mut ChocolateFactory,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<CHOCO_CHIP> {
        let coin = coin::mint(&mut factory.treasury_cap, amount, ctx);
        factory.total_supply = factory.total_supply + amount;
        coin
    }
}