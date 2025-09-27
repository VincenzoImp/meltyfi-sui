'use client';

import { createNetworkConfig, SuiClientProvider, WalletProvider } from '@mysten/dapp-kit';
import '@mysten/dapp-kit/dist/index.css';
import { getFullnodeUrl } from '@mysten/sui.js/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { useState } from 'react';

// Network configuration
const { networkConfig } = createNetworkConfig({
    testnet: { url: getFullnodeUrl('testnet') },
});

export function Providers({ children }: { children: React.ReactNode }) {
    const [queryClient] = useState(() => new QueryClient({
        defaultOptions: {
            queries: {
                staleTime: 60 * 1000, // 1 minute
                cacheTime: 10 * 60 * 1000, // 10 minutes
                retry: 2,
            },
        },
    }));

    return (
        <QueryClientProvider client={queryClient}>
            <SuiClientProvider networks={networkConfig} defaultNetwork="testnet">
                <WalletProvider autoConnect>
                    {children}
                    <ReactQueryDevtools initialIsOpen={false} />
                </WalletProvider>
            </SuiClientProvider>
        </QueryClientProvider>
    );
}
