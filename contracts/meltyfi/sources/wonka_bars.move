/// WonkaBars - Lottery ticket NFTs for MeltyFi Protocol
module meltyfi::wonka_bars {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::transfer;

    // ======== Error Codes ========
    const EInvalidQuantity: u64 = 1;
    const EInsufficientQuantity: u64 = 2;
    const EIncompatibleWonkaBars: u64 = 3;
    const ENotOwner: u64 = 4;

    // ======== Types ========

    /// WonkaBars NFT representing lottery tickets
    public struct WonkaBars has key, store {
        id: UID,
        lottery_id: u64,
        quantity: u64,
        owner: address,
        name: std::string::String,
        description: std::string::String,
        image_url: std::string::String,
        ticket_start: u64,
        ticket_end: u64,
        created_at: u64,
    }

    // ======== Events ========

    public struct WonkaBarsCreated has copy, drop {
        id: sui::object::ID,
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
        id1: sui::object::ID,
        id2: sui::object::ID,
        lottery_id: u64,
        total_quantity: u64,
    }

    public struct WonkaBarsTransferred has copy, drop {
        id: sui::object::ID,
        from: address,
        to: address,
        lottery_id: u64,
        quantity: u64,
    }

    public struct WonkaBarsBurned has copy, drop {
        id: sui::object::ID,
        lottery_id: u64,
        quantity: u64,
        owner: address,
    }

    // ======== Public Functions ========

    /// Create metadata strings for WonkaBars
    fun create_name(lottery_id: u64, quantity: u64): std::string::String {
        std::string::utf8(b"MeltyFi WonkaBars #")
    }

    fun create_description(lottery_id: u64): std::string::String {
        std::string::utf8(b"Official lottery tickets for MeltyFi Protocol")
    }

    fun create_image_url(lottery_id: u64): std::string::String {
        std::string::utf8(b"https://meltyfi.nft/images/wonka-bars.png")
    }

    /// Mint new WonkaBars with specific ticket numbers
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

        let wonka_bars = WonkaBars {
            id: object::new(ctx),
            lottery_id,
            quantity,
            owner,
            name: create_name(lottery_id, quantity),
            description: create_description(lottery_id),
            image_url: create_image_url(lottery_id),
            ticket_start,
            ticket_end,
            created_at: tx_context::epoch_timestamp_ms(ctx),
        };

        event::emit(WonkaBarsCreated {
            id: object::id(&wonka_bars),
            lottery_id,
            quantity,
            owner,
            ticket_start,
            ticket_end,
        });

