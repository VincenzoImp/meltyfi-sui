/// MeltyFi Protocol - Core protocol for NFT-collateralized lending through lottery mechanics
module meltyfi::meltyfi_core {
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
    const EInvalidQuantity: u64 = 14;

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
        winner: std::option::Option<address>,
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
        reason: std::string::String,
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
            active_lotteries: std::vector::empty(),
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

        // Calculate initial payout (95% of potential max earnings)
        let max_earnings = wonkabar_price * max_supply;
        let protocol_fee = (max_earnings * PROTOCOL_FEE_BPS) / BASIS_POINTS;
        let initial_payout = max_earnings - protocol_fee;

        let lottery = Lottery {
            id: object::new(ctx),
            lottery_id,
            owner: tx_context::sender(ctx),
            state: LOTTERY_ACTIVE,
            expiration_date,
            wonkabar_price,
            max_supply,
            sold_count: 0,
            winner: std::option::none(),
            winning_ticket: 0,
            funds: balance::zero<SUI>(),
            participants: table::new(ctx),
            participant_list: std::vector::empty(),
            ticket_ranges: table::new(ctx),
            total_ticket_numbers: 0,
        };

        // Store the NFT as a dynamic field
        dof::add(&mut lottery.id, b"nft", nft);

        let lottery_id_copy = lottery.lottery_id;
        let lottery_obj_id = object::id(&lottery);
        
        std::vector::push_back(&mut protocol.active_lotteries, lottery_obj_id);

        // Create receipt for the lottery owner
        let receipt = LotteryReceipt {
            id: object::new(ctx),
            lottery_id,
            owner: tx_context::sender(ctx),
        };

