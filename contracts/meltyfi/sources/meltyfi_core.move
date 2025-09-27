// ==================== meltyfi_core.move ====================

/// MeltyFi Protocol - Core protocol for NFT-collateralized lending through lottery mechanics
module meltyfi::meltyfi_core {
    use std::string::{Self, String};
    use std::vector;
    use std::option::{Self, Option};
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table};
    use sui::dynamic_object_field as dof;
    use sui::random::{Self, Random};
    use sui::transfer;
    
    use meltyfi::choco_chip::{Self, ChocolateFactory, CHOCO_CHIP};
    use meltyfi::wonka_bars::{Self, WonkaBars};

    // ======== Error Codes ========
    
    const ELotteryNotFound: u64 = 2;
    const EInvalidLotteryState: u64 = 3;
    const EInsufficientPayment: u64 = 4;
    const ELotteryExpired: u64 = 5;
    const ELotteryNotExpired: u64 = 6;
    const EInvalidAmount: u64 = 7;
    const EMaxSupplyReached: u64 = 8;
    const EBalanceExceedsLimit: u64 = 10;
    const ENotAuthorized: u64 = 11;
    const ENoParticipants: u64 = 12;
    const EInvalidWinningTicket: u64 = 13;

    // ======== Constants ========
    
    const PROTOCOL_FEE_BPS: u64 = 500;
    const BASIS_POINTS: u64 = 10000;
    const MAX_WONKABAR_SUPPLY: u64 = 10000;
    const MAX_BALANCE_PERCENTAGE: u64 = 2000; // 20%
    const CHOCOCHIPS_PER_SUI: u64 = 100;

    // ======== Lottery States ========
    const LOTTERY_ACTIVE: u8 = 0;
    const LOTTERY_CANCELLED: u8 = 1;
    const LOTTERY_CONCLUDED: u8 = 2;

    // ======== Types ========

    /// Main protocol object - shared
    public struct Protocol has key {
        id: UID,
        admin: address,
        total_lotteries: u64,
        treasury: Balance<SUI>,
        active_lotteries: vector<ID>,
        paused: bool,
    }

    /// Individual lottery instance - shared
    public struct Lottery has key {
        id: UID,
        lottery_id: u64,
        owner: address,
        state: u8,
        expiration_date: u64,
        wonkabar_price: u64,
        max_supply: u64,
        sold_count: u64,
        winner: Option<address>,
        winning_ticket: u64,
        funds: Balance<SUI>,
        participants: Table<address, u64>,
        participant_list: vector<address>,
        ticket_ranges: Table<address, TicketRange>,
        total_ticket_numbers: u64,
    }

    /// Proof of lottery creation
    public struct LotteryReceipt has key, store {
        id: UID,
        lottery_id: u64,
        owner: address,
    }

    /// Admin capability
    public struct AdminCap has key, store {
        id: UID,
    }

    /// Ticket range for participants
    public struct TicketRange has store {
        start: u64,
        end: u64,
    }

    // ======== Events ========

    public struct LotteryCreated has copy, drop {
        lottery_id: u64,
        owner: address,
        expiration_date: u64,
        wonkabar_price: u64,
        max_supply: u64,
        initial_payout: u64,
    }

    public struct WonkaBarsPurchased has copy, drop {
        lottery_id: u64,
        buyer: address,
        quantity: u64,
        total_cost: u64,
        ticket_range_start: u64,
        ticket_range_end: u64,
    }

    public struct LotteryWinnerDrawn has copy, drop {
        lottery_id: u64,
        winner: address,
        winning_ticket: u64,
        total_participants: u64,
    }

    public struct WonkaBarsRedeemed has copy, drop {
        lottery_id: u64,
        redeemer: address,
        quantity: u64,
        payout: u64,
        choco_reward: u64,
    }

    public struct LotteryCancelled has copy, drop {
        lottery_id: u64,
        reason: String,
    }

    public struct ProtocolPaused has copy, drop {
        paused: bool,
        admin: address,
    }

    // ======== Initialization ========

    fun init(ctx: &mut TxContext) {
        let admin = tx_context::sender(ctx);
        
        let protocol = Protocol {
            id: object::new(ctx),
            admin,
            total_lotteries: 0,
            treasury: balance::zero<SUI>(),
            active_lotteries: vector::empty(),
            paused: false,
        };

        let admin_cap = AdminCap {
            id: object::new(ctx),
        };

        transfer::share_object(protocol);
        transfer::transfer(admin_cap, admin);
    }

    // ======== Public Functions ========

    /// Create a new lottery with NFT collateral
    public fun create_lottery<T: key + store>(
        protocol: &mut Protocol,
        nft: T,
        expiration_date: u64,
        wonkabar_price: u64,
        max_supply: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): LotteryReceipt {
        assert!(!protocol.paused, EInvalidLotteryState);
        assert!(expiration_date > clock::timestamp_ms(clock), ELotteryExpired);
        assert!(wonkabar_price > 0, EInvalidAmount);
        assert!(max_supply > 0 && max_supply <= MAX_WONKABAR_SUPPLY, EInvalidAmount);

        let lottery_id = protocol.total_lotteries;
        protocol.total_lotteries = protocol.total_lotteries + 1;

        let owner = tx_context::sender(ctx);
        
        // Calculate initial payout (95% of maximum possible proceeds)
        let max_proceeds = wonkabar_price * max_supply;
        let initial_payout = (max_proceeds * (BASIS_POINTS - PROTOCOL_FEE_BPS)) / BASIS_POINTS;

        // Create lottery object
        let lottery = Lottery {
            id: object::new(ctx),
            lottery_id,
            owner,
            state: LOTTERY_ACTIVE,
            expiration_date,
            wonkabar_price,
            max_supply,
            sold_count: 0,
            winner: option::none(),
            winning_ticket: 0,
            funds: balance::zero<SUI>(),
            participants: table::new(ctx),
            participant_list: vector::empty(),
            ticket_ranges: table::new(ctx),
            total_ticket_numbers: 0,
        };

        // Store NFT in the lottery
        dof::add(&mut lottery.id, b"collateral", nft);

        // Create receipt
        let receipt = LotteryReceipt {
            id: object::new(ctx),
            lottery_id,
            owner,
        };

        // Add to active lotteries
        vector::push_back(&mut protocol.active_lotteries, object::id(&lottery));

        // Emit event
        event::emit(LotteryCreated {
            lottery_id,
            owner,
            expiration_date,
            wonkabar_price,
            max_supply,
            initial_payout,
        });

        transfer::share_object(lottery);
        receipt
    }

    /// Buy WonkaBars (lottery tickets)
    public fun buy_wonkabars(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        payment: Coin<SUI>,
        quantity: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): WonkaBars {
        assert!(!protocol.paused, EInvalidLotteryState);
        assert!(lottery.state == LOTTERY_ACTIVE, EInvalidLotteryState);
        assert!(clock::timestamp_ms(clock) < lottery.expiration_date, ELotteryExpired);
        assert!(quantity > 0, EInvalidAmount);
        assert!(lottery.sold_count + quantity <= lottery.max_supply, EMaxSupplyReached);

        let total_cost = lottery.wonkabar_price * quantity;
        assert!(coin::value(&payment) >= total_cost, EInsufficientPayment);
        
        let buyer = tx_context::sender(ctx);
        
        // Check user balance limits
        let current_balance = if (table::contains(&lottery.participants, buyer)) {
            *table::borrow(&lottery.participants, buyer)
        } else {
            0
        };
        let new_balance = current_balance + quantity;
        let max_allowed = (lottery.max_supply * MAX_BALANCE_PERCENTAGE) / BASIS_POINTS;
        assert!(new_balance <= max_allowed, EBalanceExceedsLimit);

        // Process payment - handle exact payment or return change
        let payment_balance = coin::into_balance(payment);
        let payment_amount = balance::value(&payment_balance);
        
        if (payment_amount > total_cost) {
            let change = balance::split(&mut payment_balance, payment_amount - total_cost);
            transfer::public_transfer(coin::from_balance(change, ctx), buyer);
        };
        
        balance::join(&mut lottery.funds, payment_balance);

        // Calculate ticket range for this purchase
        let ticket_start = lottery.total_ticket_numbers + 1;
        let ticket_end = lottery.total_ticket_numbers + quantity;

        // Update ticket range for user
        if (table::contains(&lottery.ticket_ranges, buyer)) {
            let existing_range = table::borrow_mut(&mut lottery.ticket_ranges, buyer);
            existing_range.end = ticket_end;
        } else {
            table::add(&mut lottery.ticket_ranges, buyer, TicketRange {
                start: ticket_start,
                end: ticket_end,
            });
            vector::push_back(&mut lottery.participant_list, buyer);
        };

        // Update lottery state
        lottery.sold_count = lottery.sold_count + quantity;
        lottery.total_ticket_numbers = lottery.total_ticket_numbers + quantity;
        
        if (table::contains(&lottery.participants, buyer)) {
            let balance_ref = table::borrow_mut(&mut lottery.participants, buyer);
            *balance_ref = *balance_ref + quantity;
        } else {
            table::add(&mut lottery.participants, buyer, quantity);
        };

        // Mint WonkaBars NFT
        let wonka_bars = wonka_bars::mint_with_tickets(
            lottery.lottery_id, 
            quantity, 
            buyer, 
            ticket_start, 
            ticket_end, 
            ctx
        );

        event::emit(WonkaBarsPurchased {
            lottery_id: lottery.lottery_id,
            buyer,
            quantity,
            total_cost,
            ticket_range_start: ticket_start,
            ticket_range_end: ticket_end,
        });

        wonka_bars
    }

    /// Draw winner for lottery using proper randomness
    #[allow(lint(public_random))]
    public fun draw_winner(
        lottery: &mut Lottery,
        random: &Random,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(lottery.state == LOTTERY_ACTIVE, EInvalidLotteryState);
        assert!(clock::timestamp_ms(clock) >= lottery.expiration_date || 
                lottery.sold_count == lottery.max_supply, ELotteryNotExpired);
        assert!(lottery.sold_count > 0, ENoParticipants);

        // Generate random ticket number
        let mut generator = random::new_generator(random, ctx);
        let winning_ticket = random::generate_u64_in_range(&mut generator, 1, lottery.total_ticket_numbers);
        
        // Find winner based on ticket ranges
        let mut winner_address = @0x0;
        let mut i = 0;
        while (i < vector::length(&lottery.participant_list)) {
            let participant = *vector::borrow(&lottery.participant_list, i);
            let range = table::borrow(&lottery.ticket_ranges, participant);
            if (winning_ticket >= range.start && winning_ticket <= range.end) {
                winner_address = participant;
                break
            };
            i = i + 1;
        };

        assert!(winner_address != @0x0, EInvalidWinningTicket);

        // Update lottery state
        lottery.state = LOTTERY_CONCLUDED;
        lottery.winner = option::some(winner_address);
        lottery.winning_ticket = winning_ticket;

        event::emit(LotteryWinnerDrawn {
            lottery_id: lottery.lottery_id,
            winner: winner_address,
            winning_ticket,
            total_participants: vector::length(&lottery.participant_list),
        });
    }

    /// Redeem WonkaBars after lottery conclusion
    public fun redeem_wonkabars<T: key + store>(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        factory: &mut ChocolateFactory,
        wonka_bars: WonkaBars,
        ctx: &mut TxContext
    ): (Option<T>, Coin<SUI>, Coin<CHOCO_CHIP>) {
        assert!(lottery.state == LOTTERY_CONCLUDED, EInvalidLotteryState);
        assert!(wonka_bars::lottery_id(&wonka_bars) == lottery.lottery_id, ELotteryNotFound);

        let redeemer = tx_context::sender(ctx);
        let quantity = wonka_bars::quantity(&wonka_bars);
        
        // Burn the WonkaBars
        wonka_bars::burn(wonka_bars);

        let is_winner = option::is_some(&lottery.winner) && 
                       *option::borrow(&lottery.winner) == redeemer;

        if (is_winner) {
            // Winner gets the NFT
            let nft: T = dof::remove(&mut lottery.id, b"collateral");
            
            // Winner also gets ChocoChip rewards
            let choco_reward = quantity * CHOCOCHIPS_PER_SUI;
            let choco_coins = choco_chip::mint(factory, choco_reward, redeemer, ctx);

            event::emit(WonkaBarsRedeemed {
                lottery_id: lottery.lottery_id,
                redeemer,
                quantity,
                payout: 0,
                choco_reward,
            });

            (option::some(nft), coin::zero(ctx), choco_coins)
        } else {
            // Non-winners get proportional refund + ChocoChip rewards
            let total_funds = balance::value(&lottery.funds);
            let user_share = (quantity * total_funds) / lottery.sold_count;
            
            let refund_balance = balance::split(&mut lottery.funds, user_share);
            let refund_coin = coin::from_balance(refund_balance, ctx);

            // ChocoChip rewards for participation
            let choco_reward = quantity * CHOCOCHIPS_PER_SUI;
            let choco_coins = choco_chip::mint(factory, choco_reward, redeemer, ctx);

            event::emit(WonkaBarsRedeemed {
                lottery_id: lottery.lottery_id,
                redeemer,
                quantity,
                payout: user_share,
                choco_reward,
            });

            (option::none(), refund_coin, choco_coins)
        }
    }

    /// Repay loan to reclaim NFT (cancel lottery)
    public fun repay_loan<T: key + store>(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        receipt: LotteryReceipt,
        repayment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ): T {
        assert!(lottery.state == LOTTERY_ACTIVE, EInvalidLotteryState);
        assert!(receipt.lottery_id == lottery.lottery_id, ELotteryNotFound);
        assert!(receipt.owner == tx_context::sender(ctx), ENotAuthorized);

        // Calculate repayment amount needed
        let max_proceeds = lottery.wonkabar_price * lottery.max_supply;
        let initial_payout = (max_proceeds * (BASIS_POINTS - PROTOCOL_FEE_BPS)) / BASIS_POINTS;
        let protocol_fee = max_proceeds - initial_payout;
        
        let funds_to_refund = balance::value(&lottery.funds);
        let total_repayment_needed = initial_payout - funds_to_refund + protocol_fee;
        
        assert!(coin::value(&repayment) >= total_repayment_needed, EInsufficientPayment);

        // Process repayment
        let repayment_balance = coin::into_balance(repayment);
        if (balance::value(&repayment_balance) > total_repayment_needed) {
            let change = balance::split(&mut repayment_balance, balance::value(&repayment_balance) - total_repayment_needed);
            transfer::public_transfer(coin::from_balance(change, ctx), tx_context::sender(ctx));
        };

        // Add to protocol treasury
        balance::join(&mut protocol.treasury, repayment_balance);

        // Cancel lottery
        lottery.state = LOTTERY_CANCELLED;

        // Return funds to participants
        // Note: In production, this would need a more sophisticated refund mechanism
        
        // Reclaim NFT
        let nft: T = dof::remove(&mut lottery.id, b"collateral");

        // Destroy receipt
        let LotteryReceipt { id, lottery_id: _, owner: _ } = receipt;
        object::delete(id);

        event::emit(LotteryCancelled {
            lottery_id: lottery.lottery_id,
            reason: string::utf8(b"Owner repaid loan"),
        });

        nft
    }

    // ======== View Functions ========

    /// Get lottery details
    public fun lottery_details(lottery: &Lottery): (u64, address, u8, u64, u64, u64, u64, Option<address>) {
        (
            lottery.lottery_id,
            lottery.owner,
            lottery.state,
            lottery.expiration_date,
            lottery.wonkabar_price,
            lottery.max_supply,
            lottery.sold_count,
            lottery.winner
        )
    }

    /// Get protocol statistics
    public fun protocol_stats(protocol: &Protocol): (u64, u64, bool) {
        (
            protocol.total_lotteries,
            balance::value(&protocol.treasury),
            protocol.paused
        )
    }

    /// Get user participation in lottery
    public fun user_participation(lottery: &Lottery, user: address): u64 {
        if (table::contains(&lottery.participants, user)) {
            *table::borrow(&lottery.participants, user)
        } else {
            0
        }
    }

    /// Check if user is lottery winner
    public fun is_lottery_winner(lottery: &Lottery, user: address): bool {
        option::is_some(&lottery.winner) && *option::borrow(&lottery.winner) == user
    }

    /// Get receipt lottery ID
    public fun receipt_lottery_id(receipt: &LotteryReceipt): u64 {
        receipt.lottery_id
    }

    // ======== Admin Functions ========

    /// Pause/unpause protocol
    public fun set_protocol_pause(
        protocol: &mut Protocol,
        _admin_cap: &AdminCap,
        paused: bool
    ) {
        protocol.paused = paused;
        
        event::emit(ProtocolPaused {
            paused,
            admin: protocol.admin,
        });
    }

    // ======== Test Functions ========

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }

    #[test_only]
    public fun create_test_lottery<T: key + store>(
        protocol: &mut Protocol,
        nft: T,
        expiration_ms: u64,
        wonkabar_price: u64,
        max_supply: u64,
        ctx: &mut TxContext
    ): LotteryReceipt {
        use sui::clock;
        let clock = clock::create_for_testing(ctx);
        clock::set_for_testing(&mut clock, 1000);
        
        let receipt = create_lottery(
            protocol,
            nft,
            expiration_ms,
            wonkabar_price,
            max_supply,
            &clock,
            ctx
        );
        
        clock::destroy_for_testing(clock);
        receipt
    }
}