        wonka_bars
    }

    /// Mint new WonkaBars (without specific ticket numbers)
    public fun mint(
        lottery_id: u64,
        quantity: u64,
        owner: address,
        ctx: &mut TxContext
    ): WonkaBars {
        mint_with_tickets(lottery_id, quantity, owner, 0, quantity - 1, ctx)
    }

    /// Split WonkaBars into two parts
    public fun split(
        wonka_bars: &mut WonkaBars,
        split_quantity: u64,
        ctx: &mut TxContext
    ): WonkaBars {
        assert!(split_quantity > 0, EInvalidQuantity);
        assert!(split_quantity < wonka_bars.quantity, EInsufficientQuantity);

        let original_id = object::id(wonka_bars);
        let remaining_quantity = wonka_bars.quantity - split_quantity;

        // Update original WonkaBars
        wonka_bars.quantity = remaining_quantity;
        wonka_bars.ticket_end = wonka_bars.ticket_start + remaining_quantity - 1;

        // Create new WonkaBars for split portion
        let new_wonka_bars = WonkaBars {
            id: object::new(ctx),
            lottery_id: wonka_bars.lottery_id,
            quantity: split_quantity,
            owner: wonka_bars.owner,
            name: create_name(wonka_bars.lottery_id, split_quantity),
            description: wonka_bars.description,
            image_url: wonka_bars.image_url,
            ticket_start: wonka_bars.ticket_end + 1,
            ticket_end: wonka_bars.ticket_end + split_quantity,
            created_at: wonka_bars.created_at,
        };

        event::emit(WonkaBarsSplit {
            original_id,
            new_id: object::id(&new_wonka_bars),
            lottery_id: wonka_bars.lottery_id,
            split_quantity,
            remaining_quantity,
        });

        new_wonka_bars
    }

    /// Merge two WonkaBars from same lottery and owner
    public fun merge(
        wonka_bars1: &mut WonkaBars,
        wonka_bars2: WonkaBars,
    ) {
        assert!(wonka_bars1.lottery_id == wonka_bars2.lottery_id, EIncompatibleWonkaBars);
        assert!(wonka_bars1.owner == wonka_bars2.owner, EIncompatibleWonkaBars);

        let id2 = object::id(&wonka_bars2);
        let quantity2 = wonka_bars2.quantity;

        // Update first WonkaBars
        wonka_bars1.quantity = wonka_bars1.quantity + quantity2;
        wonka_bars1.ticket_end = wonka_bars1.ticket_end + quantity2;

        event::emit(WonkaBarsMerged {
            id1: object::id(wonka_bars1),
            id2,
            lottery_id: wonka_bars1.lottery_id,
            total_quantity: wonka_bars1.quantity,
        });

        // Destroy the second WonkaBars
        let WonkaBars { 
            id, 
            lottery_id: _, 
            quantity: _, 
            owner: _, 
            name: _, 
            description: _, 
            image_url: _, 
            ticket_start: _, 
            ticket_end: _, 
            created_at: _ 
        } = wonka_bars2;
        object::delete(id);
    }

    /// Transfer WonkaBars to new owner
    public fun transfer_wonka_bars(wonka_bars: &mut WonkaBars, new_owner: address) {
        let old_owner = wonka_bars.owner;
        wonka_bars.owner = new_owner;

        event::emit(WonkaBarsTransferred {
            id: object::id(wonka_bars),
            from: old_owner,
            to: new_owner,
            lottery_id: wonka_bars.lottery_id,
            quantity: wonka_bars.quantity,
        });
    }

    /// Burn WonkaBars (destroy them)
    public fun burn(wonka_bars: WonkaBars) {
        let id = object::id(&wonka_bars);
        let lottery_id = wonka_bars.lottery_id;
        let quantity = wonka_bars.quantity;
        let owner = wonka_bars.owner;

        event::emit(WonkaBarsBurned {
            id,
            lottery_id,
            quantity,
            owner,
        });

        let WonkaBars { 
            id, 
            lottery_id: _, 
            quantity: _, 
            owner: _, 
            name: _, 
            description: _, 
            image_url: _, 
            ticket_start: _, 
            ticket_end: _, 
            created_at: _ 
        } = wonka_bars;
        object::delete(id);
    }

    // ======== View Functions ========

    /// Get WonkaBars quantity
    public fun quantity(wonka_bars: &WonkaBars): u64 {
        wonka_bars.quantity
    }

    /// Get lottery ID
    public fun lottery_id(wonka_bars: &WonkaBars): u64 {
        wonka_bars.lottery_id
    }

    /// Get owner address
    public fun owner(wonka_bars: &WonkaBars): address {
        wonka_bars.owner
    }

    /// Get ticket range
    public fun ticket_range(wonka_bars: &WonkaBars): (u64, u64) {
        (wonka_bars.ticket_start, wonka_bars.ticket_end)
    }

    /// Get creation timestamp
    public fun created_at(wonka_bars: &WonkaBars): u64 {
        wonka_bars.created_at
    }

    /// Get name
    public fun name(wonka_bars: &WonkaBars): std::string::String {
        wonka_bars.name
    }

    /// Get description
    public fun description(wonka_bars: &WonkaBars): std::string::String {
        wonka_bars.description
    }

    /// Get image URL
    public fun image_url(wonka_bars: &WonkaBars): std::string::String {
        wonka_bars.image_url
    }

    /// Check if a specific ticket number is contained in these WonkaBars
    public fun contains_ticket(wonka_bars: &WonkaBars, ticket_number: u64): bool {
        ticket_number >= wonka_bars.ticket_start && ticket_number <= wonka_bars.ticket_end
    }

    /// Get ticket start number
    public fun ticket_start(wonka_bars: &WonkaBars): u64 {
        wonka_bars.ticket_start
    }

    /// Get ticket end number
    public fun ticket_end(wonka_bars: &WonkaBars): u64 {
        wonka_bars.ticket_end
    }

    // ======== Utility Functions ========

    /// Check if two WonkaBars are compatible for merging
    public fun are_compatible(wonka_bars1: &WonkaBars, wonka_bars2: &WonkaBars): bool {
        wonka_bars1.lottery_id == wonka_bars2.lottery_id && 
        wonka_bars1.owner == wonka_bars2.owner
    }

    /// Get total ticket count across multiple WonkaBars
    public fun total_tickets(wonka_bars_list: &vector<WonkaBars>): u64 {
        let mut total = 0;
        let mut i = 0;
        let length = std::vector::length(wonka_bars_list);
        
        while (i < length) {
            let wonka_bars = std::vector::borrow(wonka_bars_list, i);
            total = total + wonka_bars.quantity;
            i = i + 1;
        };
        
        total
    }

    // ======== Test Functions ========

    #[test_only]
    public fun mint_for_testing(
        lottery_id: u64,
        quantity: u64,
        owner: address,
        ctx: &mut TxContext
    ): WonkaBars {
        mint(lottery_id, quantity, owner, ctx)
    }

    #[test_only]
    public fun mint_with_tickets_for_testing(
        lottery_id: u64,
        quantity: u64,
        owner: address,
        ticket_start: u64,
        ticket_end: u64,
        ctx: &mut TxContext
    ): WonkaBars {
        mint_with_tickets(lottery_id, quantity, owner, ticket_start, ticket_end, ctx)
    }
}