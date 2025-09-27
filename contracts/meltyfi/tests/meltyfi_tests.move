#[test_only]
module meltyfi::meltyfi_tests {
    use std::vector;
    use sui::test_scenario::{Self, Scenario};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::test_utils;
    use sui::random::{Self, Random};
    
    use meltyfi::meltyfi_core::{Self, Protocol, Lottery, AdminCap};
    use meltyfi::choco_chip::{Self, ChocolateFactory, FactoryAdmin};
    use meltyfi::wonka_bars::{Self, WonkaBars};

    const ADMIN: address = @0xAD;
    const USER1: address = @0xU1;
    const USER2: address = @0xU2;
    const USER3: address = @0xU3;

    // Test NFT for lottery creation
    public struct TestNFT has key, store {
        id: sui::object::UID,
        name: vector<u8>,
        value: u64,
    }

    // Helper function to create test NFT
    fun create_test_nft(ctx: &mut sui::tx_context::TxContext): TestNFT {
        TestNFT {
            id: sui::object::new(ctx),
            name: b"Test NFT",
            value: 1000,
        }
    }

    // Helper function to setup test environment
    fun setup_test_environment(): (Scenario, Clock, Random) {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);

        // Initialize all modules
        meltyfi_core::init_for_testing(ctx);
        choco_chip::init_for_testing(ctx);
        
        test_scenario::next_tx(&mut scenario, ADMIN);
        
        let clock = clock::create_for_testing(ctx);
        let random = random::create_for_testing(ctx);
        
