'use client';

import { CURRENT_CONFIG, getExplorerUrl } from '@/constants/contracts';
import { shortenAddress } from '@/lib/utils';
import {
    ConnectButton,
    useCurrentAccount,
    useCurrentWallet,
    useSuiClient,
    useSuiClientQuery
} from '@mysten/dapp-kit';
import { CheckCircle, Copy, ExternalLink, Wallet } from 'lucide-react';
import { useState } from 'react';

export function WalletConnection() {
    const currentAccount = useCurrentAccount();
    const { currentWallet } = useCurrentWallet();
    const suiClient = useSuiClient();

    // Use useSuiClientQuery instead of useBalance
    const { data: balance } = useSuiClientQuery(
        'getBalance',
        {
            owner: currentAccount?.address || '',
        },
        {
            enabled: !!currentAccount?.address,
        }
    );

    const [copiedAddress, setCopiedAddress] = useState(false);

    const copyAddress = async () => {
        if (currentAccount?.address) {
            await navigator.clipboard.writeText(currentAccount.address);
            setCopiedAddress(true);
            setTimeout(() => setCopiedAddress(false), 2000);
        }
    };

    const formatBalance = (balance: string | undefined) => {
        if (!balance) return '0';
        const balanceNumber = parseFloat(balance) / 1_000_000_000;
        return balanceNumber.toFixed(4);
    };

    if (!currentAccount) {
        return (
            <div className="flex items-center gap-2">
                <ConnectButton />
            </div>
        );
    }

    return (
        <div className="flex items-center gap-4">
            {/* Balance Display */}
            <div className="hidden md:flex items-center gap-2 px-4 py-2 rounded-lg bg-white/5 border border-white/10">
                <Wallet className="w-4 h-4 text-purple-400" />
                <span className="text-sm font-medium text-white">
                    {formatBalance(balance?.totalBalance)} SUI
                </span>
            </div>

            {/* Wallet Info */}
            <div className="flex items-center gap-3 px-4 py-2 rounded-lg bg-white/5 border border-white/10">
                {currentWallet && (
                    <img
                        src={currentWallet.icon}
                        alt={currentWallet.name}
                        className="w-6 h-6 rounded-full"
                    />
                )}
                <div className="flex flex-col">
                    <span className="text-sm font-medium text-white">
                        {shortenAddress(currentAccount.address)}
                    </span>
                    <div className="flex items-center gap-1 text-xs text-white/60">
                        <CheckCircle className="w-3 h-3 text-green-400" />
                        <span>Connected</span>
                    </div>
                </div>

                {/* Copy Button */}
                <button
                    onClick={copyAddress}
                    className="p-2 hover:bg-white/10 rounded-lg transition-colors"
                >
                    {copiedAddress ? (
                        <CheckCircle className="w-4 h-4 text-green-400" />
                    ) : (
                        <Copy className="w-4 h-4 text-white/60" />
                    )}
                </button>

                {/* Explorer Link */}
                <a
                    href={getExplorerUrl(currentAccount.address, 'address')}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="p-2 hover:bg-white/10 rounded-lg transition-colors"
                >
                    <ExternalLink className="w-4 h-4 text-white/60" />
                </a>
            </div>

            {/* Network Status */}
            <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-purple-500/20 border border-purple-500/30">
                <div className="w-2 h-2 rounded-full bg-purple-400 animate-pulse" />
                <span className="text-xs font-medium text-purple-300">
                    {CURRENT_CONFIG.network}
                </span>
            </div>
        </div>
    );
}