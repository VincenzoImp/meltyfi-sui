/// MeltyFi Protocol - Core lottery and NFT liquidity protocol
module meltyfi::core {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::event;
    use sui::clock::{Self, Clock};
    use sui::random::{Self, Random};
    use sui::dynamic_object_field as dof;
    use sui::vec_map::{Self, VecMap};
    use std::vector;
    use std::option::{Self, Option};
    use std::string::{Self, String};

    // ===== Constants =====
    const PROTOCOL_VERSION: u64 = 1;
    const PROTOCOL_FEE_BPS: u64 = 500; // 5%
    const BASIS_POINTS: u64 = 10000;
    const MIN_LOTTERY_DURATION: u64 = 86400000; // 24 hours in ms
    const MAX_LOTTERY_DURATION: u64 = 2592000000; // 30 days in ms
    const MAX_WONKA_SUPPLY: u64 = 10000;
    
    // ===== Lottery States =====
    const LOTTERY_ACTIVE: u8 = 0;
    const LOTTERY_CONCLUDED: u8 = 1;
    const LOTTERY_CANCELLED: u8 = 2;
    const LOTTERY_EXPIRED: u8 = 3;

    // ===== Error Codes =====
    const ENotAuthorized: u64 = 1;
    const EInvalidLotteryState: u64 = 2;
    const ELotteryExpired: u64 = 3;
    const EInvalidAmount: u64 = 4;
    const EInvalidQuantity: u64 = 5;
    const EMaxSupplyReached: u64 = 6;
    const EInsufficientPayment: u64 = 7;
    const ENotLotteryOwner: u64 = 9;
    const EInvalidDuration: u64 = 11;
    const EProtocolPaused: u64 = 12;

    // ===== Core Types =====

    /// One-time witness for package initialization
    public struct CORE has drop {}

    /// Main protocol state
    public struct Protocol has key {
        id: UID,
        version: u64,
        admin: address,
        total_lotteries: u64,
        active_lotteries: VecMap<u64, ID>,
        treasury: Balance<SUI>,
        paused: bool,
    }

    /// Admin capability
    public struct AdminCap has key, store {
        id: UID,
    }

    /// Individual lottery
    public struct Lottery has key {
        id: UID,
        lottery_id: u64,
        owner: address,
        state: u8,
        created_at: u64,
        expiration_date: u64,
        wonka_price: u64,
        max_supply: u64,
        sold_count: u64,
        total_raised: u64,
        winner: Option<address>,
        winning_ticket: u64,
        funds: Balance<SUI>,
        participants: VecMap<address, u64>, // address -> ticket count
    }

    /// Receipt for lottery creation (allows owner to manage lottery)
    public struct LotteryReceipt has key, store {
        id: UID,
        lottery_id: u64,
        owner: address,
    }

    /// WonkaBar NFT (lottery ticket)
    public struct WonkaBar has key, store {
        id: UID,
        lottery_id: u64,
        ticket_count: u64,
        owner: address,
        purchased_at: u64,
    }

    // ===== Events =====

    public struct LotteryCreated has copy, drop {
        lottery_id: u64,
        owner: address,
        nft_type: String,
        expiration_date: u64,
        wonka_price: u64,
        max_supply: u64,
        initial_payout: u64,
    }

    public struct WonkaBarsPurchased has copy, drop {
        lottery_id: u64,
        buyer: address,
        quantity: u64,
        total_cost: u64,
        total_sold: u64,
    }

    public struct LotteryResolved has copy, drop {
        lottery_id: u64,
        winner: Option<address>,
        winning_ticket: u64,
        total_participants: u64,
        total_raised: u64,
        state: u8,
    }

    public struct FundsWithdrawn has copy, drop {
        lottery_id: u64,
        recipient: address,
        amount: u64,
        withdrawal_type: String,
    }

    public struct ProtocolUpdated has copy, drop {
        admin: address,
        action: String,
        data: String,
    }

    // ===== Initialization =====

    fun init(_witness: CORE, ctx: &mut TxContext) {
        let admin = tx_context::sender(ctx);
        
        let protocol = Protocol {
            id: object::new(ctx),
            version: PROTOCOL_VERSION,
            admin,
            total_lotteries: 0,
            active_lotteries: vec_map::empty(),
            treasury: balance::zero<SUI>(),
            paused: false,
        };

        let admin_cap = AdminCap {
            id: object::new(ctx),
        };

        transfer::share_object(protocol);
        transfer::transfer(admin_cap, admin);

        event::emit(ProtocolUpdated {
            admin,
            action: string::utf8(b"protocol_initialized"),
            data: string::utf8(b"MeltyFi protocol deployed"),
        });
    }

