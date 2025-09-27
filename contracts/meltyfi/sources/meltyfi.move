/// Main entry point and module organization for MeltyFi Protocol
module meltyfi::meltyfi {
    // Re-export commonly used functions for convenience
    use meltyfi::meltyfi_core::{Self, Protocol, Lottery, AdminCap, LotteryReceipt};
    use meltyfi::choco_chip::{Self, ChocolateFactory, FactoryAdmin, CHOCO_CHIP};
    use meltyfi::wonka_bars::{Self, WonkaBars};
    
    // Re-export key types for external modules
    public use fun meltyfi_core::create_lottery;
    public use fun meltyfi_core::buy_wonkabars;
    public use fun meltyfi_core::redeem_wonkabars;
    public use fun meltyfi_core::repay_loan;
    public use fun meltyfi_core::draw_winner;
    
    // Re-export view functions
    public use fun meltyfi_core::lottery_details;
    public use fun meltyfi_core::protocol_stats;
    public use fun meltyfi_core::user_participation;
    public use fun meltyfi_core::is_lottery_winner;
    
    // Re-export ChocoChip functions
    public use fun choco_chip::mint as mint_choco;
    public use fun choco_chip::total_supply as choco_total_supply;
    public use fun choco_chip::is_authorized_minter;
    
    // Re-export WonkaBars functions
    public use fun wonka_bars::mint as mint_wonka_bars;
    public use fun wonka_bars::burn as burn_wonka_bars;
    public use fun wonka_bars::quantity as wonka_bars_quantity;
    public use fun wonka_bars::lottery_id as wonka_bars_lottery_id;

    // ======== Protocol Constants ========
    
    /// Protocol version for compatibility checking
    const PROTOCOL_VERSION: u64 = 1;
    
    /// Protocol name for identification
    const PROTOCOL_NAME: vector<u8> = b"MeltyFi Protocol v1.0";

    // ======== Public Interface Functions ========
    
    /// Get protocol version
    public fun get_protocol_version(): u64 {
        PROTOCOL_VERSION
    }
    
    /// Get protocol name
    public fun get_protocol_name(): vector<u8> {
        PROTOCOL_NAME
    }
    
    /// Check if an address is a protocol admin
    public fun is_protocol_admin(protocol: &Protocol, address: address): bool {
        meltyfi_core::protocol_stats(protocol);
        // This is a placeholder - in reality, you'd check against the protocol admin
        false
    }
    
    /// Get protocol health status
    public fun get_protocol_health(protocol: &Protocol): (u64, u64, u64, bool) {
        meltyfi_core::protocol_stats(protocol)
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