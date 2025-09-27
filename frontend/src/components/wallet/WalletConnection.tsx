'use client';

import { CURRENT_CONFIG, getExplorerUrl } from '@/constants/contracts';
import { shortenAddress } from '@/lib/utils';
import {
    ConnectButton,
    useBalance,
    useCurrentAccount,
    useCurrentWallet,
    useSuiClient
} from '@mysten/dapp-kit';
import { AlertCircle, CheckCircle, Copy, ExternalLink, Wallet } from 'lucide-react';
import { useState } from 'react';

export function WalletConnection() {
    const currentAccount = useCurrentAccount();
    const { currentWallet } = useCurrentWallet();
    const suiClient = useSuiClient();
    const { data: balance } = useBalance({
        address: currentAccount?.address,
    });
    const [copiedAddress, setCopiedAddress] = useState(false);

    const copyAddress = async () => {
        if (currentAccount?.address) {
            await navigator.clipboard.writeText(currentAccount.address);
            setCopiedAddress(true);
            setTimeout(() => setCopiedAddress(false), 2000);
        }
    };

    const formatBalance = (balance: bigint | string | undefined) => {
        if (!balance) return '0';
        const balanceNumber = typeof balance === 'string' ? BigInt(balance) : balance;
        return (Number(balanceNumber) / 1_000_000_000).toFixed(4);
    };

    if (!currentAccount) {
        return (
            <div className="flex flex-col items-center gap-4">
                <ConnectButton
                    connectText="Connect Wallet"
                    className="bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-medium px-4 py-2 rounded-md transition-colors flex items-center justify-center"
                >
                    <Wallet className="w-4 h-4 mr-2" />
                    Connect Wallet
                </ConnectButton>

                {/* Testnet Warning */}
                <div className="flex items-center gap-2 px-3 py-2 bg-yellow-500/10 border border-yellow-500/20 rounded-lg">
                    <AlertCircle className="w-4 h-4 text-yellow-500" />
                    <span className="text-sm text-yellow-200">
                        Testnet Mode - Get free SUI from{' '}
                        <a
                            href={CURRENT_CONFIG.faucet}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="underline hover:text-yellow-100"
                        >
                            faucet
                        </a>
                    </span>
                </div>
            </div>
        );
    }

    return (
        <div className="flex items-center gap-4">
            {/* Wallet Info */}
            <div className="flex items-center gap-2 px-3 py-2 bg-white/5 backdrop-blur-sm rounded-lg border border-white/10">
                <Wallet className="w-4 h-4 text-white/70" />
                <div className="flex flex-col">
                    <div className="flex items-center gap-2">
                        <span className="text-sm font-medium text-white">
                            {shortenAddress(currentAccount.address)}
                        </span>
                        <button
                            onClick={copyAddress}
                            className="p-1 hover:bg-white/10 rounded text-white/60 hover:text-white transition-colors"
                        >
                            {copiedAddress ? (
                                <CheckCircle className="w-3 h-3 text-green-400" />
                            ) : (
                                <Copy className="w-3 h-3" />
                            )}
                        </button>
                    </div>
                    <span className="text-xs text-white/50">
                        {formatBalance(balance?.totalBalance)} SUI
                    </span>
                </div>
            </div>

            {/* Explorer Link */}
            <a
                href={getExplorerUrl('address', currentAccount.address)}
                target="_blank"
                rel="noopener noreferrer"
                className="p-2 hover:bg-white/10 rounded text-white/60 hover:text-white transition-colors"
                title="View on Explorer"
            >
                <ExternalLink className="w-4 h-4" />
            </a>

            {/* Wallet Controls */}
            <ConnectButton
                connectText="Switch Wallet"
                connectedText={currentWallet?.name || 'Connected'}
            />
        </div>
    );
}
