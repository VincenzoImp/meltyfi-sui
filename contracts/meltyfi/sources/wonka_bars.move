/// WonkaBars - Lottery ticket NFTs for MeltyFi Protocol
module meltyfi::wonka_bars {
    use std::string::{Self, String};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::display;
    use sui::package;

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

    // ======== Initialization ========

    fun init(otw: WONKA_BARS, ctx: &mut TxContext) {
        // Create display object for WonkaBars NFTs
        let publisher = package::claim(otw, ctx);
        let mut display = display::new<WonkaBars>(&publisher, ctx);
        
        display::add(&mut display, string::utf8(b"name"), string::utf8(b"{name}"));
        display::add(&mut display, string::utf8(b"description"), string::utf8(b"{description}"));
        display::add(&mut display, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
        display::add(&mut display, string::utf8(b"lottery_id"), string::utf8(b"{lottery_id}"));
        display::add(&mut display, string::utf8(b"quantity"), string::utf8(b"{quantity}"));
        display::add(&mut display, string::utf8(b"project_url"), string::utf8(b"https://meltyfi.nft"));
        
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
        let name = string::utf8(b"WonkaBar Lottery Ticket");
        let description = create_description();
        let image_url = create_image_url();
        
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
        assert!(wonka_bars.quantity > split_quantity, 0);
        
        wonka_bars.quantity = wonka_bars.quantity - split_quantity;
        
        mint(
            wonka_bars.lottery_id,
            split_quantity,
            wonka_bars.owner,
            ctx
        )
    }

    /// Merge WonkaBars from the same lottery
    public fun merge(wonka_bars: &mut WonkaBars, other: WonkaBars) {
        assert!(wonka_bars.lottery_id == other.lottery_id, 1);
        
        let WonkaBars { 
            id, 
            lottery_id: _, 
            quantity, 
            owner: _,
            name: _,
            description: _,
            image_url: _,
        } = other;

        wonka_bars.quantity = wonka_bars.quantity + quantity;
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

    /// Create description based on lottery details
    fun create_description(): String {
        string::utf8(b"MeltyFi WonkaBar lottery tickets - your golden ticket to win NFT collateral or get refunded with ChocoChip rewards!")
    }

    /// Create image URL based on lottery ID
    fun create_image_url(): String {
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