/// Main entry point and module organization for MeltyFi Protocol
module meltyfi::meltyfi {
    use meltyfi::meltyfi_core::{Protocol, Lottery, AdminCap, LotteryReceipt};
    use meltyfi::choco_chip::{ChocolateFactory, FactoryAdmin, CHOCO_CHIP};
    use meltyfi::wonka_bars::WonkaBars;

    // ======== Protocol Constants ========
    
    /// Protocol version for compatibility checking
    const PROTOCOL_VERSION: u64 = 1;
    
    /// Protocol name for identification
    const PROTOCOL_NAME: vector<u8> = b"MeltyFi Protocol v1.0";

    // ======== Core Protocol Functions ========
    
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
        meltyfi::meltyfi_core::create_lottery(
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
        meltyfi::meltyfi_core::buy_wonkabars(protocol, lottery, payment, quantity, clock, ctx)
    }

    /// Redeem WonkaBars after lottery conclusion
    public fun redeem_wonkabars<T: key + store>(
        protocol: &mut Protocol,
        lottery: &mut Lottery,
        factory: &mut ChocolateFactory,
        wonka_bars: WonkaBars,
        ctx: &mut sui::tx_context::TxContext
    ): (std::option::Option<T>, sui::coin::Coin<sui::sui::SUI>, sui::coin::Coin<CHOCO_CHIP>) {
        meltyfi::meltyfi_core::redeem_wonkabars(protocol, lottery, factory, wonka_bars, ctx)
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
        meltyfi::meltyfi_core::repay_loan(protocol, lottery, receipt, repayment, clock, ctx)
    }

    /// Draw winner for lottery
    public fun draw_winner(
        lottery: &mut Lottery,
        random: &sui::random::Random,
        clock: &sui::clock::Clock,
        ctx: &mut sui::tx_context::TxContext
    ) {
        meltyfi::meltyfi_core::draw_winner(lottery, random, clock, ctx)
    }

    // ======== View Functions ========

    /// Get lottery details
    public fun lottery_details(lottery: &Lottery): (u64, address, u8, u64, u64, u64, u64, std::option::Option<address>) {
        meltyfi::meltyfi_core::lottery_details(lottery)
    }

    /// Get protocol statistics
    public fun protocol_stats(protocol: &Protocol): (u64, u64, bool) {
        meltyfi::meltyfi_core::protocol_stats(protocol)
    }

    /// Get user participation in lottery
    public fun user_participation(lottery: &Lottery, user: address): u64 {
        meltyfi::meltyfi_core::user_participation(lottery, user)
    }

    /// Check if user is lottery winner
    public fun is_lottery_winner(lottery: &Lottery, user: address): bool {
        meltyfi::meltyfi_core::is_lottery_winner(lottery, user)
    }

    // ======== ChocolateFactory Functions ========

    /// Mint ChocoChip tokens
    public fun mint_choco(
        factory: &mut ChocolateFactory,
        amount: u64,
        recipient: address,
        ctx: &mut sui::tx_context::TxContext
    ): sui::coin::Coin<CHOCO_CHIP> {
        meltyfi::choco_chip::mint(factory, amount, recipient, ctx)
    }

    /// Get ChocoChip total supply
    public fun choco_total_supply(factory: &ChocolateFactory): u64 {
        meltyfi::choco_chip::total_supply(factory)
    }

    /// Check if address is authorized minter
    public fun is_authorized_minter(factory: &ChocolateFactory, minter: address): bool {
        meltyfi::choco_chip::is_authorized_minter(factory, minter)
    }

    // ======== WonkaBars Functions ========

    /// Mint WonkaBars
    public fun mint_wonka_bars(
        lottery_id: u64,
        quantity: u64,
        owner: address,
        ctx: &mut sui::tx_context::TxContext
    ): WonkaBars {
        meltyfi::wonka_bars::mint(lottery_id, quantity, owner, ctx)
    }

    /// Burn WonkaBars
    public fun burn_wonka_bars(wonka_bars: WonkaBars) {
        meltyfi::wonka_bars::burn(wonka_bars)
    }

    /// Get WonkaBars quantity
    public fun wonka_bars_quantity(wonka_bars: &WonkaBars): u64 {
        meltyfi::wonka_bars::quantity(wonka_bars)
    }

    /// Get WonkaBars lottery ID
    public fun wonka_bars_lottery_id(wonka_bars: &WonkaBars): u64 {
        meltyfi::wonka_bars::lottery_id(wonka_bars)
    }

    // ======== Utility Functions ========
    
    /// Get protocol version
    public fun get_protocol_version(): u64 {
        PROTOCOL_VERSION
    }
    
    /// Get protocol name
    public fun get_protocol_name(): vector<u8> {
        PROTOCOL_NAME
    }
    
    /// Check if an address is a protocol admin
    public fun is_protocol_admin(protocol: &Protocol, addr: address): bool {
        // This is a placeholder implementation
        // In reality, you'd check against stored admin addresses
        let (_, _, is_active) = meltyfi::meltyfi_core::protocol_stats(protocol);
        is_active && addr != @0x0
    }
}