        (scenario, clock, random)
    }

    #[test]
    fun test_protocol_initialization() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);

        meltyfi_core::init_for_testing(ctx);
        test_scenario::next_tx(&mut scenario, ADMIN);

        // Check that protocol was created
        assert!(test_scenario::has_most_recent_shared<Protocol>(), 0);
        
        let protocol = test_scenario::take_shared<Protocol>(&scenario);
        let (total_lotteries, treasury_balance, active_lotteries, paused) = meltyfi_core::protocol_stats(&protocol);
        
        assert!(total_lotteries == 0, 1);
        assert!(treasury_balance == 0, 2);
        assert!(active_lotteries == 0, 3);
        assert!(!paused, 4);

        test_scenario::return_shared(protocol);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_create_lottery() {
        let (mut scenario, clock, _random) = setup_test_environment();

        let mut protocol = test_scenario::take_shared<Protocol>(&scenario);
        
        // Create test NFT
        let nft = create_test_nft(test_scenario::ctx(&mut scenario));

        // Create lottery
        let expiration = clock::timestamp_ms(&clock) + 1000000; // 1000 seconds from now
        let receipt = meltyfi_core::create_lottery(
            &mut protocol,
            nft,
            expiration,
            100, // 100 MIST per WonkaBar
            1000, // max 1000 WonkaBars
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // Verify lottery creation
        assert!(meltyfi_core::receipt_lottery_id(&receipt) == 0, 0);
        
        let (total_lotteries, _treasury_balance, active_lotteries, _paused) = meltyfi_core::protocol_stats(&protocol);
        assert!(total_lotteries == 1, 1);
        assert!(active_lotteries == 1, 2);

        sui::object::delete(receipt);
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(protocol);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_buy_wonkabars() {
        let (mut scenario, clock, _random) = setup_test_environment();

        let mut protocol = test_scenario::take_shared<Protocol>(&scenario);
        
        // Create lottery first
        let nft = create_test_nft(test_scenario::ctx(&mut scenario));
        let expiration = clock::timestamp_ms(&clock) + 1000000;
        let receipt = meltyfi_core::create_lottery(
            &mut protocol,
            nft,
            expiration,
            100, // 100 MIST per WonkaBar
            1000,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        let lottery_id = meltyfi_core::receipt_lottery_id(&receipt);
        sui::object::delete(receipt);

        test_scenario::next_tx(&mut scenario, USER1);
        let mut lottery = test_scenario::take_shared<Lottery>(&scenario);
        
        // Buy WonkaBars
        let payment = coin::mint_for_testing<SUI>(500, test_scenario::ctx(&mut scenario)); // 500 MIST
        let wonka_bars = meltyfi_core::buy_wonkabars(
            &mut protocol,
            &mut lottery,
            payment,
            5, // buy 5 WonkaBars
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // Verify purchase
        assert!(wonka_bars::quantity(&wonka_bars) == 5, 0);
        assert!(wonka_bars::lottery_id(&wonka_bars) == lottery_id, 1);
        assert!(wonka_bars::owner(&wonka_bars) == USER1, 2);

        // Check user participation
        let user_participation = meltyfi_core::user_participation(&lottery, USER1);
        assert!(user_participation == 5, 3);

        // Check ticket range
        let (ticket_start, ticket_end) = meltyfi_core::user_ticket_range(&lottery, USER1);
        assert!(ticket_start == 1, 4);
        assert!(ticket_end == 5, 5);

        sui::object::delete(wonka_bars);
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(protocol);
        test_scenario::return_shared(lottery);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_multiple_users_buy_wonkabars() {
        let (mut scenario, clock, _random) = setup_test_environment();

        let mut protocol = test_scenario::take_shared<Protocol>(&scenario);
        
        // Create lottery
        let nft = create_test_nft(test_scenario::ctx(&mut scenario));
        let expiration = clock::timestamp_ms(&clock) + 1000000;
        let receipt = meltyfi_core::create_lottery(
            &mut protocol,
            nft,
            expiration,
            100,
            1000,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        sui::object::delete(receipt);
        test_scenario::next_tx(&mut scenario, USER1);
        let mut lottery = test_scenario::take_shared<Lottery>(&scenario);

        // USER1 buys 5 WonkaBars
        let payment1 = coin::mint_for_testing<SUI>(500, test_scenario::ctx(&mut scenario));
        let wonka_bars1 = meltyfi_core::buy_wonkabars(
            &mut protocol,
            &mut lottery,
            payment1,
            5,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // USER2 buys 3 WonkaBars
        test_scenario::next_tx(&mut scenario, USER2);
        let payment2 = coin::mint_for_testing<SUI>(300, test_scenario::ctx(&mut scenario));
        let wonka_bars2 = meltyfi_core::buy_wonkabars(
            &mut protocol,
            &mut lottery,
            payment2,
            3,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // Verify ticket ranges
        let (user1_start, user1_end) = meltyfi_core::user_ticket_range(&lottery, USER1);
        let (user2_start, user2_end) = meltyfi_core::user_ticket_range(&lottery, USER2);
        
        assert!(user1_start == 1 && user1_end == 5, 0);
        assert!(user2_start == 6 && user2_end == 8, 1);

        // Check lottery state
        let (lottery_id, _owner, state, _exp, _price, _max, sold_count, _winner) = meltyfi_core::lottery_details(&lottery);
        assert!(sold_count == 8, 2);
        assert!(state == 0, 3); // ACTIVE

        sui::object::delete(wonka_bars1);
        sui::object::delete(wonka_bars2);
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(protocol);
        test_scenario::return_shared(lottery);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_draw_winner() {
        let (mut scenario, clock, random) = setup_test_environment();

        let mut protocol = test_scenario::take_shared<Protocol>(&scenario);
        
        // Create lottery
        let nft = create_test_nft(test_scenario::ctx(&mut scenario));
        let expiration = clock::timestamp_ms(&clock) + 1000;
        let receipt = meltyfi_core::create_lottery(
            &mut protocol,
            nft,
            expiration,
            100,
            1000,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        sui::object::delete(receipt);
        test_scenario::next_tx(&mut scenario, USER1);
        let mut lottery = test_scenario::take_shared<Lottery>(&scenario);

        // Buy some WonkaBars
        let payment = coin::mint_for_testing<SUI>(500, test_scenario::ctx(&mut scenario));
        let wonka_bars = meltyfi_core::buy_wonkabars(
            &mut protocol,
            &mut lottery,
            payment,
            5,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // Advance time past expiration
        clock::increment_for_testing(&mut clock, 2000);

        // Draw winner
        meltyfi_core::draw_winner(
            &mut lottery,
            &random,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // Check lottery state
        let (_lottery_id, _owner, state, _exp, _price, _max, _sold_count, winner) = meltyfi_core::lottery_details(&lottery);
        assert!(state == 2, 0); // CONCLUDED
        assert!(std::option::is_some(&winner), 1);

        // Check if USER1 is the winner (should be since they're the only participant)
        assert!(meltyfi_core::is_lottery_winner(&lottery, USER1), 2);

        sui::object::delete(wonka_bars);
        clock::destroy_for_testing(clock);
        random::destroy_for_testing(random);
        test_scenario::return_shared(protocol);
        test_scenario::return_shared(lottery);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_repay_loan() {
        let (mut scenario, clock, _random) = setup_test_environment();

        let mut protocol = test_scenario::take_shared<Protocol>(&scenario);
        
        // Create lottery
        let nft = create_test_nft(test_scenario::ctx(&mut scenario));
        let expiration = clock::timestamp_ms(&clock) + 1000000;
        let receipt = meltyfi_core::create_lottery(
            &mut protocol,
            nft,
            expiration,
            100,
            1000,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        sui::object::delete(receipt);
        test_scenario::next_tx(&mut scenario, USER1);
        let mut lottery = test_scenario::take_shared<Lottery>(&scenario);

        // USER1 buys WonkaBars
        let payment = coin::mint_for_testing<SUI>(500, test_scenario::ctx(&mut scenario));
        let wonka_bars = meltyfi_core::buy_wonkabars(
            &mut protocol,
            &mut lottery,
            payment,
            5,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // Owner repays loan
        test_scenario::next_tx(&mut scenario, ADMIN);
        let repayment = coin::mint_for_testing<SUI>(525, test_scenario::ctx(&mut scenario)); // 500 + 5% fee
        let returned_nft: TestNFT = meltyfi_core::repay_loan(
            &mut protocol,
            &mut lottery,
            repayment,
            test_scenario::ctx(&mut scenario)
        );

        // Check lottery state
        let (_lottery_id, _owner, state, _exp, _price, _max, _sold_count, _winner) = meltyfi_core::lottery_details(&lottery);
        assert!(state == 1, 0); // CANCELLED

        // Verify NFT returned
        assert!(returned_nft.name == b"Test NFT", 1);

        sui::object::delete(wonka_bars);
        sui::object::delete(returned_nft);
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(protocol);
        test_scenario::return_shared(lottery);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_choco_chip_integration() {
        let (mut scenario, clock, _random) = setup_test_environment();

        // Take chocolate factory
        let mut factory = test_scenario::take_shared<ChocolateFactory>(&scenario);
        
        // Create lottery and buy WonkaBars
        let mut protocol = test_scenario::take_shared<Protocol>(&scenario);
        let nft = create_test_nft(test_scenario::ctx(&mut scenario));
        let expiration = clock::timestamp_ms(&clock) + 1000000;
        let receipt = meltyfi_core::create_lottery(
            &mut protocol,
            nft,
            expiration,
            100,
            1000,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        sui::object::delete(receipt);
        test_scenario::next_tx(&mut scenario, USER1);
        let mut lottery = test_scenario::take_shared<Lottery>(&scenario);

        let payment = coin::mint_for_testing<SUI>(500, test_scenario::ctx(&mut scenario));
        let wonka_bars = meltyfi_core::buy_wonkabars(
            &mut protocol,
            &mut lottery,
            payment,
            5,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // Cancel lottery to enable refunds
        test_scenario::next_tx(&mut scenario, ADMIN);
        let repayment = coin::mint_for_testing<SUI>(525, test_scenario::ctx(&mut scenario));
        let returned_nft: TestNFT = meltyfi_core::repay_loan(
            &mut protocol,
            &mut lottery,
            repayment,
            test_scenario::ctx(&mut scenario)
        );

        // Redeem WonkaBars for refund + ChocoChips
        test_scenario::next_tx(&mut scenario, USER1);
        let (nft_option, sui_payout, choco_chips) = meltyfi_core::redeem_wonkabars<TestNFT>(
            &mut lottery,
            &mut factory,
            wonka_bars,
            test_scenario::ctx(&mut scenario)
        );

        // Verify redemption
        assert!(std::option::is_none(&nft_option), 0); // No NFT for non-winner
        assert!(sui::coin::value(&sui_payout) > 0, 1); // Should get refund
        assert!(choco_chip::coin_value(&choco_chips) == 500, 2); // 5 * 100 ChocoChips

        std::option::destroy_none(nft_option);
        sui::object::delete(sui_payout);
        sui::object::delete(choco_chips);
        sui::object::delete(returned_nft);
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(protocol);
        test_scenario::return_shared(lottery);
        test_scenario::return_shared(factory);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_wonka_bars_operations() {
        let mut scenario = test_scenario::begin(USER1);
        let ctx = test_scenario::ctx(&mut scenario);

        // Create WonkaBars
        let mut wonka_bars1 = wonka_bars::create_with_tickets_for_testing(1, 5, USER1, 1, 5, ctx);
        let wonka_bars2 = wonka_bars::create_with_tickets_for_testing(1, 3, USER1, 6, 8, ctx);

        // Test split
        let split_bars = wonka_bars::split(&mut wonka_bars1, 2, ctx);
        assert!(wonka_bars::quantity(&wonka_bars1) == 3, 0);
        assert!(wonka_bars::quantity(&split_bars) == 2, 1);

        // Test merge
        wonka_bars::merge(&mut wonka_bars1, wonka_bars2);
        assert!(wonka_bars::quantity(&wonka_bars1) == 6, 2); // 3 + 3

        // Test ticket range functions
        let (start, end) = wonka_bars::ticket_range(&wonka_bars1);
        assert!(start <= end, 3);

        // Test contains ticket
        assert!(wonka_bars::contains_ticket(&split_bars, 4), 4); // Should be in range
        assert!(!wonka_bars::contains_ticket(&split_bars, 10), 5); // Should not be in range

        // Test transfer
        wonka_bars::transfer_wonka_bars(&mut wonka_bars1, USER2);
        assert!(wonka_bars::owner(&wonka_bars1) == USER2, 6);

        // Clean up
        wonka_bars::burn(wonka_bars1);
        wonka_bars::burn(split_bars);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = meltyfi_core::EInvalidAmount)]
    fun test_invalid_lottery_creation() {
        let (mut scenario, clock, _random) = setup_test_environment();

        let mut protocol = test_scenario::take_shared<Protocol>(&scenario);
        let nft = create_test_nft(test_scenario::ctx(&mut scenario));

        // Try to create lottery with invalid parameters
        let receipt = meltyfi_core::create_lottery(
            &mut protocol,
            nft,
            clock::timestamp_ms(&clock) + 1000000,
            0, // Invalid price (0)
            1000,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        sui::object::delete(receipt);
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(protocol);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = meltyfi_core::EInsufficientPayment)]
    fun test_insufficient_payment() {
        let (mut scenario, clock, _random) = setup_test_environment();

        let mut protocol = test_scenario::take_shared<Protocol>(&scenario);
        let nft = create_test_nft(test_scenario::ctx(&mut scenario));
        let receipt = meltyfi_core::create_lottery(
            &mut protocol,
            nft,
            clock::timestamp_ms(&clock) + 1000000,
            100,
            1000,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        sui::object::delete(receipt);
        test_scenario::next_tx(&mut scenario, USER1);
        let mut lottery = test_scenario::take_shared<Lottery>(&scenario);

        // Try to buy with insufficient payment
        let payment = coin::mint_for_testing<SUI>(50, test_scenario::ctx(&mut scenario)); // Only 50, need 100
        let wonka_bars = meltyfi_core::buy_wonkabars(
            &mut protocol,
            &mut lottery,
            payment,
            1,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        sui::object::delete(wonka_bars);
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(protocol);
        test_scenario::return_shared(lottery);
        test_scenario::end(scenario);
    }
}