/// MeltyFiProtocol - Core protocol for NFT-collateralized lending through lottery mechanics
/// Reimplementation of the original Solidity protocol using Move on Sui
module meltyfi::meltyfi_core {
    use std::string::{Self, String};
    use std::vector;
    use std::option::{Self, Option};
    
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table};
    use sui::dynamic_field as df;
    use sui::dynamic_object_field as dof;
    use sui::random::{Self, Random};
    use sui::address;
    
    use meltyfi::choco_chip::{Self, ChocoChip};
    use meltyfi::wonka_bars::{Self, WonkaBars};

    // ======== Error Codes ========
    
    const ENotAuthorized: u64 = 1;
    const ELotteryNotFound: u64 = 2;
    const EInvalidLotteryState: u64 = 3;
    const EInsufficientPayment: u64 = 4;
    const ELotteryExpired: u64 = 5;
    const ELotteryNotExpired: u64 = 6;
    const EInvalidAmount: u64 = 7;
    const EMaxSupplyReached: u64 = 8;
    const EInvalidWinnerSelection: u64 = 9;
    const EBalanceExceedsLimit: u64 = 10;

    // ======== Constants ========
    
    /// Protocol fee percentage (5%)
    const PROTOCOL_FEE_BPS: u64 = 500;
    const BASIS_POINTS: u64 = 10000;
    
    /// Upper limits for lottery parameters
    const MAX_WONKABAR_SUPPLY: u64 = 10000;
    const MAX_BALANCE_PERCENTAGE: u64 = 2000; // 20%
    
    /// ChocoChip rewards per ETH equivalent (in SUI)
    const CHOCOCHIPS_PER_SUI: u64 = 100;

    // ======== Types ========

    /// Lottery state enumeration
    const LOTTERY_ACTIVE: u8 = 0;
    const LOTTERY_CANCELLED: u8 = 1;
    const LOTTERY_CONCLUDED: u8 = 2;
    const LOTTERY_TRASHED: u8 = 3;

    /// Core protocol state - shared object
    public struct Protocol has key {
        id: UID,
        /// Total number of lotteries created
        total_lotteries: u64,
        /// Protocol treasury for collecting fees
        treasury: Balance<SUI>,
        /// Active lottery IDs
        active_lotteries: vector<ID>,
        /// Protocol admin capability
        admin_cap: ID,
    }

    /// Individual lottery object
    public struct Lottery has key, store {
        id: UID,
        /// Unique lottery identifier
        lottery_id: u64,
        /// Lottery owner (borrower)
        owner: address,
        /// NFT being used as collateral (stored as dynamic object field)
        /// State of the lottery
        state: u8,
        /// Expiration timestamp (milliseconds)
        expiration_date: u64,
        /// Price per WonkaBar in SUI
        wonkabar_price: u64,
        /// Maximum WonkaBars that can be minted
        max_supply: u64,
        /// Current number of WonkaBars sold
        sold_count: u64,
        /// Winner address (if concluded)
        winner: Option<address>,
        /// Funds collected from WonkaBar sales
        funds: Balance<SUI>,
        /// Table tracking WonkaBar holders and their balances
        participants: Table<address, u64>,
    }

    /// NFT wrapper for collateral storage
    public struct CollateralNFT<T: key + store> has key, store {
        id: UID,
        nft: T,
        lottery_id: u64,
    }

    /// Admin capability for protocol management
    public struct AdminCap has key, store {
        id: UID,
    }

    /// Lottery creation receipt
    public struct LotteryReceipt has key, store {
        id: UID,
        lottery_id: u64,
        owner: address,
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

    public struct LotteryRepaid has copy, drop {
        lottery_id: u64,
        owner: address,
        refund_amount: u64,
    }

    public struct LotteryDrawn has copy, drop {
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

    // ======== Initialization ========

    /// Initialize the MeltyFi protocol
    fun init(ctx: &mut TxContext) {
        let admin_cap = AdminCap {
            id: object::new(ctx),
        };
        
        let admin_cap_id = object::id(&admin_cap);
        
        let protocol = Protocol {
            id: object::new(ctx),
            total_lotteries: 0,
            treasury: balance::zero<SUI>(),
            active_lotteries: vector::empty(),
            admin_cap: admin_cap_id,
        };

        transfer::share_object(protocol);
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    // ======== Public Functions ========

    /// Create a new lottery with NFT as collateral
    public fun create_lottery<T: key + store>(
        protocol: &mut Protocol,
        nft: T,
        expiration_date: u64,
        wonkabar_price: u64,
        max_supply: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): LotteryReceipt {
        // Validate parameters
        assert!(expiration_date > clock::timestamp_ms(clock), ELotteryExpired);
        assert!(wonkabar_price > 0, EInvalidAmount);
        assert!(max_supply > 0 && max_supply <= MAX_WONKABAR_SUPPLY, EInvalidAmount);

        let lottery_id = protocol.total_lotteries;
        protocol.total_lotteries = protocol.total_lotteries + 1;

        let lottery_uid = object::new(ctx);
        let lottery_id_obj = object::uid_to_inner(&lottery_uid);

        // Create collateral wrapper
        let collateral = CollateralNFT {
            id: object::new(ctx),
            nft,
            lottery_id,
        };

        let lottery = Lottery {
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
        };

        // Store NFT as dynamic object field
        dof::add(&mut lottery.id, b"collateral", collateral);
        
        // Add to active lotteries
        vector::push_back(&mut protocol.active_lotteries, lottery_id_obj);

        // Share the lottery object
        transfer::share_object(lottery);

        // Emit event
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
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        payment: Coin<SUI>,
        quantity: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): WonkaBars {
        // Validate lottery state and timing
        assert!(lottery.state == LOTTERY_ACTIVE, EInvalidLotteryState);
        assert!(clock::timestamp_ms(clock) < lottery.expiration_date, ELotteryExpired);
        
        // Check supply limits
        assert!(lottery.sold_count + quantity <= lottery.max_supply, EMaxSupplyReached);
        
        // Validate payment amount
        let total_cost = lottery.wonkabar_price * quantity;
        assert!(coin::value(&payment) >= total_cost, EInsufficientPayment);
        
        let buyer = tx_context::sender(ctx);
        
        // Check buyer's balance limit (max 20% of total supply)
        let current_balance = if (table::contains(&lottery.participants, buyer)) {
            *table::borrow(&lottery.participants, buyer)
        } else {
            0
        };
        let new_balance = current_balance + quantity;
        let max_allowed = (lottery.max_supply * MAX_BALANCE_PERCENTAGE) / BASIS_POINTS;
        assert!(new_balance <= max_allowed, EBalanceExceedsLimit);

        // Process payment
        let payment_balance = coin::into_balance(payment);
        let protocol_fee = (total_cost * PROTOCOL_FEE_BPS) / BASIS_POINTS;
        let owner_amount = total_cost - protocol_fee;

        // Split funds
        let fee_balance = balance::split(&mut payment_balance, protocol_fee);
        balance::join(&mut protocol.treasury, fee_balance);
        balance::join(&mut lottery.funds, payment_balance);

        // Update participant tracking
        if (table::contains(&lottery.participants, buyer)) {
            let existing_balance = table::borrow_mut(&mut lottery.participants, buyer);
            *existing_balance = *existing_balance + quantity;
        } else {
            table::add(&mut lottery.participants, buyer, quantity);
        };

        // Update sold count
        lottery.sold_count = lottery.sold_count + quantity;

        // Mint WonkaBars
        let wonka_bars = wonka_bars::mint(
            lottery.lottery_id,
            quantity,
            buyer,
            ctx
        );

        // Emit event
        event::emit(WonkaBarsPurchased {
            lottery_id: lottery.lottery_id,
            buyer,
            quantity,
            total_cost,
        });

        wonka_bars
    }

    /// Repay loan and cancel lottery (borrower)
    public fun repay_loan(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        receipt: LotteryReceipt,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Verify ownership
        assert!(receipt.owner == tx_context::sender(ctx), ENotAuthorized);
        assert!(lottery.lottery_id == receipt.lottery_id, ELotteryNotFound);
        assert!(lottery.state == LOTTERY_ACTIVE, EInvalidLotteryState);
        assert!(clock::timestamp_ms(clock) < lottery.expiration_date, ELotteryNotExpired);

        // Change state to cancelled
        lottery.state = LOTTERY_CANCELLED;

        // Calculate refund amount (funds collected from sales)
        let refund_amount = balance::value(&lottery.funds);

        // Remove from active lotteries
        remove_from_active_lotteries(protocol, object::id(lottery));

        // Emit event
        event::emit(LotteryRepaid {
            lottery_id: lottery.lottery_id,
            owner: lottery.owner,
            refund_amount,
        });

        // Destroy receipt
        let LotteryReceipt { id, lottery_id: _, owner: _ } = receipt;
        object::delete(id);
    }

    /// Draw winner for expired lottery using Sui's random
    public fun draw_winner(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        random: &Random,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Verify lottery is expired and active
        assert!(lottery.state == LOTTERY_ACTIVE, EInvalidLotteryState);
        assert!(clock::timestamp_ms(clock) >= lottery.expiration_date, ELotteryNotExpired);
        assert!(lottery.sold_count > 0, EInvalidWinnerSelection);

        // Generate random number for winner selection
        let mut generator = random::new_generator(random, ctx);
        let random_number = random::generate_u64(&mut generator);
        let winner_index = random_number % lottery.sold_count;

        // Find winner based on weighted random selection
        let winner = select_winner_by_index(lottery, winner_index);
        lottery.winner = option::some(winner);
        lottery.state = LOTTERY_CONCLUDED;

        // Remove from active lotteries
        remove_from_active_lotteries(protocol, object::id(lottery));

        // Emit event
        event::emit(LotteryDrawn {
            lottery_id: lottery.lottery_id,
            winner,
            total_participants: table::length(&lottery.participants),
        });
    }

    /// Redeem WonkaBars for rewards (cancelled/concluded lotteries)
    public fun redeem_wonkabars<T: key + store>(
        lottery: &mut Lottery,
        wonka_bars: WonkaBars,
        ctx: &mut TxContext
    ): (Option<T>, Coin<SUI>, ChocoChip) {
        let redeemer = tx_context::sender(ctx);
        let quantity = wonka_bars::quantity(&wonka_bars);
        
        // Verify WonkaBars belong to this lottery
        assert!(wonka_bars::lottery_id(&wonka_bars) == lottery.lottery_id, ELotteryNotFound);
        assert!(lottery.state != LOTTERY_ACTIVE, EInvalidLotteryState);

        // Calculate ChocoChip rewards
        let choco_reward_amount = quantity * CHOCOCHIPS_PER_SUI;
        let choco_chips = choco_chip::mint(choco_reward_amount, ctx);

        let (nft_option, sui_payout) = if (lottery.state == LOTTERY_CANCELLED) {
            // Cancelled: Full refund + ChocoChips
            let refund_amount = (quantity * lottery.wonkabar_price * (BASIS_POINTS - PROTOCOL_FEE_BPS)) / BASIS_POINTS;
            let payout_balance = balance::split(&mut lottery.funds, refund_amount);
            (option::none(), coin::from_balance(payout_balance, ctx))
        } else if (lottery.state == LOTTERY_CONCLUDED) {
            // Concluded: Winner gets NFT + ChocoChips, others get ChocoChips only
            if (option::contains(&lottery.winner, &redeemer)) {
                // Winner gets the NFT
                let collateral: CollateralNFT<T> = dof::remove(&mut lottery.id, b"collateral");
                let CollateralNFT { id, nft, lottery_id: _ } = collateral;
                object::delete(id);
                (option::some(nft), coin::zero(ctx))
            } else {
                // Non-winner gets only ChocoChips
                (option::none(), coin::zero(ctx))
            }
        } else {
            // Should not reach here
            abort EInvalidLotteryState
        };

        // Update participant tracking
        if (table::contains(&lottery.participants, redeemer)) {
            let balance_ref = table::borrow_mut(&mut lottery.participants, redeemer);
            *balance_ref = *balance_ref - quantity;
            if (*balance_ref == 0) {
                table::remove(&mut lottery.participants, redeemer);
            };
        };

        // Burn the WonkaBars
        wonka_bars::burn(wonka_bars);

        // Emit event
        event::emit(WonkaBarsRedeemed {
            lottery_id: lottery.lottery_id,
            redeemer,
            quantity,
            payout: coin::value(&sui_payout),
        });

        (nft_option, sui_payout, choco_chips)
    }

    // ======== View Functions ========

    /// Get lottery details
    public fun lottery_details(lottery: &Lottery): (
        u64,    // lottery_id
        address, // owner  
        u8,     // state
        u64,    // expiration_date
        u64,    // wonkabar_price
        u64,    // max_supply
        u64,    // sold_count
        Option<address>, // winner
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

    /// Get protocol statistics
    public fun protocol_stats(protocol: &Protocol): (u64, u64, u64) {
        (
            protocol.total_lotteries,
            balance::value(&protocol.treasury),
            vector::length(&protocol.active_lotteries)
        )
    }

    /// Check if user participates in lottery
    public fun user_participation(lottery: &Lottery, user: address): u64 {
        if (table::contains(&lottery.participants, user)) {
            *table::borrow(&lottery.participants, user)
        } else {
            0
        }
    }

    // ======== Admin Functions ========

    /// Withdraw protocol fees (admin only)
    public fun withdraw_treasury(
        protocol: &mut Protocol,
        _: &AdminCap,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<SUI> {
        let withdrawal = balance::split(&mut protocol.treasury, amount);
        coin::from_balance(withdrawal, ctx)
    }

    // ======== Internal Helper Functions ========

    /// Select winner by weighted index
    fun select_winner_by_index(lottery: &Lottery, target_index: u64): address {
        let mut current_index = 0;
        let mut i = 0;
        let participants_length = table::length(&lottery.participants);
        
        // This is a simplified approach - in production, you'd want a more efficient method
        // to iterate through participants and find the winner based on weighted selection
        let keys = table_keys(&lottery.participants);
        let mut selected_winner = *vector::borrow(&keys, 0); // fallback
        
        while (i < vector::length(&keys)) {
            let participant = *vector::borrow(&keys, i);
            let balance = *table::borrow(&lottery.participants, participant);
            if (current_index + balance > target_index) {
                selected_winner = participant;
                break
            };
            current_index = current_index + balance;
            i = i + 1;
        };
        
        selected_winner
    }

    /// Remove lottery from active list
    fun remove_from_active_lotteries(protocol: &mut Protocol, lottery_id: ID) {
        let (found, index) = vector::index_of(&protocol.active_lotteries, &lottery_id);
        if (found) {
            vector::remove(&mut protocol.active_lotteries, index);
        };
    }

    /// Helper to get table keys (simplified version)
    fun table_keys(participants: &Table<address, u64>): vector<address> {
        // Note: This is a placeholder. In a real implementation, you'd need to 
        // maintain a separate vector of keys or use a different data structure
        // that allows iteration. For now, this assumes we have access to keys.
        vector::empty<address>() // This would be replaced with actual implementation
    }

    // ======== Test Functions ========

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}