        event::emit(LotteryCreated {
            lottery_id,
            owner: tx_context::sender(ctx),
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
        assert!(quantity > 0, EInvalidQuantity);
        assert!(lottery.sold_count + quantity <= lottery.max_supply, EMaxSupplyReached);

        let total_cost = lottery.wonkabar_price * quantity;
        assert!(coin::value(&payment) >= total_cost, EInsufficientPayment);

        let buyer = tx_context::sender(ctx);
        
        // Handle payment
        let payment_balance = coin::into_balance(payment);
        let cost_balance = balance::split(&mut payment_balance, total_cost);
        balance::join(&mut lottery.funds, cost_balance);
        
        // Return excess payment if any
        if (balance::value(&payment_balance) > 0) {
            let excess_coin = coin::from_balance(payment_balance, ctx);
            transfer::public_transfer(excess_coin, buyer);
        } else {
            balance::destroy_zero(payment_balance);
        };

        // Update lottery state
        lottery.sold_count = lottery.sold_count + quantity;
        
        // Track participation
        if (table::contains(&lottery.participants, buyer)) {
            let current_count = table::remove(&mut lottery.participants, buyer);
            table::add(&mut lottery.participants, buyer, current_count + quantity);
        } else {
            table::add(&mut lottery.participants, buyer, quantity);
            std::vector::push_back(&mut lottery.participant_list, buyer);
        };

        // Assign ticket ranges
        let ticket_start = lottery.total_ticket_numbers;
        let ticket_end = ticket_start + quantity - 1;
        lottery.total_ticket_numbers = lottery.total_ticket_numbers + quantity;

        if (table::contains(&lottery.ticket_ranges, buyer)) {
            // For simplicity, we'll overwrite the range. In a full implementation,
            // you'd want to track multiple ranges per user
            table::remove(&mut lottery.ticket_ranges, buyer);
        };
        
        table::add(&mut lottery.ticket_ranges, buyer, TicketRange {
            start: ticket_start,
            end: ticket_end,
        });

        // Create WonkaBars NFT
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

    /// Draw winner for lottery using randomness
    public fun draw_winner(
        lottery: &mut Lottery,
        random: &Random,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(lottery.state == LOTTERY_ACTIVE, EInvalidLotteryState);
        assert!(clock::timestamp_ms(clock) >= lottery.expiration_date, ELotteryNotExpired);
        assert!(lottery.sold_count > 0, ENoParticipants);

        // Generate random winning ticket number
        let mut generator = random::new_generator(random, ctx);
        let winning_ticket = random::generate_u64_in_range(&mut generator, 0, lottery.total_ticket_numbers - 1);

        // Find winner by ticket number
        let mut winner_address = @0x0;
        let participant_count = std::vector::length(&lottery.participant_list);
        let mut i = 0;
        
        while (i < participant_count) {
            let participant = *std::vector::borrow(&lottery.participant_list, i);
            if (table::contains(&lottery.ticket_ranges, participant)) {
                let range = table::borrow(&lottery.ticket_ranges, participant);
                if (winning_ticket >= range.start && winning_ticket <= range.end) {
                    winner_address = participant;
                    break
                };
            };
            i = i + 1;
        };

        assert!(winner_address != @0x0, EInvalidWinningTicket);

        // Update lottery state
        lottery.state = LOTTERY_CONCLUDED;
        lottery.winner = std::option::some(winner_address);
        lottery.winning_ticket = winning_ticket;

        event::emit(LotteryWinnerDrawn {
            lottery_id: lottery.lottery_id,
            winner: winner_address,
            winning_ticket,
            total_participants: participant_count,
        });
    }

    /// Redeem WonkaBars after lottery conclusion
    public fun redeem_wonkabars<T: key + store>(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        factory: &mut ChocolateFactory,
        wonka_bars: WonkaBars,
        ctx: &mut TxContext
    ): (std::option::Option<T>, Coin<SUI>, Coin<CHOCO_CHIP>) {
        assert!(lottery.state == LOTTERY_CONCLUDED, EInvalidLotteryState);
        
        let redeemer = tx_context::sender(ctx);
        let quantity = wonka_bars::quantity(&wonka_bars);
        
        // Burn the WonkaBars
        wonka_bars::burn(wonka_bars);

        // Check if redeemer is the winner
        let is_winner = std::option::is_some(&lottery.winner) && 
                       *std::option::borrow(&lottery.winner) == redeemer;

        let nft_option = if (is_winner) {
            // Winner gets the NFT
            let nft: T = dof::remove(&mut lottery.id, b"nft");
            std::option::some(nft)
        } else {
            std::option::none()
        };

        // Calculate ChocoChip rewards
        let choco_reward_amount = quantity * CHOCOCHIPS_PER_SUI;
        
        // FIXED: Use correct parameters for mint function
        let choco_chips = choco_chip::mint(factory, choco_reward_amount, redeemer, ctx);

        // Calculate SUI refund for non-winners
        let sui_refund = if (!is_winner && lottery.sold_count > 0) {
            let total_funds = balance::value(&lottery.funds);
            let per_ticket_refund = total_funds / lottery.sold_count;
            let refund_amount = per_ticket_refund * quantity;
            
            if (refund_amount > 0 && balance::value(&lottery.funds) >= refund_amount) {
                let refund_balance = balance::split(&mut lottery.funds, refund_amount);
                coin::from_balance(refund_balance, ctx)
            } else {
                coin::zero(ctx)
            }
        } else {
            coin::zero(ctx)
        };

        event::emit(WonkaBarsRedeemed {
            lottery_id: lottery.lottery_id,
            redeemer,
            quantity,
            payout: coin::value(&sui_refund),
            choco_reward: choco_reward_amount,
        });

        (nft_option, sui_refund, choco_chips)
    }

    /// Repay loan to reclaim NFT before lottery conclusion
    public fun repay_loan<T: key + store>(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        receipt: LotteryReceipt,
        repayment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ): T {
        assert!(!protocol.paused, EInvalidLotteryState);
        assert!(lottery.state == LOTTERY_ACTIVE, EInvalidLotteryState);
        assert!(clock::timestamp_ms(clock) < lottery.expiration_date, ELotteryExpired);
        assert!(receipt.lottery_id == lottery.lottery_id, ELotteryNotFound);
        assert!(receipt.owner == tx_context::sender(ctx), ENotAuthorized);

        // Calculate repayment amount (total potential earnings)
        let total_repayment = lottery.wonkabar_price * lottery.max_supply;
        assert!(coin::value(&repayment) >= total_repayment, EInsufficientPayment);

        // Handle repayment
        let repayment_balance = coin::into_balance(repayment);
        let required_balance = balance::split(&mut repayment_balance, total_repayment);
        balance::join(&mut protocol.treasury, required_balance);

        // Return excess payment if any
        if (balance::value(&repayment_balance) > 0) {
            let excess_coin = coin::from_balance(repayment_balance, ctx);
            transfer::public_transfer(excess_coin, tx_context::sender(ctx));
        } else {
            balance::destroy_zero(repayment_balance);
        };

        // Cancel lottery and refund participants
        lottery.state = LOTTERY_CANCELLED;
        
        // Refund all participants
        let total_refund = balance::value(&lottery.funds);
        if (total_refund > 0) {
            let refund_balance = balance::split(&mut lottery.funds, total_refund);
            balance::join(&mut protocol.treasury, refund_balance);
        };

        // Remove NFT and return it
        let nft: T = dof::remove(&mut lottery.id, b"nft");

        // Clean up receipt
        let LotteryReceipt { id, lottery_id: _, owner: _ } = receipt;
        object::delete(id);

        event::emit(LotteryCancelled {
            lottery_id: lottery.lottery_id,
            reason: std::string::utf8(b"Loan repaid by owner"),
        });

        nft
    }

    // ======== View Functions ========

    /// Get lottery details
    public fun lottery_details(lottery: &Lottery): (u64, address, u8, u64, u64, u64, u64, std::option::Option<address>) {
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
        std::option::is_some(&lottery.winner) && 
        *std::option::borrow(&lottery.winner) == user
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
        paused: bool,
        ctx: &mut TxContext
    ) {
        protocol.paused = paused;
        
        event::emit(ProtocolPaused {
            paused,
            admin: tx_context::sender(ctx),
        });
    }

    /// Withdraw protocol treasury (admin only)
    public fun withdraw_treasury(
        protocol: &mut Protocol,
        _admin_cap: &AdminCap,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<SUI> {
        assert!(balance::value(&protocol.treasury) >= amount, EInsufficientPayment);
        let withdrawal_balance = balance::split(&mut protocol.treasury, amount);
        coin::from_balance(withdrawal_balance, ctx)
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
        expiration_date: u64,
        wonkabar_price: u64,
        max_supply: u64,
        ctx: &mut TxContext
    ): LotteryReceipt {
        let clock = clock::create_for_testing(ctx);
        clock::set_for_testing(&mut clock, expiration_date - 1000);
        
        let receipt = create_lottery(
            protocol,
            nft,
            expiration_date,
            wonkabar_price,
            max_supply,
            &clock,
            ctx
        );
        
        clock::destroy_for_testing(clock);
        receipt
    }
}