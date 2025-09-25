#[test_only]
module meltyfi::test_helpers {
    use sui::test_scenario::{Self, Scenario};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    
    public fun init_test_helper(): (Scenario, Clock) {
        let scenario = test_scenario::begin(@0x1);
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        (scenario, clock)
    }
    
    public fun mint_sui_for_testing(scenario: &mut Scenario, recipient: address, amount: u64) {
        let coin = coin::mint_for_testing<SUI>(amount, test_scenario::ctx(scenario));
        transfer::public_transfer(coin, recipient);
    }
}
