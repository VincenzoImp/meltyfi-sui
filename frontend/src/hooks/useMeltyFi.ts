'use client';

import {
    CHOCOLATE_FACTORY_ID,
    CHOCO_CHIP_TYPE,
    DEFAULT_GAS_BUDGET,
    MELTYFI_PACKAGE_ID,
    PROTOCOL_OBJECT_ID,
    WONKA_BAR_TYPE
} from '@/constants/contracts';
import {
    useCurrentAccount,
    useSignAndExecuteTransactionBlock,
    useSuiClient
} from '@mysten/dapp-kit';
import { SuiObjectResponse } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';

export interface Lottery {
    id: string;
    lotteryId: string;
    owner: string;
    state: 'ACTIVE' | 'CANCELLED' | 'CONCLUDED';
    expirationDate: number;
    wonkaBarPrice: string;
    maxSupply: string;
    soldCount: string;
    winner?: string;
    collateralNft: {
        id: string;
        name: string;
        imageUrl: string;
        collection?: string;
    };
    totalFunds: string;
    participants: number;
}

export interface WonkaBar {
    id: string;
    lotteryId: string;
    quantity: string;
    purchasedAt: number;
}

export interface UserStats {
    totalLotteries: number;
    activeLotteries: number;
    totalWonkaBars: number;
    chocoChipBalance: string;
    suiBalance: string;
}