    // ===== Public Functions =====

    /// Create a new lottery with NFT collateral
    public fun create_lottery<T: key + store>(
        protocol: &mut Protocol,
        nft: T,
        expiration_date: u64,
        wonka_price: u64,
        max_supply: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): LotteryReceipt {
        assert!(!protocol.paused, EProtocolPaused);
        let current_time = clock::timestamp_ms(clock);
        let duration = expiration_date - current_time;
        assert!(duration >= MIN_LOTTERY_DURATION && duration <= MAX_LOTTERY_DURATION, EInvalidDuration);
        assert!(wonka_price > 0, EInvalidAmount);
        assert!(max_supply > 0 && max_supply <= MAX_WONKA_SUPPLY, EInvalidAmount);

        let lottery_id = protocol.total_lotteries;
        protocol.total_lotteries = protocol.total_lotteries + 1;
        let owner = tx_context::sender(ctx);

        // Calculate and transfer initial payout (95% of potential earnings)
        let max_earnings = wonka_price * max_supply;
        let protocol_fee = (max_earnings * PROTOCOL_FEE_BPS) / BASIS_POINTS;
        let initial_payout = max_earnings - protocol_fee;

        let mut lottery = Lottery {
            id: object::new(ctx),
            lottery_id,
            owner,
            state: LOTTERY_ACTIVE,
            created_at: current_time,
            expiration_date,
            wonka_price,
            max_supply,
            sold_count: 0,
            total_raised: 0,
            winner: option::none(),
            winning_ticket: 0,
            funds: balance::zero<SUI>(),
            participants: vec_map::empty(),
        };

        // Store NFT as dynamic field
        dof::add(&mut lottery.id, b"nft", nft);
        let lottery_id_copy = object::uid_to_inner(&lottery.id);
        
        // Add to active lotteries
        vec_map::insert(&mut protocol.active_lotteries, lottery_id, lottery_id_copy);

        let receipt = LotteryReceipt {
            id: object::new(ctx),
            lottery_id,
            owner,
        };

        // Emit creation event
        event::emit(LotteryCreated {
            lottery_id,
            owner,
            nft_type: string::utf8(b"Generic NFT"),
            expiration_date,
            wonka_price,
            max_supply,
            initial_payout,
        });

        transfer::share_object(lottery);
        receipt
    }

    /// Purchase WonkaBars (lottery tickets)
    public fun buy_wonka_bars(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        payment: Coin<SUI>,
        quantity: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): WonkaBar {
        assert!(!protocol.paused, EProtocolPaused);
        assert!(lottery.state == LOTTERY_ACTIVE, EInvalidLotteryState);
        assert!(clock::timestamp_ms(clock) < lottery.expiration_date, ELotteryExpired);
        assert!(quantity > 0, EInvalidQuantity);
        assert!(lottery.sold_count + quantity <= lottery.max_supply, EMaxSupplyReached);

        let total_cost = lottery.wonka_price * quantity;
        let payment_amount = coin::value(&payment);
        assert!(payment_amount >= total_cost, EInsufficientPayment);

        let buyer = tx_context::sender(ctx);
        
        // Handle payment
        let mut payment_balance = coin::into_balance(payment);
        let cost_balance = balance::split(&mut payment_balance, total_cost);
        balance::join(&mut lottery.funds, cost_balance);
        
        // Return excess payment if any
        if (balance::value(&payment_balance) > 0) {
            transfer::public_transfer(coin::from_balance(payment_balance, ctx), buyer);
        } else {
            balance::destroy_zero(payment_balance);
        };

        // Update lottery state
        lottery.sold_count = lottery.sold_count + quantity;
        lottery.total_raised = lottery.total_raised + total_cost;
        
        // Update participant count
        if (vec_map::contains(&lottery.participants, &buyer)) {
            let current_count = *vec_map::get(&lottery.participants, &buyer);
            vec_map::remove(&mut lottery.participants, &buyer);
            vec_map::insert(&mut lottery.participants, buyer, current_count + quantity);
        } else {
            vec_map::insert(&mut lottery.participants, buyer, quantity);
        };

        // Create WonkaBar NFT
        let wonka_bar = WonkaBar {
            id: object::new(ctx),
            lottery_id: lottery.lottery_id,
            ticket_count: quantity,
            owner: buyer,
            purchased_at: clock::timestamp_ms(clock),
        };

        event::emit(WonkaBarsPurchased {
            lottery_id: lottery.lottery_id,
            buyer,
            quantity,
            total_cost,
            total_sold: lottery.sold_count,
        });

        wonka_bar
    }

