/// ChocoChip - Governance token for MeltyFi Protocol
module meltyfi::choco_chip {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::tx_context::TxContext;
    use sui::url;
    use sui::event;

    // ======== Error Codes ========
    const ENotAuthorized: u64 = 1;
    const EInsufficientSupply: u64 = 2;
    const EInvalidAmount: u64 = 3;

    // ======== Constants ========
    const MAX_SUPPLY: u64 = 1_000_000_000_000_000_000; // 1 billion tokens with 9 decimals
    const DECIMALS: u8 = 9;

    // ======== Types ========

    public struct CHOCO_CHIP has drop {}

    public struct ChocolateFactory has key {
        id: sui::object::UID,
        treasury_cap: TreasuryCap<CHOCO_CHIP>,
        total_supply: u64,
        authorized_minters: vector<address>,
        max_supply: u64,
    }

    public struct FactoryAdmin has key, store {
        id: sui::object::UID,
    }
        treasury_cap: TreasuryCap<CHOCO_CHIP>,
        total_supply: u64,
        authorized_minters: vector<address>,
        max_supply: u64,
    }

    public struct FactoryAdmin has key, store {
        id: sui::object::UID,
    }

    // ======== Events ========

    public struct ChocolateMinted has copy, drop {
        recipient: address,
        amount: u64,
        reason: vector<u8>,
        minter: address,
    }

    public struct MinterAuthorized has copy, drop {
        minter: address,
        authorized_by: address,
    }

    public struct MinterRevoked has copy, drop {
        minter: address,
        revoked_by: address,
    }

    public struct SupplyBurned has copy, drop {
        amount: u64,
        burned_by: address,
    }

    // ======== Initialization ========

    fun init(witness: CHOCO_CHIP, ctx: &mut TxContext) {
        // Create currency using the standard coin framework
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            DECIMALS,
            b"CHOC",
            b"ChocoChip",
            b"Governance token for MeltyFi Protocol - Earn rewards through lottery participation",
            std::option::some(url::new_unsafe_from_bytes(b"https://meltyfi.nft/images/choco-chip.png")),
            ctx
        );

        let mut factory = ChocolateFactory {
            id: object::new(ctx),
            treasury_cap,
            total_supply: 0,
            authorized_minters: std::vector::empty(),
            max_supply: MAX_SUPPLY,
        };

        let admin = FactoryAdmin {
            id: object::new(ctx),
        };

        // Add the admin as an authorized minter initially
        let admin_address = tx_context::sender(ctx);
        std::vector::push_back(&mut factory.authorized_minters, admin_address);

        // Freeze the currency metadata and share the factory
        transfer::public_freeze_object(metadata);
        transfer::share_object(factory);
        transfer::transfer(admin, admin_address);

        event::emit(ChocolateMinted {
            recipient: admin_address,
            amount: 0,
            reason: b"Factory initialized",
            minter: admin_address,
        });
    }

    // ======== Public Functions ========

    /// Mint ChocoChips and return to caller (FIXED IMPLEMENTATION)
    public fun mint(
        factory: &mut ChocolateFactory,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ): Coin<CHOCO_CHIP> {
        let minter = tx_context::sender(ctx);
        assert!(std::vector::contains(&factory.authorized_minters, &minter), ENotAuthorized);
        assert!(amount > 0, EInvalidAmount);
        assert!(factory.total_supply + amount <= factory.max_supply, EInsufficientSupply);

        factory.total_supply = factory.total_supply + amount;
        let minted_coin = coin::mint(&mut factory.treasury_cap, amount, ctx);

        event::emit(ChocolateMinted {
            recipient,
            amount,
            reason: b"lottery_reward",
            minter,
        });

        minted_coin
    }

    /// Burn ChocoChips to reduce supply
    public fun burn(
        factory: &mut ChocolateFactory,
        coin_to_burn: Coin<CHOCO_CHIP>,
        ctx: &mut TxContext
    ) {
        let amount = coin::value(&coin_to_burn);
        assert!(amount > 0, EInvalidAmount);
        
        factory.total_supply = factory.total_supply - amount;
        coin::burn(&mut factory.treasury_cap, coin_to_burn);

        event::emit(SupplyBurned {
            amount,
            burned_by: tx_context::sender(ctx),
        });
    }

    // ======== Admin Functions ========

    /// Authorize a new minter
    public fun authorize_minter(
        factory: &mut ChocolateFactory,
        _admin: &FactoryAdmin,
        new_minter: address,
        ctx: &mut TxContext
    ) {
        assert!(!std::vector::contains(&factory.authorized_minters, &new_minter), ENotAuthorized);
        std::vector::push_back(&mut factory.authorized_minters, new_minter);

        event::emit(MinterAuthorized {
            minter: new_minter,
            authorized_by: tx_context::sender(ctx),
        });
    }

    /// Revoke minter authorization
    public fun revoke_minter(
        factory: &mut ChocolateFactory,
        _admin: &FactoryAdmin,
        minter_to_revoke: address,
        ctx: &mut TxContext
    ) {
        let (found, index) = std::vector::index_of(&factory.authorized_minters, &minter_to_revoke);
        assert!(found, ENotAuthorized);
        std::vector::remove(&mut factory.authorized_minters, index);

        event::emit(MinterRevoked {
            minter: minter_to_revoke,
            revoked_by: tx_context::sender(ctx),
        });
    }

    /// Update maximum supply (only increase allowed)
    public fun update_max_supply(
        factory: &mut ChocolateFactory,
        _admin: &FactoryAdmin,
        new_max_supply: u64
    ) {
        assert!(new_max_supply >= factory.total_supply, EInvalidAmount);
        factory.max_supply = new_max_supply;
    }

    // ======== View Functions ========

    /// Get total supply
    public fun total_supply(factory: &ChocolateFactory): u64 {
        factory.total_supply
    }

    /// Get maximum supply
    public fun max_supply(factory: &ChocolateFactory): u64 {
        factory.max_supply
    }

    /// Check if address is authorized minter
    public fun is_authorized_minter(factory: &ChocolateFactory, minter: address): bool {
        std::vector::contains(&factory.authorized_minters, &minter)
    }

    /// Get all authorized minters
    public fun get_authorized_minters(factory: &ChocolateFactory): &vector<address> {
        &factory.authorized_minters
    }

    /// Get remaining supply that can be minted
    public fun remaining_supply(factory: &ChocolateFactory): u64 {
        factory.max_supply - factory.total_supply
    }

    /// Get coin decimals
    public fun decimals(): u8 {
        DECIMALS
    }

    // ======== Utility Functions ========

    /// Get coin value
    public fun coin_value(coin_ref: &Coin<CHOCO_CHIP>): u64 {
        coin::value(coin_ref)
    }

    // ======== Test Functions ========

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        let witness = CHOCO_CHIP {};
        init(witness, ctx);
    }

    #[test_only]
    public fun mint_for_testing(
        factory: &mut ChocolateFactory,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ): Coin<CHOCO_CHIP> {
        mint(factory, amount, recipient, ctx)
    }
}