// ==================== choco_chip.move ====================

/// ChocoChip - Governance token for MeltyFi Protocol
module meltyfi::choco_chip {
    use std::string;
    use std::option;
    use std::vector;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::tx_context::{Self, TxContext};
    use sui::url;
    use sui::event;
    use sui::transfer;
    use sui::object;

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
            option::some(url::new_unsafe_from_bytes(b"https://meltyfi.nft/images/choco-chip.png")),
            ctx
        );

        let mut factory = ChocolateFactory {
            id: object::new(ctx),
            treasury_cap,
            total_supply: 0,
            authorized_minters: vector::empty(),
            max_supply: MAX_SUPPLY,
        };

        let admin = FactoryAdmin {
            id: object::new(ctx),
        };

        // Add the admin as an authorized minter initially
        let admin_address = tx_context::sender(ctx);
        vector::push_back(&mut factory.authorized_minters, admin_address);

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

    /// Mint ChocoChips and transfer to recipient
    public fun mint(
        factory: &mut ChocolateFactory,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ): Coin<CHOCO_CHIP> {
        let minter = tx_context::sender(ctx);
        assert!(vector::contains(&factory.authorized_minters, &minter), ENotAuthorized);
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

    /// Authorize a new minter
    public fun authorize_minter(
        factory: &mut ChocolateFactory,
        _admin: &FactoryAdmin,
        new_minter: address,
        ctx: &mut TxContext
    ) {
        assert!(!vector::contains(&factory.authorized_minters, &new_minter), EInvalidAmount);
        vector::push_back(&mut factory.authorized_minters, new_minter);

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
        let (found, index) = vector::index_of(&factory.authorized_minters, &minter_to_revoke);
        assert!(found, ENotAuthorized);
        vector::remove(&mut factory.authorized_minters, index);

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
        vector::contains(&factory.authorized_minters, &minter)
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

// ==================== wonka_bars.move ====================

/// WonkaBars - Lottery ticket NFTs for MeltyFi Protocol
module meltyfi::wonka_bars {
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::display;
    use sui::package;
    use sui::transfer;
    use sui::object;

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
        assert!(can_merge(wonka_bars1, &wonka_bars2), ELotteryMismatch);

        let kept_id = object::id(wonka_bars1);
        let merged_id = object::id(&wonka_bars2);
        let total_quantity = wonka_bars1.quantity + wonka_bars2.quantity;

        // Update the first WonkaBars
        wonka_bars1.quantity = total_quantity;
        wonka_bars1.ticket_end = wonka_bars2.ticket_end.max(wonka_bars1.ticket_end);
        wonka_bars1.ticket_start = wonka_bars2.ticket_start.min(wonka_bars1.ticket_start);
        wonka_bars1.name = create_name(wonka_bars1.lottery_id, total_quantity);

        event::emit(WonkaBarsMerged {
            kept_id,
            merged_id,
            lottery_id: wonka_bars1.lottery_id,
            total_quantity,
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

    /// Burn WonkaBars
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
            created_at: _ 
        } = wonka_bars;

        event::emit(WonkaBarsBurned {
            lottery_id,
            quantity,
            owner,
            ticket_start,
            ticket_end,
        });

        object::delete(id);
    }

    /// Transfer WonkaBars to new owner
    public fun transfer_wonka_bars(wonka_bars: &mut WonkaBars, new_owner: address) {
        let old_owner = wonka_bars.owner;
        wonka_bars.owner = new_owner;

        event::emit(WonkaBarsTransferred {
            id: object::id(wonka_bars),
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
    fun create_name(_lottery_id: u64, quantity: u64): String {
        if (quantity == 1) {
            string::utf8(b"WonkaBar Lottery Ticket")
        } else {
            string::utf8(b"WonkaBar Lottery Tickets")
        }
    }

    /// Create description based on lottery details
    fun create_description(_lottery_id: u64): String {
        string::utf8(b"MeltyFi WonkaBar lottery tickets - your golden ticket to win NFT collateral or get refunded with ChocoChip rewards!")
    }

    /// Create image URL based on lottery ID
    fun create_image_url(_lottery_id: u64): String {
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

// ==================== meltyfi.move ====================

/// MeltyFi - Main module exposing protocol functionality
module meltyfi::meltyfi {
    use meltyfi::meltyfi_core::{Self, Protocol, Lottery, AdminCap, LotteryReceipt};
    use meltyfi::choco_chip::{ChocolateFactory, FactoryAdmin, CHOCO_CHIP};
    use meltyfi::wonka_bars::WonkaBars;

    // ======== Protocol Functions ========
    
    /// Create a new lottery
    public fun create_lottery<T: key + store>(
        protocol: &mut Protocol,
        nft: T,
        expiration_date: u64,
        wonkabar_price: u64,
        max_supply: u64,
        clock: &sui::clock::Clock,
        ctx: &mut sui::tx_context::TxContext
    ): LotteryReceipt {
        meltyfi_core::create_lottery(
            protocol, nft, expiration_date, wonkabar_price, max_supply, clock, ctx
        )
    }

    /// Buy WonkaBars (lottery tickets)
    public fun buy_wonkabars(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        payment: sui::coin::Coin<sui::sui::SUI>,
        quantity: u64,
        clock: &sui::clock::Clock,
        ctx: &mut sui::tx_context::TxContext
    ): WonkaBars {
        meltyfi_core::buy_wonkabars(protocol, lottery, payment, quantity, clock, ctx)
    }

    /// Redeem WonkaBars after lottery conclusion
    public fun redeem_wonkabars<T: key + store>(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        factory: &mut ChocolateFactory,
        wonka_bars: WonkaBars,
        ctx: &mut sui::tx_context::TxContext
    ): (std::option::Option<T>, sui::coin::Coin<sui::sui::SUI>, sui::coin::Coin<CHOCO_CHIP>) {
        meltyfi_core::redeem_wonkabars(protocol, lottery, factory, wonka_bars, ctx)
    }

    /// Repay loan to reclaim NFT
    public fun repay_loan<T: key + store>(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        receipt: LotteryReceipt,
        repayment: sui::coin::Coin<sui::sui::SUI>,
        clock: &sui::clock::Clock,
        ctx: &mut sui::tx_context::TxContext
    ): T {
        meltyfi_core::repay_loan(protocol, lottery, receipt, repayment, clock, ctx)
    }

    /// Draw winner for lottery
    public fun draw_winner(
        lottery: &mut Lottery,
        random: &sui::random::Random,
        clock: &sui::clock::Clock,
        ctx: &mut sui::tx_context::TxContext
    ) {
        meltyfi_core::draw_winner(lottery, random, clock, ctx)
    }

    // ======== View Functions ========

    /// Get lottery details
    public fun lottery_details(lottery: &Lottery): (u64, address, u8, u64, u64, u64, u64, std::option::Option<address>) {
        meltyfi_core::lottery_details(lottery)
    }

    /// Get protocol statistics
    public fun protocol_stats(protocol: &Protocol): (u64, u64, bool) {
        meltyfi_core::protocol_stats(protocol)
    }

    /// Get user participation in lottery
    public fun user_participation(lottery: &Lottery, user: address): u64 {
        meltyfi_core::user_participation(lottery, user)
    }

    /// Check if user is lottery winner
    public fun is_lottery_winner(lottery: &Lottery, user: address): bool {
        meltyfi_core::is_lottery_winner(lottery, user)
    }

    // ======== ChocolateFactory Functions ========

    /// Mint ChocoChip tokens
    public fun mint_choco(
        factory: &mut ChocolateFactory,
        amount: u64,
        recipient: address,
        ctx: &mut sui::tx_context::TxContext
    ): sui::coin::Coin<CHOCO_CHIP> {
        choco_chip::mint(factory, amount, recipient, ctx)
    }

    /// Get ChocoChip total supply
    public fun choco_total_supply(factory: &ChocolateFactory): u64 {
        choco_chip::total_supply(factory)
    }

    /// Check if address is authorized minter
    public fun is_authorized_minter(factory: &ChocolateFactory, minter: address): bool {
        choco_chip::is_authorized_minter(factory, minter)
    }

    // ======== WonkaBars Functions ========

    /// Mint WonkaBars
    public fun mint_wonka_bars(
        lottery_id: u64,
        quantity: u64,
        owner: address,
        ctx: &mut sui::tx_context::TxContext
    ): WonkaBars {
        wonka_bars::mint(lottery_id, quantity, owner, ctx)
    }

    /// Burn WonkaBars
    public fun burn_wonka_bars(wonka_bars: WonkaBars) {
        wonka_bars::burn(wonka_bars)
    }

    /// Get WonkaBars quantity
    public fun wonka_bars_quantity(wonka_bars: &WonkaBars): u64 {
        wonka_bars::quantity(wonka_bars)
    }

    /// Get WonkaBars lottery ID
    public fun wonka_bars_lottery_id(wonka_bars: &WonkaBars): u64 {
        wonka_bars::lottery_id(wonka_bars)
    }

    // ======== Admin Functions ========

    /// Pause or unpause the protocol
    public fun set_protocol_pause(
        protocol: &mut Protocol,
        admin_cap: &AdminCap,
        paused: bool
    ) {
        meltyfi_core::set_protocol_pause(protocol, admin_cap, paused)
    }

    /// Check if address is protocol admin
    public fun is_protocol_admin(_protocol: &Protocol, _address: address): bool {
        // This would need to be implemented based on your admin logic
        false
    }

    // ======== Convenience Functions ========
    
    /// Create a lottery and return both receipt and lottery ID
    public fun create_lottery_with_id<T: key + store>(
        protocol: &mut Protocol,
        nft: T,
        expiration_date: u64,
        wonkabar_price: u64,
        max_supply: u64,
        clock: &sui::clock::Clock,
        ctx: &mut sui::tx_context::TxContext
    ): (LotteryReceipt, u64) {
        let receipt = meltyfi_core::create_lottery(
            protocol, nft, expiration_date, wonkabar_price, max_supply, clock, ctx
        );
        let lottery_id = meltyfi_core::receipt_lottery_id(&receipt);
        (receipt, lottery_id)
    }
    
    /// Get user's total WonkaBars across all lotteries
    public fun get_user_total_wonka_bars(lotteries: &vector<Lottery>, user: address): u64 {
        let mut total = 0;
        let mut i = 0;
        while (i < vector::length(lotteries)) {
            let lottery = vector::borrow(lotteries, i);
            total = total + meltyfi_core::user_participation(lottery, user);
            i = i + 1;
        };
        total
    }
}