    /// Resolve lottery (draw winner or cancel)
    #[allow(lint(public_random))]
    public fun resolve_lottery(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        random: &Random,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(!protocol.paused, EProtocolPaused);
        assert!(lottery.state == LOTTERY_ACTIVE, EInvalidLotteryState);
        

        let current_time = clock::timestamp_ms(clock);
        let mut final_state = LOTTERY_EXPIRED;
        let mut winner = option::none<address>();
        let mut winning_ticket = 0;

        // Check if lottery has expired or if it's concluded naturally
        if (current_time >= lottery.expiration_date || lottery.sold_count == lottery.max_supply) {
            let participants = &lottery.participants;
            let participant_addresses = vec_map::keys(participants);
            let participant_count = vector::length(&participant_addresses);
            if (participant_count > 0) {
                // Draw winner using Sui's randomness: pick a random participant
                let mut rng = random::new_generator(random, ctx);
                let winner_index = random::generate_u64_in_range(&mut rng, 0, participant_count);
                let winner_addr = *vector::borrow(&participant_addresses, winner_index);
                winner = option::some(winner_addr);
                final_state = LOTTERY_CONCLUDED;
                winning_ticket = winner_index; // Optionally store the index as the 'winning_ticket'
            };
        };

        lottery.state = final_state;
        lottery.winner = winner;
        lottery.winning_ticket = winning_ticket;

        // Remove from active lotteries
        vec_map::remove(&mut protocol.active_lotteries, &lottery.lottery_id);

        event::emit(LotteryResolved {
            lottery_id: lottery.lottery_id,
            winner,
            winning_ticket,
            total_participants: vec_map::length(&lottery.participants),
            total_raised: lottery.total_raised,
            state: final_state,
        });
    }

    /// Claim winnings (for winner) or refund (for participants if cancelled)
    public fun claim_rewards<T: key + store>(
        lottery: &mut Lottery,
        wonka_bar: WonkaBar,
        ctx: &mut TxContext
    ): Option<T> {
        assert!(lottery.state != LOTTERY_ACTIVE, EInvalidLotteryState);
        let claimer = tx_context::sender(ctx);
        assert!(wonka_bar.owner == claimer, ENotAuthorized);
        assert!(wonka_bar.lottery_id == lottery.lottery_id, EInvalidAmount);

        let WonkaBar { id, lottery_id: _, ticket_count, owner: _, purchased_at: _ } = wonka_bar;
        object::delete(id);

        let mut refund_amount = 0;

        if (lottery.state == LOTTERY_CONCLUDED) {
            // Check if claimer is the winner
            if (option::is_some(&lottery.winner) && *option::borrow(&lottery.winner) == claimer) {
                // Transfer NFT to winner
                if (dof::exists_(&lottery.id, b"nft")) {
                    let nft: T = dof::remove(&mut lottery.id, b"nft");
                    let nft_option = option::some(nft);
                    
                    event::emit(FundsWithdrawn {
                        lottery_id: lottery.lottery_id,
                        recipient: claimer,
                        amount: 0,
                        withdrawal_type: string::utf8(b"nft_claim"),
                    });
                    
                    return nft_option
                };
            };
            // Non-winners get ChocoChip rewards (handled by separate module)
        } else if (lottery.state == LOTTERY_CANCELLED || lottery.state == LOTTERY_EXPIRED) {
            // Calculate refund
            refund_amount = lottery.wonka_price * ticket_count;
            
            if (refund_amount > 0 && balance::value(&lottery.funds) >= refund_amount) {
                let refund_balance = balance::split(&mut lottery.funds, refund_amount);
                let refund_coin = coin::from_balance(refund_balance, ctx);
                transfer::public_transfer(refund_coin, claimer);
            };
        };

        event::emit(FundsWithdrawn {
            lottery_id: lottery.lottery_id,
            recipient: claimer,
            amount: refund_amount,
            withdrawal_type: string::utf8(b"refund"),
        });

        option::none<T>()
    }

