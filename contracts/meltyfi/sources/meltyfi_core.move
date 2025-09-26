/// MeltyFiProtocol - Core protocol for NFT-collateralized lending through lottery mechanics
module meltyfi::meltyfi_core {
    use std::string::{Self, String};
    use std::vector;
    use std::option;
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table};
    use sui::dynamic_object_field as dof;
    use sui::random::{Self, Random};
    
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
    const EInvalidWinner: u64 = 12;

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

    /// Main protocol object - now shared
    public struct Protocol has key {
        id: UID,
        admin: address,
        total_lotteries: u64,
        treasury: Balance<SUI>,
        active_lotteries: vector<ID>,
    }

    /// Admin capability
    public struct AdminCap has key, store {
        id: UID,
    }

    /// Lottery structure - shared object
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
        funds: Balance<SUI>,
        participants: Table<address, u64>,
        total_ticket_numbers: u64, // For proper winner selection
    }

    /// Receipt for lottery creation
    public struct LotteryReceipt has key, store {
        id: UID,
        lottery_id: u64,
        owner: address,
    }

    /// Wrapper for NFT collateral
    public struct CollateralNFT<T: key + store> has key, store {
        id: UID,
        nft: T,
        lottery_id: u64,
    }

    // ======== Events ========

    public struct LotteryCreated has copy, drop {
        lottery_id: u64,
        owner: address,
        expiration_date: u64,
        wonkabar_price: u64,
        max_supply: u64,
    }

    public struct WonkaBarsPurchased has copy, drop {
        lottery_id: u64,
        buyer: address,
        quantity: u64,
        total_cost: u64,
    }

    public struct LotteryWinnerDrawn has copy, drop {
        lottery_id: u64,
        winner: address,
        total_participants: u64,
    }

    public struct WonkaBarsRedeemed has copy, drop {
        lottery_id: u64,
        redeemer: address,
        quantity: u64,
        payout: u64,
    }

    public struct LotteryCancelled has copy, drop {
        lottery_id: u64,
        reason: String,
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
        assert!(expiration_date > clock::timestamp_ms(clock), ELotteryExpired);
        assert!(wonkabar_price > 0, EInvalidAmount);
        assert!(max_supply > 0 && max_supply <= MAX_WONKABAR_SUPPLY, EInvalidAmount);

        let lottery_id = protocol.total_lotteries;
        protocol.total_lotteries = protocol.total_lotteries + 1;

        let lottery_uid = object::new(ctx);
        let lottery_id_obj = object::uid_to_inner(&lottery_uid);

        let collateral = CollateralNFT {
            id: object::new(ctx),
            nft,
            lottery_id,
        };

        let mut lottery = Lottery {
            id: lottery_uid,
            lottery_id,
            owner: tx_context::sender(ctx),
            state: LOTTERY_ACTIVE,
            expiration_date,
            wonkabar_price,
            max_supply,
            sold_count: 0,
            winner: option::none(),
            funds: balance::zero<SUI>(),
            participants: table::new(ctx),
            total_ticket_numbers: 0,
        };

        dof::add(&mut lottery.id, b"collateral", collateral);
        vector::push_back(&mut protocol.active_lotteries, lottery_id_obj);
        transfer::share_object(lottery);

        event::emit(LotteryCreated {
            lottery_id,
            owner: tx_context::sender(ctx),
            expiration_date,
            wonkabar_price,
            max_supply,
        });

        LotteryReceipt {
            id: object::new(ctx),
            lottery_id,
            owner: tx_context::sender(ctx),
        }
    }

    /// Purchase WonkaBars for a lottery
    public fun buy_wonkabars(
        _protocol: &mut Protocol,
        lottery: &mut Lottery,
        payment: Coin<SUI>,
        quantity: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): WonkaBars {
        assert!(lottery.state == LOTTERY_ACTIVE, EInvalidLotteryState);
        assert!(clock::timestamp_ms(clock) < lottery.expiration_date, ELotteryExpired);
        assert!(lottery.sold_count + quantity <= lottery.max_supply, EMaxSupplyReached);
        assert!(quantity > 0, EInvalidAmount);
        
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
        let wonka_bars = wonka_bars::mint(lottery.lottery_id, quantity, buyer, ctx);

        event::emit(WonkaBarsPurchased {
            lottery_id: lottery.lottery_id,
            buyer,
            quantity,
            total_cost,
        });

        wonka_bars
    }

    /// Draw winner for lottery using proper randomness
    public fun draw_winner(
        lottery: &mut Lottery,
        random: &Random,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(lottery.state == LOTTERY_ACTIVE, EInvalidLotteryState);
        assert!(clock::timestamp_ms(clock) >= lottery.expiration_date, ELotteryNotExpired);
        
        if (lottery.sold_count == 0) {
            lottery.state = LOTTERY_CANCELLED;
            event::emit(LotteryCancelled {
                lottery_id: lottery.lottery_id,
                reason: string::utf8(b"No participants")
            });
            return
        };

        // Proper random winner selection
        let mut generator = random::new_generator(random, ctx);
        let winning_ticket = random::generate_u64_in_range(&mut generator, 1, lottery.total_ticket_numbers + 1);
        
        // Find winner by iterating through participants
        let winner = find_winner_by_ticket(lottery, winning_ticket);
        
        lottery.state = LOTTERY_CONCLUDED;
        lottery.winner = option::some(winner);

        event::emit(LotteryWinnerDrawn {
            lottery_id: lottery.lottery_id,
            winner,
            total_participants: lottery.sold_count,
        });
    }

    /// Helper function to find winner by ticket number
    fun find_winner_by_ticket(lottery: &Lottery, winning_ticket: u64): address {
        // For now, return a dummy address - this should be implemented with proper ticket tracking
        // In a full implementation, we'd need to track ticket ranges per participant
        @0x1 // Placeholder - needs proper implementation
    }

    /// Redeem WonkaBars after lottery conclusion
    public fun redeem_wonkabars<T: key + store>(
        lottery: &mut Lottery,
        factory: &mut ChocolateFactory,
        wonka_bars: WonkaBars,
        ctx: &mut TxContext
    ): (option::Option<T>, Coin<SUI>, Coin<CHOCO_CHIP>) {
        let redeemer = tx_context::sender(ctx);
        let quantity = wonka_bars::quantity(&wonka_bars);
        
        assert!(wonka_bars::lottery_id(&wonka_bars) == lottery.lottery_id, ELotteryNotFound);
        assert!(lottery.state != LOTTERY_ACTIVE, EInvalidLotteryState);

        let choco_reward_amount = quantity * CHOCOCHIPS_PER_SUI;
        let choco_chips = choco_chip::mint(factory, choco_reward_amount, ctx);

        let (nft_option, sui_payout) = if (lottery.state == LOTTERY_CANCELLED) {
            // Refund case
            let refund_amount = (quantity * lottery.wonkabar_price * (BASIS_POINTS - PROTOCOL_FEE_BPS)) / BASIS_POINTS;
            let payout_balance = balance::split(&mut lottery.funds, refund_amount);
            (option::none(), coin::from_balance(payout_balance, ctx))
        } else if (lottery.state == LOTTERY_CONCLUDED) {
            // Winner case
            if (option::contains(&lottery.winner, &redeemer)) {
                let collateral: CollateralNFT<T> = dof::remove(&mut lottery.id, b"collateral");
                let CollateralNFT { id, nft, lottery_id: _ } = collateral;
                object::delete(id);
                (option::some(nft), coin::zero(ctx))
            } else {
                (option::none(), coin::zero(ctx))
            }
        } else {
            abort EInvalidLotteryState
        };

        // Update participant balance
        if (table::contains(&lottery.participants, redeemer)) {
            let balance_ref = table::borrow_mut(&mut lottery.participants, redeemer);
            assert!(*balance_ref >= quantity, EInsufficientPayment);
            *balance_ref = *balance_ref - quantity;
            if (*balance_ref == 0) {
                table::remove(&mut lottery.participants, redeemer);
            }
        };

        wonka_bars::burn(wonka_bars);

        event::emit(WonkaBarsRedeemed {
            lottery_id: lottery.lottery_id,
            redeemer,
            quantity,
            payout: coin::value(&sui_payout),
        });

        (nft_option, sui_payout, choco_chips)
    }

    /// Allow lottery owner to repay loan and reclaim NFT
    public fun repay_loan<T: key + store>(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ): T {
        let repayer = tx_context::sender(ctx);
        assert!(repayer == lottery.owner, ENotAuthorized);
        assert!(lottery.state == LOTTERY_ACTIVE, EInvalidLotteryState);
        
        let repayment_amount = lottery.sold_count * lottery.wonkabar_price;
        let with_interest = (repayment_amount * (BASIS_POINTS + PROTOCOL_FEE_BPS)) / BASIS_POINTS;
        
        assert!(coin::value(&payment) >= with_interest, EInsufficientPayment);
        
        // Take protocol fee
        let payment_balance = coin::into_balance(payment);
        let protocol_fee = balance::split(&mut payment_balance, with_interest - repayment_amount);
        balance::join(&mut protocol.treasury, protocol_fee);
        
        // Add repayment to lottery funds for participant refunds
        balance::join(&mut lottery.funds, payment_balance);
        
        // Mark lottery as cancelled (for refund purposes)
        lottery.state = LOTTERY_CANCELLED;
        
        // Return NFT to owner
        let collateral: CollateralNFT<T> = dof::remove(&mut lottery.id, b"collateral");
        let CollateralNFT { id, nft, lottery_id: _ } = collateral;
        object::delete(id);
        
        nft
    }

    // ======== View Functions ========

    public fun lottery_details(lottery: &Lottery): (
        u64, address, u8, u64, u64, u64, u64, Option<address>
    ) {
        (
            lottery.lottery_id,
            lottery.owner,
            lottery.state,
            lottery.expiration_date,
            lottery.wonkabar_price,
            lottery.max_supply,
            lottery.sold_count,
            lottery.winner,
        )
    }

    public fun protocol_stats(protocol: &Protocol): (u64, u64, u64) {
        (
            protocol.total_lotteries,
            balance::value(&protocol.treasury),
            vector::length(&protocol.active_lotteries)
        )
    }

    public fun user_participation(lottery: &Lottery, user: address): u64 {
        if (table::contains(&lottery.participants, user)) {
            *table::borrow(&lottery.participants, user)
        } else {
            0
        }
    }

    public fun receipt_lottery_id(receipt: &LotteryReceipt): u64 {
        receipt.lottery_id
    }

    // ======== Admin Functions ========

    public fun withdraw_treasury(
        protocol: &mut Protocol,
        _: &AdminCap,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<SUI> {
        let withdrawn_balance = balance::split(&mut protocol.treasury, amount);
        coin::from_balance(withdrawn_balance, ctx)
    }

    // ======== Test Functions ========
    
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }
}