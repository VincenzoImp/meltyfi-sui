/// WonkaBars - Lottery ticket NFTs for MeltyFi Protocol
module meltyfi::wonka_bars {
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::display;
    use sui::package;
    use sui::transfer;

    // ======== Error Codes ========
    const EInvalidQuantity: u64 = 1;
    const EInsufficientQuantity: u64 = 2;
    const ELotteryMismatch: u64 = 3;
    const ENotOwner: u64 = 4;
    const EInvalidOperation: u64 = 5;

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
        /// Ticket numbers for this batch
        ticket_start: u64,
        ticket_end: u64,
        /// Creation timestamp
        created_at: u64,
    }

    /// One-time witness for creating the display
    public struct WONKA_BARS has drop {}

    // ======== Events ========

    public struct WonkaBarsCreated has copy, drop {
        id: sui::object::ID,
        lottery_id: u64,
        quantity: u64,
        owner: address,
        ticket_start: u64,
        ticket_end: u64,
    }

    public struct WonkaBarsBurned has copy, drop {
        lottery_id: u64,
        quantity: u64,
        owner: address,
        ticket_start: u64,
        ticket_end: u64,
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

    public struct WonkaBarsTransferred has copy, drop {
        id: sui::object::ID,
        lottery_id: u64,
        from: address,
        to: address,
        quantity: u64,
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
        display::add(&mut display, string::utf8(b"ticket_range"), string::utf8(b"Tickets #{ticket_start} - #{ticket_end}"));
        display::add(&mut display, string::utf8(b"project_url"), string::utf8(b"https://meltyfi.nft"));
        display::add(&mut display, string::utf8(b"creator"), string::utf8(b"MeltyFi Protocol"));
        display::add(&mut display, string::utf8(b"category"), string::utf8(b"Lottery Ticket"));
        
        display::update_version(&mut display);
        
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    // ======== Public Functions ========

    /// Mint new WonkaBars for a lottery with ticket numbers
    public fun mint_with_tickets(
        lottery_id: u64,
        quantity: u64,
        owner: address,
        ticket_start: u64,
        ticket_end: u64,
        ctx: &mut TxContext
    ): WonkaBars {
        assert!(quantity > 0, EInvalidQuantity);
        assert!(ticket_end >= ticket_start, EInvalidQuantity);
        assert!(ticket_end - ticket_start + 1 == quantity, EInvalidQuantity);
        
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
            ticket_start,
            ticket_end,
            created_at: sui::tx_context::epoch_timestamp_ms(ctx),
        };

        event::emit(WonkaBarsCreated {
            id: sui::object::id(&wonka_bars),
            lottery_id,
            quantity,
            owner,
            ticket_start,
            ticket_end,
        });

        wonka_bars
    }

    /// Mint new WonkaBars for a lottery (legacy function for compatibility)
    public fun mint(
        lottery_id: u64,
        quantity: u64,
        owner: address,
        ctx: &mut TxContext
    ): WonkaBars {
        // For legacy compatibility, create dummy ticket range
        mint_with_tickets(lottery_id, quantity, owner, 0, quantity - 1, ctx)
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
            ticket_start,
            ticket_end,
            created_at: _,
        } = wonka_bars;

        event::emit(WonkaBarsBurned {
            lottery_id,
            quantity,
            owner,
            ticket_start,
            ticket_end,
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
        
        // Update original WonkaBars
        let original_end = wonka_bars.ticket_end;
        wonka_bars.quantity = wonka_bars.quantity - split_quantity;
        wonka_bars.ticket_end = wonka_bars.ticket_start + wonka_bars.quantity - 1;
        wonka_bars.name = create_name(wonka_bars.lottery_id, wonka_bars.quantity);
        
        // Create new WonkaBars with remaining tickets
        let new_ticket_start = wonka_bars.ticket_end + 1;
        let new_wonka_bars = mint_with_tickets(
            wonka_bars.lottery_id,
            split_quantity,
            wonka_bars.owner,
            new_ticket_start,
            original_end,
            ctx
        );

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
        assert!(wonka_bars.owner == other.owner, ENotOwner);
        
        let WonkaBars { 
            id, 
            lottery_id: _, 
            quantity, 
            owner: _,
            name: _,
            description: _,
            image_url: _,
            ticket_start: other_start,
            ticket_end: other_end,
            created_at: _,
        } = other;

        // Update ticket range - merge adjacent ranges if possible
        let new_start = if (wonka_bars.ticket_start < other_start) {
            wonka_bars.ticket_start
        } else {
            other_start
        };
        
        let new_end = if (wonka_bars.ticket_end > other_end) {
            wonka_bars.ticket_end
        } else {
            other_end
        };

        wonka_bars.quantity = wonka_bars.quantity + quantity;
        wonka_bars.ticket_start = new_start;
        wonka_bars.ticket_end = new_end;
        wonka_bars.name = create_name(wonka_bars.lottery_id, wonka_bars.quantity);

        event::emit(WonkaBarsMerged {
            kept_id: sui::object::id(wonka_bars),
            merged_id: sui::object::uid_to_inner(&id),
            lottery_id: wonka_bars.lottery_id,
            total_quantity: wonka_bars.quantity,
        });

        sui::object::delete(id);
    }

    /// Transfer WonkaBars to new owner
    public fun transfer_wonka_bars(wonka_bars: &mut WonkaBars, new_owner: address) {
        let old_owner = wonka_bars.owner;
        wonka_bars.owner = new_owner;

        event::emit(WonkaBarsTransferred {
            id: sui::object::id(wonka_bars),
            lottery_id: wonka_bars.lottery_id,
            from: old_owner,
            to: new_owner,
            quantity: wonka_bars.quantity,
        });
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

    /// Get ticket range
    public fun ticket_range(wonka_bars: &WonkaBars): (u64, u64) {
        (wonka_bars.ticket_start, wonka_bars.ticket_end)
    }

    /// Get creation timestamp
    public fun created_at(wonka_bars: &WonkaBars): u64 {
        wonka_bars.created_at
    }

    /// Check if ticket number is in this WonkaBars range
    public fun contains_ticket(wonka_bars: &WonkaBars, ticket_number: u64): bool {
        ticket_number >= wonka_bars.ticket_start && ticket_number <= wonka_bars.ticket_end
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

    // ======== Utility Functions ========

    /// Calculate win probability percentage (returns basis points)
    public fun calculate_win_probability(
        wonka_bars: &WonkaBars,
        total_tickets: u64
    ): u64 {
        if (total_tickets == 0) {
            return 0
        };
        (wonka_bars.quantity * 10000) / total_tickets // Returns basis points (1% = 100)
    }

    /// Check if WonkaBars can be merged
    public fun can_merge(wonka_bars1: &WonkaBars, wonka_bars2: &WonkaBars): bool {
        wonka_bars1.lottery_id == wonka_bars2.lottery_id && 
        wonka_bars1.owner == wonka_bars2.owner
    }

    /// Get total ticket count for multiple WonkaBars
    public fun total_tickets(wonka_bars_list: &vector<WonkaBars>): u64 {
        let mut total = 0;
        let mut i = 0;
        while (i < vector::length(wonka_bars_list)) {
            let wonka_bars = vector::borrow(wonka_bars_list, i);
            total = total + wonka_bars.quantity;
            i = i + 1;
        };
        total
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

    #[test_only]
    public fun create_with_tickets_for_testing(
        lottery_id: u64,
        quantity: u64,
        owner: address,
        ticket_start: u64,
        ticket_end: u64,
        ctx: &mut TxContext
    ): WonkaBars {
        mint_with_tickets(lottery_id, quantity, owner, ticket_start, ticket_end, ctx)
    }

    #[test_only]
    public fun get_ticket_start_for_testing(wonka_bars: &WonkaBars): u64 {
        wonka_bars.ticket_start
    }

    #[test_only]
    public fun get_ticket_end_for_testing(wonka_bars: &WonkaBars): u64 {
        wonka_bars.ticket_end
    }
}