    /// Cancel lottery (owner only, before expiration)
    public fun cancel_lottery(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        receipt: &LotteryReceipt,
        repayment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(!protocol.paused, EProtocolPaused);
        assert!(lottery.state == LOTTERY_ACTIVE, EInvalidLotteryState);
        assert!(receipt.lottery_id == lottery.lottery_id, EInvalidAmount);
        assert!(receipt.owner == tx_context::sender(ctx), ENotLotteryOwner);
        let sender = tx_context::sender(ctx);

        // Owner must repay the loan (total_raised) when cancelling before expiration.
        let payment_amount = coin::value(&repayment);
        assert!(payment_amount >= lottery.total_raised, EInsufficientPayment);

        let mut payment_balance = coin::into_balance(repayment);
        let repay_balance = balance::split(&mut payment_balance, lottery.total_raised);
        // Join the repayment into the lottery funds so participants can claim refunds
        balance::join(&mut lottery.funds, repay_balance);

        // Return any excess to sender
        if (balance::value(&payment_balance) > 0) {
            transfer::public_transfer(coin::from_balance(payment_balance, ctx), sender);
        } else {
            balance::destroy_zero(payment_balance);
        };
        

        lottery.state = LOTTERY_CANCELLED;

        // Remove from active lotteries
        vec_map::remove(&mut protocol.active_lotteries, &lottery.lottery_id);

        event::emit(LotteryResolved {
            lottery_id: lottery.lottery_id,
            winner: option::none(),
            winning_ticket: 0,
            total_participants: vec_map::length(&lottery.participants),
            total_raised: lottery.total_raised,
            state: LOTTERY_CANCELLED,
        });
    }

    // ===== Admin Functions =====

    /// Pause/unpause protocol
    public fun set_protocol_pause(
        protocol: &mut Protocol,
        _admin_cap: &AdminCap,
        paused: bool,
        ctx: &mut TxContext
    ) {
        protocol.paused = paused;
        
        event::emit(ProtocolUpdated {
            admin: tx_context::sender(ctx),
            action: string::utf8(b"pause_updated"),
            data: if (paused) { string::utf8(b"true") } else { string::utf8(b"false") },
        });
    }

    /// Withdraw protocol fees
    public fun withdraw_protocol_fees(
        protocol: &mut Protocol,
        _admin_cap: &AdminCap,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(balance::value(&protocol.treasury) >= amount, EInsufficientPayment);
        
        let fee_balance = balance::split(&mut protocol.treasury, amount);
        let fee_coin = coin::from_balance(fee_balance, ctx);
        transfer::public_transfer(fee_coin, tx_context::sender(ctx));

        event::emit(FundsWithdrawn {
            lottery_id: 0, // Protocol level withdrawal
            recipient: tx_context::sender(ctx),
            amount,
            withdrawal_type: string::utf8(b"protocol_fees"),
        });
    }

    // ===== View Functions =====

    /// Get protocol stats
    public fun get_protocol_stats(protocol: &Protocol): (u64, u64, u64, bool) {
        (
            protocol.version,
            protocol.total_lotteries,
            balance::value(&protocol.treasury),
            protocol.paused
        )
    }

    /// Get lottery details
    public fun get_lottery_info(lottery: &Lottery): (u64, address, u8, u64, u64, u64, u64, u64, Option<address>) {
        (
            lottery.lottery_id,
            lottery.owner,
            lottery.state,
            lottery.expiration_date,
            lottery.wonka_price,
            lottery.max_supply,
            lottery.sold_count,
            lottery.total_raised,
            lottery.winner
        )
    }

    /// Check if address is lottery participant
    public fun is_participant(lottery: &Lottery, participant: address): bool {
        vec_map::contains(&lottery.participants, &participant)
    }

    /// Get participant ticket count
    public fun get_participant_tickets(lottery: &Lottery, participant: address): u64 {
        if (vec_map::contains(&lottery.participants, &participant)) {
            *vec_map::get(&lottery.participants, &participant)
        } else {
            0
        }
    }

    /// Get WonkaBar info
    public fun get_wonka_bar_info(wonka_bar: &WonkaBar): (u64, u64, address, u64) {
        (
            wonka_bar.lottery_id,
            wonka_bar.ticket_count,
            wonka_bar.owner,
            wonka_bar.purchased_at
        )
    }

    // ===== Test Functions =====

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        let witness = CORE {};
        init(witness, ctx);
    }
}