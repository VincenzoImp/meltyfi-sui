'use client';

import { useMeltyFi } from '@/hooks/useMeltyFi';
import { useCurrentAccount, useSuiClient } from '@mysten/dapp-kit';
import {
    AlertCircle,
    CheckCircle,
    Coins,
    Image as ImageIcon,
    Upload
} from 'lucide-react';
import Image from 'next/image';
import { useEffect, useState } from 'react';

interface NFT {
    id: string;
    name: string;
    description: string;
    imageUrl: string;
    collection?: string;
    type: string;
}

export default function CreateLotteryPage() {
    const currentAccount = useCurrentAccount();
    const suiClient = useSuiClient();
    // Update the type for createLottery argument to include expirationDate
    const { createLottery, isCreatingLottery } = useMeltyFi();

    const [selectedNFT, setSelectedNFT] = useState<NFT | null>(null);
    const [userNFTs, setUserNFTs] = useState<NFT[]>([]);
    const [loadingNFTs, setLoadingNFTs] = useState(false);
    const [wonkaBarPrice, setWonkaBarPrice] = useState('0.1');
    const [maxSupply, setMaxSupply] = useState('100');
    const [duration, setDuration] = useState('7');
    const [showNFTSelector, setShowNFTSelector] = useState(false);

    // Load user's NFTs
    useEffect(() => {
        if (!currentAccount?.address) return;

        const loadUserNFTs = async () => {
            setLoadingNFTs(true);
            try {
                const objects = await suiClient.getOwnedObjects({
                    owner: currentAccount.address,
                    options: {
                        showContent: true,
                        showDisplay: true,
                        showType: true,
                    },
                    filter: {
                        MatchAny: [
                            { StructType: '0x2::nft::NFT' },
                            // Add other common NFT types
                        ]
                    }
                });

                const nfts: NFT[] = objects.data
                    .filter((obj) => {
                        // Remove explicit type annotation to let TypeScript infer
                        return obj.data?.display?.data || obj.data?.content;
                    })
                    .map((obj) => {
                        // Remove explicit type annotation here too
                        const display = obj.data?.display?.data;
                        const content = obj.data?.content;

                        return {
                            id: obj.data?.objectId || '',
                            name: display?.name || display?.title || `NFT ${obj.data?.objectId?.slice(-8)}`,
                            description: display?.description || 'No description available',
                            imageUrl: display?.image_url || display?.img_url || '/placeholder-nft.png',
                            collection: display?.collection || display?.project_name,
                            type: obj.data?.type || 'Unknown'
                        };
                    });

                setUserNFTs(nfts);
            } catch (error) {
                console.error('Error loading NFTs:', error);
            } finally {
                setLoadingNFTs(false);
            }
        };

        loadUserNFTs();
    }, [currentAccount?.address, suiClient]);

    const handleCreateLottery = async () => {
        if (!selectedNFT) return;

        try {
            const wonkaBarPriceMist = (parseFloat(wonkaBarPrice) * 1_000_000_000).toString();

            // Calculate absolute expiration timestamp
            const durationMs = parseInt(duration) * 24 * 60 * 60 * 1000;
            const expirationTimestamp = Date.now() + durationMs;

            await createLottery({
                nftId: selectedNFT.id,
                wonkaBarPrice: wonkaBarPriceMist,
                maxSupply,
                expirationDate: expirationTimestamp.toString() // Pass absolute timestamp as string
            });

            // Reset form
            setSelectedNFT(null);
            setWonkaBarPrice('0.1');
            setMaxSupply('100');
            setDuration('7');
        } catch (error) {
            console.error('Failed to create lottery:', error);
        }
    };
    const estimatedLiquidity = parseFloat(wonkaBarPrice) * parseInt(maxSupply) * 0.95; // 95% upfront
    const protocolFee = parseFloat(wonkaBarPrice) * parseInt(maxSupply) * 0.05; // 5% fee

    if (!currentAccount) {
        return (
            <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 flex items-center justify-center">
                <div className="rounded-lg border border-white/10 bg-white/5 backdrop-blur-sm p-12 text-center max-w-md">
                    <AlertCircle className="w-16 h-16 text-white/40 mx-auto mb-6" />
                    <h2 className="text-2xl font-bold text-white mb-4">Connect Your Wallet</h2>
                    <p className="text-white/60 mb-8">
                        Connect your Sui wallet to create lotteries and unlock liquidity from your NFTs.
                    </p>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900">
            <div className="container mx-auto px-6 py-12">
                <div className="max-w-2xl mx-auto">
                    {/* Header */}
                    <div className="text-center mb-12">
                        <h1 className="text-4xl font-bold text-white mb-4">Create Lottery</h1>
                        <p className="text-white/60 text-lg">
                            Turn your NFT into instant liquidity with our lottery system
                        </p>
                    </div>

                    {/* Main Form */}
                    <div className="rounded-lg border border-white/10 bg-white/5 backdrop-blur-sm p-8">
                        {/* Step 1: Select NFT */}
                        <div className="mb-8">
                            <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
                                <ImageIcon className="w-5 h-5" />
                                1. Select Your NFT
                            </h3>

                            {selectedNFT ? (
                                <div className="border border-white/20 rounded-lg p-4 bg-white/5">
                                    <div className="flex items-center gap-4">
                                        <div className="w-16 h-16 rounded-lg overflow-hidden bg-white/10">
                                            {selectedNFT.imageUrl !== '/placeholder-nft.png' ? (
                                                <Image
                                                    src={selectedNFT.imageUrl}
                                                    alt={selectedNFT.name}
                                                    width={64}
                                                    height={64}
                                                    className="w-full h-full object-cover"
                                                />
                                            ) : (
                                                <div className="w-full h-full flex items-center justify-center">
                                                    <ImageIcon className="w-6 h-6 text-white/40" />
                                                </div>
                                            )}
                                        </div>
                                        <div className="flex-1">
                                            <h4 className="font-medium text-white">{selectedNFT.name}</h4>
                                            {selectedNFT.collection && (
                                                <p className="text-sm text-white/60">{selectedNFT.collection}</p>
                                            )}
                                        </div>
                                        <button
                                            onClick={() => setShowNFTSelector(true)}
                                            className="text-purple-400 hover:text-purple-300 text-sm"
                                        >
                                            Change
                                        </button>
                                    </div>
                                </div>
                            ) : (
                                <button
                                    onClick={() => setShowNFTSelector(true)}
                                    className="w-full border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-purple-500/50 transition-colors"
                                >
                                    <Upload className="w-8 h-8 text-white/40 mx-auto mb-2" />
                                    <p className="text-white/60">Select an NFT from your wallet</p>
                                    <p className="text-sm text-white/40 mt-1">
                                        {loadingNFTs ? 'Loading your NFTs...' : `Found ${userNFTs.length} NFTs`}
                                    </p>
                                </button>
                            )}
                        </div>

                        {/* Step 2: Lottery Parameters */}
                        <div className="mb-8">
                            <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
                                <Coins className="w-5 h-5" />
                                2. Set Lottery Parameters
                            </h3>

                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                {/* WonkaBar Price */}
                                <div>
                                    <label className="block text-sm font-medium text-white/80 mb-2">
                                        WonkaBar Price (SUI)
                                    </label>
                                    <input
                                        type="number"
                                        step="0.001"
                                        min="0.001"
                                        value={wonkaBarPrice}
                                        onChange={(e) => setWonkaBarPrice(e.target.value)}
                                        className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-white focus:outline-none focus:border-purple-500"
                                    />
                                    <p className="text-xs text-white/60 mt-1">
                                        Minimum bid per lottery ticket
                                    </p>
                                </div>

                                {/* Max Supply */}
                                <div>
                                    <label className="block text-sm font-medium text-white/80 mb-2">
                                        Max WonkaBars
                                    </label>
                                    <input
                                        type="number"
                                        min="1"
                                        value={maxSupply}
                                        onChange={(e) => setMaxSupply(e.target.value)}
                                        className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-white focus:outline-none focus:border-purple-500"
                                    />
                                    <p className="text-xs text-white/60 mt-1">
                                        Total lottery tickets available
                                    </p>
                                </div>

                                {/* Duration */}
                                <div className="md:col-span-2">
                                    <label className="block text-sm font-medium text-white/80 mb-2">
                                        Lottery Duration (Days)
                                    </label>
                                    <input
                                        type="number"
                                        min="1"
                                        max="30"
                                        value={duration}
                                        onChange={(e) => setDuration(e.target.value)}
                                        className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-white focus:outline-none focus:border-purple-500"
                                    />
                                    <p className="text-xs text-white/60 mt-1">
                                        How long the lottery will run
                                    </p>
                                </div>
                            </div>
                        </div>

                        {/* Step 3: Summary */}
                        <div className="mb-8">
                            <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
                                <CheckCircle className="w-5 h-5" />
                                3. Lottery Summary
                            </h3>

                            <div className="bg-white/5 rounded-lg p-4 space-y-3">
                                <div className="flex justify-between">
                                    <span className="text-white/60">Potential Total Value:</span>
                                    <span className="text-white font-medium">
                                        {(parseFloat(wonkaBarPrice) * parseInt(maxSupply)).toFixed(3)} SUI
                                    </span>
                                </div>
                                <div className="flex justify-between">
                                    <span className="text-white/60">Instant Liquidity (95%):</span>
                                    <span className="text-green-400 font-medium">
                                        {estimatedLiquidity.toFixed(3)} SUI
                                    </span>
                                </div>
                                <div className="flex justify-between">
                                    <span className="text-white/60">Protocol Fee (5%):</span>
                                    <span className="text-white/60">
                                        {protocolFee.toFixed(3)} SUI
                                    </span>
                                </div>
                                <div className="border-t border-white/10 pt-3">
                                    <div className="flex justify-between">
                                        <span className="text-white/60">Lottery Duration:</span>
                                        <span className="text-white">{duration} days</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Create Button */}
                        <button
                            onClick={handleCreateLottery}
                            disabled={!selectedNFT || isCreatingLottery}
                            className="w-full bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 disabled:from-gray-600 disabled:to-gray-600 disabled:cursor-not-allowed text-white font-semibold py-3 px-6 rounded-lg transition-colors"
                        >
                            {isCreatingLottery ? 'Creating Lottery...' : 'Create Lottery'}
                        </button>

                        {/* Info Box */}
                        <div className="mt-6 bg-blue-500/10 border border-blue-500/20 rounded-lg p-4">
                            <div className="flex items-start gap-3">
                                <AlertCircle className="w-5 h-5 text-blue-400 mt-0.5" />
                                <div className="text-sm text-blue-200">
                                    <p className="font-medium mb-1">How it works:</p>
                                    <ul className="space-y-1 text-blue-200/80">
                                        <li>• Your NFT is held in escrow until lottery ends or you repay</li>
                                        <li>• You receive 95% of potential funds immediately</li>
                                        <li>• Participants buy WonkaBars and earn ChocoChips</li>
                                        <li>• You can repay anytime to reclaim your NFT</li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* NFT Selector Modal */}
            {showNFTSelector && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                    <div className="bg-gray-900 rounded-lg border border-white/10 max-w-4xl w-full max-h-[80vh] overflow-hidden">
                        <div className="p-6 border-b border-white/10">
                            <div className="flex items-center justify-between">
                                <h3 className="text-lg font-semibold text-white">Select Your NFT</h3>
                                <button
                                    onClick={() => setShowNFTSelector(false)}
                                    className="text-white/60 hover:text-white"
                                >
                                    ✕
                                </button>
                            </div>
                        </div>

                        <div className="p-6 overflow-y-auto max-h-[60vh]">
                            {loadingNFTs ? (
                                <div className="text-center py-12">
                                    <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-white"></div>
                                    <p className="text-white/60 mt-4">Loading your NFTs...</p>
                                </div>
                            ) : userNFTs.length === 0 ? (
                                <div className="text-center py-12">
                                    <ImageIcon className="w-16 h-16 text-white/40 mx-auto mb-4" />
                                    <h3 className="text-xl font-semibold text-white mb-2">No NFTs Found</h3>
                                    <p className="text-white/60">
                                        You don't have any NFTs in your wallet that can be used for lotteries.
                                    </p>
                                </div>
                            ) : (
                                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                                    {userNFTs.map((nft) => (
                                        <div
                                            key={nft.id}
                                            onClick={() => {
                                                setSelectedNFT(nft);
                                                setShowNFTSelector(false);
                                            }}
                                            className="border border-white/10 rounded-lg p-3 hover:bg-white/5 cursor-pointer transition-colors"
                                        >
                                            <div className="aspect-square rounded-lg overflow-hidden bg-white/10 mb-3">
                                                {nft.imageUrl !== '/placeholder-nft.png' ? (
                                                    <Image
                                                        src={nft.imageUrl}
                                                        alt={nft.name}
                                                        width={200}
                                                        height={200}
                                                        className="w-full h-full object-cover"
                                                    />
                                                ) : (
                                                    <div className="w-full h-full flex items-center justify-center">
                                                        <ImageIcon className="w-8 h-8 text-white/40" />
                                                    </div>
                                                )}
                                            </div>
                                            <h4 className="font-medium text-white text-sm truncate">{nft.name}</h4>
                                            {nft.collection && (
                                                <p className="text-xs text-white/60 truncate">{nft.collection}</p>
                                            )}
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}