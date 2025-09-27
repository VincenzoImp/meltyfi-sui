// src/constants/contracts.ts
export const MELTYFI_PACKAGE_ID = process.env.NEXT_PUBLIC_MELTYFI_PACKAGE_ID || '0x123'
export const PROTOCOL_OBJECT_ID = process.env.NEXT_PUBLIC_PROTOCOL_OBJECT_ID || '0x456'
export const CHOCOLATE_FACTORY_ID = process.env.NEXT_PUBLIC_CHOCOLATE_FACTORY_ID || '0x789'
export const CHOCO_CHIP_TYPE = process.env.NEXT_PUBLIC_CHOCO_CHIP_TYPE || `${MELTYFI_PACKAGE_ID}::choco_chip::CHOCO_CHIP`
export const WONKA_BARS_TYPE = process.env.NEXT_PUBLIC_WONKA_BARS_TYPE || `${MELTYFI_PACKAGE_ID}::wonka_bars::WonkaBars`

// Network configurations
export const NETWORK_CONFIG = {
    devnet: {
        rpcUrl: 'https://fullnode.devnet.sui.io:443',
        explorer: 'https://suiexplorer.com',
        faucet: 'https://faucet.devnet.sui.io',
    },
    testnet: {
        rpcUrl: 'https://fullnode.testnet.sui.io:443',
        explorer: 'https://suiexplorer.com',
        faucet: 'https://faucet.testnet.sui.io/gas',
    },
    mainnet: {
        rpcUrl: 'https://fullnode.mainnet.sui.io:443',
        explorer: 'https://suiexplorer.com',
        faucet: null,
    },
}

export const CURRENT_NETWORK = (process.env.NEXT_PUBLIC_SUI_NETWORK || 'devnet') as keyof typeof NETWORK_CONFIG
