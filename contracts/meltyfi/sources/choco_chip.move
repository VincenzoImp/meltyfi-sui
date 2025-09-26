/// ChocoChip - Governance token for MeltyFi Protocol
module meltyfi::choco_chip {
    use std::vector;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url;
    use sui::event;

    // ======== Error Codes ========
    const ENotAuthorized: u64 = 1;

    // ======== Types ========

    public struct CHOCO_CHIP has drop {}

    public struct ChocolateFactory has key {
        id: sui::object::UID,
        treasury_cap: TreasuryCap<CHOCO_CHIP>,
        total_supply: u64,
        authorized_minters: vector<address>,
    }

    public struct FactoryAdmin has key, store {
        id: sui::object::UID,
    }

    // ======== Events ========

    public struct ChocolateMinted has copy, drop {
        recipient: address,
        amount: u64,
        reason: vector<u8>,
    }

    public struct MinterAuthorized has copy, drop {
        minter: address,
        authorized_by: address,
    }

    public struct MinterRevoked has copy, drop {
        minter: address,
        revoked_by: address,
    }

    // ======== Initialization ========

    #[allow(deprecated_usage)]
    fun init(witness: CHOCO_CHIP, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness, 
            9, // decimals
            b"CHOCO",
            b"ChocoChip",
            b"Governance token for MeltyFi Protocol - Earn rewards through lottery participation",
            std::option::some(url::new_unsafe_from_bytes(b"https://meltyfi.nft/images/choco-chip.png")),
            ctx
        );

        let mut factory = ChocolateFactory {
            id: sui::object::new(ctx),
            treasury_cap,
            total_supply: 0,
            authorized_minters: vector::empty(),
        };

        let admin = FactoryAdmin {
            id: sui::object::new(ctx),
        };

        // Add the admin as an authorized minter initially
        let admin_address = tx_context::sender(ctx);
        vector::push_back(&mut factory.authorized_minters, admin_address);

        transfer::public_freeze_object(metadata);
        transfer::share_object(factory);
        transfer::transfer(admin, admin_address);
    }

    // ======== Public Functions ========

    public fun mint(
        factory: &mut ChocolateFactory,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ): Coin<CHOCO_CHIP> {
        let minter = tx_context::sender(ctx);
        assert!(vector::contains(&factory.authorized_minters, &minter), ENotAuthorized);

        factory.total_supply = factory.total_supply + amount;
        let minted_coin = coin::mint(&mut factory.treasury_cap, amount, ctx);

        event::emit(ChocolateMinted {
            recipient,
            amount,
            reason: b"lottery_reward",
        });

        // Transfer the minted coin to the recipient
        transfer::public_transfer(minted_coin, recipient);
        
        // Return a zero coin for consistency with the interface
        coin::zero(ctx)
    }

    public fun authorize_minter(
        factory: &mut ChocolateFactory,
        _admin: &FactoryAdmin,
        new_minter: address,
        ctx: &mut TxContext
    ) {
        if (!vector::contains(&factory.authorized_minters, &new_minter)) {
            vector::push_back(&mut factory.authorized_minters, new_minter);
            
            event::emit(MinterAuthorized {
                minter: new_minter,
                authorized_by: tx_context::sender(ctx),
            });
        }
    }

    public fun revoke_minter(
        factory: &mut ChocolateFactory,
        _admin: &FactoryAdmin,
        minter_to_revoke: address,
        ctx: &mut TxContext
    ) {
        let (found, index) = vector::index_of(&factory.authorized_minters, &minter_to_revoke);
        if (found) {
            vector::remove(&mut factory.authorized_minters, index);
            
            event::emit(MinterRevoked {
                minter: minter_to_revoke,
                revoked_by: tx_context::sender(ctx),
            });
        }
    }

    // ======== View Functions ========

    public fun total_supply(factory: &ChocolateFactory): u64 {
        factory.total_supply
    }

    public fun is_authorized_minter(factory: &ChocolateFactory, minter: address): bool {
        vector::contains(&factory.authorized_minters, &minter)
    }

    public fun get_authorized_minters(factory: &ChocolateFactory): &vector<address> {
        &factory.authorized_minters
    }

    // ======== Test Functions ========

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        let witness = CHOCO_CHIP {};
        init(witness, ctx);
    }
}