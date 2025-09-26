/// WonkaBars - Lottery ticket NFTs for MeltyFi Protocol
module meltyfi::wonka_bars {
    use std::string::{Self, String};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::display;
    use sui::package;

    // ======== Error Codes ========
    const EInvalidQuantity: u64 = 1;
    const EInsufficientQuantity: u64 = 2;
    const ELotteryMismatch: u64 = 3;

    // ======== Types ========

    /// WonkaBars NFT representing lottery participation
    public struct WonkaBars has key, store {
        id: sui::object::UID,
        /// ID of the lottery this ticket belongs to
        lottery_id: u64,
        /// Number of tickets held
        quantity: u64,
        /// Owner of the tickets
        owner: address,
        /// Metadata for display
        name: String,
        description: String,
        image_url: String,
    }

    /// One-time witness for creating the display
    public struct WONKA_BARS has drop {}

    // ======== Events ========

    public struct WonkaBarsCreated has copy, drop {
        id: sui::object::ID,
        lottery_id: u64,
        quantity: u64,
        owner: address,
    }

    public struct WonkaBarsBurned has copy, drop {
        lottery_id: u64,
        quantity: u64,
        owner: address,
    }

    public struct WonkaBarsSplit has copy, drop {
        original_id: sui::object::ID,
        new_id: sui::object::ID,
        lottery_id: u64,
        split_quantity: u64,
        remaining_quantity: u64,
    }

    public struct WonkaBarsMerged has copy, drop {
        kept_id: sui::object::ID,
        merged_id: sui::object::ID,
        lottery_id: u64,
        total_quantity: u64,
    }

    // ======== Initialization ========

    fun init(otw: WONKA_BARS, ctx: &mut TxContext) {
        // Create display object for WonkaBars NFTs
        let publisher = package::claim(otw, ctx);
        let mut display = display::new<WonkaBars>(&publisher, ctx);
        
        display::add(&mut display, string::utf8(b"name"), string::utf8(b"{name}"));
        display::add(&mut display, string::utf8(b"description"), string::utf8(b"{description}"));
        display::add(&mut display, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
        display::add(&mut display, string::utf8(b"lottery_id"), string::utf8(b"Lottery #{lottery_id}"));
        display::add(&mut display, string::utf8(b"quantity"), string::utf8(b"{quantity} tickets"));
        display::add(&mut display, string::utf8(b"project_url"), string::utf8(b"https://meltyfi.nft"));
        display::add(&mut display, string::utf8(b"creator"), string::utf8(b"MeltyFi Protocol"));
        
        display::update_version(&mut display);
        
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    // ======== Public Functions ========

    /// Mint new WonkaBars for a lottery
    public fun mint(
        lottery_id: u64,
        quantity: u64,
        owner: address,
        ctx: &mut TxContext
    ): WonkaBars {
        assert!(quantity > 0, EInvalidQuantity);
        
        let name = create_name(lottery_id, quantity);
        let description = create_description(lottery_id);
        let image_url = create_image_url(lottery_id);
        
        let wonka_bars = WonkaBars {
            id: sui::object::new(ctx),
            lottery_id,
            quantity,
            owner,
            name,
            description,
            image_url,
        };

        event::emit(WonkaBarsCreated {
            id: sui::object::id(&wonka_bars),
            lottery_id,
            quantity,
            owner,
        });

        wonka_bars
    }

    /// Burn WonkaBars when redeeming rewards
    public fun burn(wonka_bars: WonkaBars) {
        let WonkaBars { 
            id, 
            lottery_id, 
            quantity, 
            owner,
            name: _,
            description: _,
            image_url: _,
        } = wonka_bars;

        event::emit(WonkaBarsBurned {
            lottery_id,
            quantity,
            owner,
        });

        sui::object::delete(id);
    }

    /// Split WonkaBars into smaller quantities
    public fun split(
        wonka_bars: &mut WonkaBars, 
        split_quantity: u64,
        ctx: &mut TxContext
    ): WonkaBars {
        assert!(split_quantity > 0, EInvalidQuantity);
        assert!(wonka_bars.quantity > split_quantity, EInsufficientQuantity);
        
        wonka_bars.quantity = wonka_bars.quantity - split_quantity;
        
        let new_wonka_bars = mint(
            wonka_bars.lottery_id,
            split_quantity,
            wonka_bars.owner,
            ctx
        );

        // Update the original WonkaBar's name to reflect new quantity
        wonka_bars.name = create_name(wonka_bars.lottery_id, wonka_bars.quantity);

        event::emit(WonkaBarsSplit {
            original_id: sui::object::id(wonka_bars),
            new_id: sui::object::id(&new_wonka_bars),
            lottery_id: wonka_bars.lottery_id,
            split_quantity,
            remaining_quantity: wonka_bars.quantity,
        });
        
        new_wonka_bars
    }

    /// Merge WonkaBars from the same lottery
    public fun merge(wonka_bars: &mut WonkaBars, other: WonkaBars) {
        assert!(wonka_bars.lottery_id == other.lottery_id, ELotteryMismatch);
        
        let WonkaBars { 
            id, 
            lottery_id: _, 
            quantity, 
            owner: _,
            name: _,
            description: _,
            image_url: _,
        } = other;

        let old_quantity = wonka_bars.quantity;
        wonka_bars.quantity = wonka_bars.quantity + quantity;
        
        // Update the name to reflect new quantity
        wonka_bars.name = create_name(wonka_bars.lottery_id, wonka_bars.quantity);

        event::emit(WonkaBarsMerged {
            kept_id: sui::object::id(wonka_bars),
            merged_id: sui::object::uid_to_inner(&id),
            lottery_id: wonka_bars.lottery_id,
            total_quantity: wonka_bars.quantity,
        });

        sui::object::delete(id);
    }

    // ======== View Functions ========

    /// Get lottery ID
    public fun lottery_id(wonka_bars: &WonkaBars): u64 {
        wonka_bars.lottery_id
    }

    /// Get quantity
    public fun quantity(wonka_bars: &WonkaBars): u64 {
        wonka_bars.quantity
    }

    /// Get owner
    public fun owner(wonka_bars: &WonkaBars): address {
        wonka_bars.owner
    }

    /// Get name
    public fun name(wonka_bars: &WonkaBars): String {
        wonka_bars.name
    }

    /// Get description
    public fun description(wonka_bars: &WonkaBars): String {
        wonka_bars.description
    }

    /// Get image URL
    public fun image_url(wonka_bars: &WonkaBars): String {
        wonka_bars.image_url
    }

    // ======== Internal Helper Functions ========

    /// Create name based on lottery ID and quantity
    fun create_name(lottery_id: u64, quantity: u64): String {
        if (quantity == 1) {
            string::utf8(b"WonkaBar Lottery Ticket")
        } else {
            string::utf8(b"WonkaBar Lottery Tickets")
        }
    }

    /// Create description based on lottery details
    fun create_description(lottery_id: u64): String {
        string::utf8(b"MeltyFi WonkaBar lottery tickets - your golden ticket to win NFT collateral or get refunded with ChocoChip rewards!")
    }

    /// Create image URL based on lottery ID
    fun create_image_url(lottery_id: u64): String {
        string::utf8(b"https://ipfs.io/ipfs/QmWonkaBarImage")
    }

    // ======== Test Functions ========

    #[test_only]
    public fun create_for_testing(
        lottery_id: u64,
        quantity: u64,
        owner: address,
        ctx: &mut TxContext
    ): WonkaBars {
        mint(lottery_id, quantity, owner, ctx)
    }
}