export function useMeltyFi() {
    const currentAccount = useCurrentAccount();
    const suiClient = useSuiClient();
    const { mutateAsync: signAndExecute } = useSignAndExecuteTransactionBlock();
    const queryClient = useQueryClient();

    // Query: Get all active lotteries
    const { data: lotteries = [], isLoading: lotteriesLoading } = useQuery({
        queryKey: ['lotteries', PROTOCOL_OBJECT_ID],
        queryFn: async (): Promise<Lottery[]> => {
            if (!PROTOCOL_OBJECT_ID) return [];

            try {
                // Get protocol object
                const protocolObject = await suiClient.getObject({
                    id: PROTOCOL_OBJECT_ID,
                    options: { showContent: true, showType: true }
                });

                if (!protocolObject.data?.content || protocolObject.data.content.dataType !== 'moveObject') {
                    return [];
                }

                // Get active lottery IDs from protocol
                const protocolData = protocolObject.data.content.fields as any;
                const activeLotteryIds = protocolData.active_lotteries || [];

                // Fetch lottery details
                const lotteryPromises = activeLotteryIds.map(async (lotteryId: string) => {
                    const lotteryObject = await suiClient.getObject({
                        id: lotteryId,
                        options: { showContent: true, showType: true, showDisplay: true }
                    });

                    if (!lotteryObject.data?.content || lotteryObject.data.content.dataType !== 'moveObject') {
                        return null;
                    }

                    const fields = lotteryObject.data.content.fields as any;

                    return {
                        id: lotteryId,
                        lotteryId: fields.lottery_id,
                        owner: fields.owner,
                        state: fields.state === 0 ? 'ACTIVE' : fields.state === 1 ? 'CANCELLED' : 'CONCLUDED',
                        expirationDate: parseInt(fields.expiration_date),
                        wonkaBarPrice: fields.wonkabar_price,
                        maxSupply: fields.max_supply,
                        soldCount: fields.sold_count,
                        winner: fields.winner?.vec?.[0],
                        collateralNft: {
                            id: fields.collateral_nft || lotteryId,
                            name: fields.nft_name || `Lottery #${fields.lottery_id}`,
                            imageUrl: fields.nft_image_url || '/placeholder-nft.png',
                            collection: fields.nft_collection
                        },
                        totalFunds: fields.funds?.value || '0',
                        participants: Object.keys(fields.participants?.fields || {}).length
                    } as Lottery;
                });

                const resolvedLotteries = await Promise.all(lotteryPromises);
                return resolvedLotteries.filter(Boolean) as Lottery[];
            } catch (error) {
                console.error('Error fetching lotteries:', error);
                return [];
            }
        },
        enabled: !!PROTOCOL_OBJECT_ID,
        refetchInterval: 10000 // Refresh every 10 seconds
    });

    // Query: Get user's WonkaBars
    const { data: userWonkaBars = [], isLoading: wonkaBarsLoading } = useQuery({
        queryKey: ['userWonkaBars', currentAccount?.address],
        queryFn: async (): Promise<WonkaBar[]> => {
            if (!currentAccount?.address || !WONKA_BAR_TYPE) return [];

            try {
                const objects = await suiClient.getOwnedObjects({
                    owner: currentAccount.address,
                    filter: { StructType: WONKA_BAR_TYPE },
                    options: { showContent: true, showType: true }
                });

                return objects.data.map((obj: SuiObjectResponse) => {
                    if (!obj.data?.content || obj.data.content.dataType !== 'moveObject') {
                        return null;
                    }

                    const fields = obj.data.content.fields as any;
                    return {
                        id: obj.data.objectId,
                        lotteryId: fields.lottery_id,
                        quantity: fields.quantity || '1',
                        purchasedAt: parseInt(fields.purchased_at || Date.now())
                    };
                }).filter(Boolean) as WonkaBar[];
            } catch (error) {
                console.error('Error fetching WonkaBars:', error);
                return [];
            }
        },
        enabled: !!currentAccount?.address,
        refetchInterval: 15000
    });

    // Query: Get user stats
    const { data: userStats } = useQuery({
        queryKey: ['userStats', currentAccount?.address],
        queryFn: async (): Promise<UserStats> => {
            if (!currentAccount?.address) {
                return {
                    totalLotteries: 0,
                    activeLotteries: 0,
                    totalWonkaBars: 0,
                    chocoChipBalance: '0',
                    suiBalance: '0'
                };
            }

            try {
                // Get user's balance
                const balance = await suiClient.getBalance({
                    owner: currentAccount.address
                });

                // Get ChocoChip balance
                let chocoChipBalance = '0';
                if (CHOCO_CHIP_TYPE) {
                    const chocoChipObjects = await suiClient.getOwnedObjects({
                        owner: currentAccount.address,
                        filter: { StructType: CHOCO_CHIP_TYPE },
                        options: { showContent: true }
                    });

                    chocoChipBalance = chocoChipObjects.data.reduce((total, obj) => {
                        if (obj.data?.content && obj.data.content.dataType === 'moveObject') {
                            const fields = obj.data.content.fields as any;
                            return total + BigInt(fields.balance?.value || 0);
                        }
                        return total;
                    }, BigInt(0)).toString();
                }

                const userLotteries = lotteries.filter(lottery => lottery.owner === currentAccount.address);
                const activeLotteries = userLotteries.filter(lottery => lottery.state === 'ACTIVE');

                return {
                    totalLotteries: userLotteries.length,
                    activeLotteries: activeLotteries.length,
                    totalWonkaBars: userWonkaBars.length,
                    chocoChipBalance,
                    suiBalance: balance.totalBalance
                };
            } catch (error) {
                console.error('Error fetching user stats:', error);
                return {
                    totalLotteries: 0,
                    activeLotteries: 0,
                    totalWonkaBars: 0,
                    chocoChipBalance: '0',
                    suiBalance: '0'
                };
            }
        },
        enabled: !!currentAccount?.address,
        refetchInterval: 20000
    });

    // Mutation: Create lottery
    const createLotteryMutation = useMutation({
        mutationFn: async (params: {
            nftId: string;
            wonkaBarPrice: string;
            maxSupply: string;
            duration: number;
        }) => {
            if (!currentAccount?.address) throw new Error('Wallet not connected');
            if (!MELTYFI_PACKAGE_ID || !PROTOCOL_OBJECT_ID) throw new Error('Contracts not configured');

            const txb = new TransactionBlock();

            // Create lottery transaction
            txb.moveCall({
                target: `${MELTYFI_PACKAGE_ID}::core::create_lottery`,
                arguments: [
                    txb.object(PROTOCOL_OBJECT_ID),
                    txb.object(params.nftId),
                    txb.pure(params.wonkaBarPrice),
                    txb.pure(params.maxSupply),
                    txb.pure(params.duration),
                    txb.object('0x8') // Clock object
                ],
            });

            txb.setGasBudget(DEFAULT_GAS_BUDGET);

            const result = await signAndExecute({
                transactionBlock: txb,
                options: { showObjectChanges: true, showEffects: true }
            });

            return result;
        },
        onSuccess: () => {
            toast.success('Lottery created successfully!');
            queryClient.invalidateQueries({ queryKey: ['lotteries'] });
            queryClient.invalidateQueries({ queryKey: ['userStats'] });
        },
        onError: (error) => {
            console.error('Create lottery error:', error);
            toast.error('Failed to create lottery. Please try again.');
        }
    });

    // Mutation: Buy WonkaBars
    const buyWonkaBarsMutation = useMutation({
        mutationFn: async (params: {
            lotteryId: string;
            quantity: number;
            totalCost: string;
        }) => {
            if (!currentAccount?.address) throw new Error('Wallet not connected');
            if (!MELTYFI_PACKAGE_ID) throw new Error('Contracts not configured');

            const txb = new TransactionBlock();

            // Split SUI coin for payment
            const [paymentCoin] = txb.splitCoins(txb.gas, [txb.pure(params.totalCost)]);

            // Buy WonkaBars
            txb.moveCall({
                target: `${MELTYFI_PACKAGE_ID}::core::buy_wonka_bars`,
                arguments: [
                    txb.object(params.lotteryId),
                    paymentCoin,
                    txb.pure(params.quantity),
                    txb.object('0x8'), // Clock object
                    txb.object(CHOCOLATE_FACTORY_ID)
                ],
            });

            txb.setGasBudget(DEFAULT_GAS_BUDGET);

            const result = await signAndExecute({
                transactionBlock: txb,
                options: { showObjectChanges: true, showEffects: true }
            });

            return result;
        },
        onSuccess: () => {
            toast.success('WonkaBars purchased successfully!');
            queryClient.invalidateQueries({ queryKey: ['lotteries'] });
            queryClient.invalidateQueries({ queryKey: ['userWonkaBars'] });
            queryClient.invalidateQueries({ queryKey: ['userStats'] });
        },
        onError: (error) => {
            console.error('Buy WonkaBars error:', error);
            toast.error('Failed to purchase WonkaBars. Please try again.');
        }
    });

    // Mutation: Repay lottery
    const repayLotteryMutation = useMutation({
        mutationFn: async (params: {
            lotteryId: string;
            repaymentAmount: string;
        }) => {
            if (!currentAccount?.address) throw new Error('Wallet not connected');
            if (!MELTYFI_PACKAGE_ID) throw new Error('Contracts not configured');

            const txb = new TransactionBlock();

            // Split SUI coin for repayment
            const [repaymentCoin] = txb.splitCoins(txb.gas, [txb.pure(params.repaymentAmount)]);

            // Repay lottery
            txb.moveCall({
                target: `${MELTYFI_PACKAGE_ID}::core::repay_lottery`,
                arguments: [
                    txb.object(params.lotteryId),
                    repaymentCoin,
                    txb.object('0x8') // Clock object
                ],
            });

            txb.setGasBudget(DEFAULT_GAS_BUDGET);

            const result = await signAndExecute({
                transactionBlock: txb,
                options: { showObjectChanges: true, showEffects: true }
            });

            return result;
        },
        onSuccess: () => {
            toast.success('Lottery repaid successfully!');
            queryClient.invalidateQueries({ queryKey: ['lotteries'] });
            queryClient.invalidateQueries({ queryKey: ['userStats'] });
        },
        onError: (error) => {
            console.error('Repay lottery error:', error);
            toast.error('Failed to repay lottery. Please try again.');
        }
    });

    return {
        // Data
        lotteries,
        userWonkaBars,
        userStats,

        // Loading states
        lotteriesLoading,
        wonkaBarsLoading,

        // Mutations
        createLottery: createLotteryMutation.mutateAsync,
        buyWonkaBars: buyWonkaBarsMutation.mutateAsync,
        repayLottery: repayLotteryMutation.mutateAsync,

        // Mutation states
        isCreatingLottery: createLotteryMutation.isPending,
        isBuyingWonkaBars: buyWonkaBarsMutation.isPending,
        isRepayingLottery: repayLotteryMutation.isPending,

        // Account
        currentAccount,
        isConnected: !!currentAccount
    };
}
