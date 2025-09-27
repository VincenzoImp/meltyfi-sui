// ===== sources/meltyfi.move =====
/// MeltyFi Protocol - Main entry point module
module meltyfi::meltyfi {
    use meltyfi::core::{Self, Protocol, Lottery, LotteryReceipt, WonkaBar, AdminCap};
    use meltyfi::choco_chip::{Self, ChocolateFactory, FactoryAdmin, CHOCO_CHIP};
    
    // Re-export core functionality
    use fun core::create_lottery as create_lottery.
    use fun core::buy_wonka_bars as buy_wonka_bars.
    use fun core::resolve_lottery as resolve_lottery.
    use fun core::claim_rewards as claim_rewards.
    use fun core::cancel_lottery as cancel_lottery.
    use fun core::get_protocol_stats as get_protocol_stats.
    use fun core::get_lottery_info as get_lottery_info.
    use fun core::get_wonka_bar_info as get_wonka_bar_info.

    // Re-export ChocoChip functionality
    use fun choco_chip::mint as mint_choco_chips.
    use fun choco_chip::total_supply as choco_total_supply.
    use fun choco_chip::is_authorized_minter as is_choco_authorized_minter.
}