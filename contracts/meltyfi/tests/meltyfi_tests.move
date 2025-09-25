#[test_only]
module meltyfi::meltyfi_tests {
    use std::vector;
    use sui::test_scenario::{Self, Scenario};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::test_utils;
    
    use meltyfi::meltyfi_core::{Self, Protocol, Lottery, AdminCap};
    use meltyfi::choco_chip::{Self, ChocolateFactory, FactoryAdmin};
    use meltyfi::wonka_bars::{Self, WonkaBars};

    const ADMIN: address = @0xAD;
    const USER1: address = @0xU1;
    const USER2: address = @0xU2;

    public struct TestNFT has key, store {
        id: sui::object::UID,
        name: vector<u8>,
    }

    #[test]
    fun test_create_lottery() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);

        // Initialize protocol
        meltyfi_core::init_for_testing(ctx);
        test_scenario::next_tx(&mut scenario, ADMIN);

        let mut protocol = test_scenario::take_shared<Protocol>(&scenario);
        let clock = clock::create_for_testing(ctx);
        
        // Create test NFT
        let nft = TestNFT {
            id: sui::object::new(ctx),
            name: b"Test NFT",
        };

        // Create lottery
        let receipt = meltyfi_core::create_lottery(
            &mut protocol,
            nft,
            1000000, // expiration
            100,     // price
            1000,    // max supply
            &clock,
            ctx
        );

        // Verify lottery creation
        assert!(meltyfi_core::receipt_lottery_id(&receipt) == 0, 0);
        
        sui::object::delete(receipt);
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(protocol);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_buy_wonkabars() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);

        // Setup
        meltyfi_core::init_for_testing(ctx);
        choco_chip::init_for_testing(ctx);
        test_scenario::next_tx(&mut scenario, ADMIN);

        let mut protocol = test_scenario::take_shared<Protocol>(&scenario);
        let clock = clock::create_for_testing(ctx);
        
        let nft = TestNFT {
            id: sui::object::new(ctx),
            name: b"Test NFT",
        };

        let receipt = meltyfi_core::create_lottery(
            &mut protocol,
            nft,
            1000000,
            100,
            1000,
            &clock,
            ctx
        );

        let lottery_id = meltyfi_core::receipt_lottery_id(&receipt);
        sui::object::delete(receipt);

        test_scenario::next_tx(&mut scenario, USER1);
        let mut lottery = test_scenario::take_shared<Lottery>(&scenario);
        
        // Buy WonkaBars
        let payment = coin::mint_for_testing<SUI>(500, test_scenario::ctx(&mut scenario));
        let wonka_bars = meltyfi_core::buy_wonkabars(
            &mut protocol,
            &mut lottery,
            payment,
            5, // quantity
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // Verify purchase
        assert!(wonka_bars::quantity(&wonka_bars) == 5, 0);
        assert!(wonka_bars::lottery_id(&wonka_bars) == lottery_id, 1);

        sui::object::delete(wonka_bars);
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(protocol);
        test_scenario::return_shared(lottery);
        test_scenario::end(scenario);
    }
}