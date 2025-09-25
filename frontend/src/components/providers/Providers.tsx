'use client';

import { SuiClientProvider, WalletProvider } from '@mysten/dapp-kit';
import { getFullnodeUrl } from '@mysten/sui/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from 'next-themes';
import { useState } from 'react';

// Import Sui wallet adapters
import '@mysten/dapp-kit/dist/index.css';

export function Providers({ children }: { children: React.ReactNode }) {
    const [queryClient] = useState(() => new QueryClient());

    const networks = {
        devnet: { url: getFullnodeUrl('devnet') },
        testnet: { url: getFullnodeUrl('testnet') },
        mainnet: { url: getFullnodeUrl('mainnet') },
    };

    return (
        <ThemeProvider
            attribute="class"
            defaultTheme="dark"
            enableSystem
        >
            <QueryClientProvider client={queryClient}>
                <SuiClientProvider networks={networks} defaultNetwork="devnet">
                    <WalletProvider autoConnect>
                        {children}
                    </WalletProvider>
                </SuiClientProvider>
            </QueryClientProvider>
        </ThemeProvider>
    );
}