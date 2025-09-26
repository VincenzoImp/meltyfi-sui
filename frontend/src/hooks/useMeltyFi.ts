// src/hooks/useMeltyFi.ts
'use client';

declare global {
    interface Window {
        suiWallet?: {
            signAndExecuteTransactionBlock: (args: any) => Promise<any>;
        };
    }
}

import { MELTYFI_PACKAGE_ID, PROTOCOL_OBJECT_ID } from '@/constants/contracts';
import { useCurrentAccount, useSuiClient } from '@mysten/dapp-kit';
import { Transaction } from '@mysten/sui/transactions';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';

interface CreateLotteryParams {
    nftId: string;
    expirationDate: number;
    wonkabarPrice: number;
    maxSupply: number;
}

interface BuyWonkaBarsParams {
    lotteryId: string;
    quantity: number;
    totalCost: number;
}

export function useMeltyFi() {
    const client = useSuiClient();
    const currentAccount = useCurrentAccount();
    const queryClient = useQueryClient();
    const [isLoading, setIsLoading] = useState(false);

    // Create lottery mutation
    const createLotteryMutation = useMutation({
        mutationFn: async (params: CreateLotteryParams) => {
            if (!currentAccount) throw new Error('No wallet connected');

            setIsLoading(true);
            try {
                const tx = new Transaction();

                tx.moveCall({
                    target: `${MELTYFI_PACKAGE_ID}::meltyfi_core::create_lottery`,
                    arguments: [
                        tx.object(PROTOCOL_OBJECT_ID),
                        tx.object(params.nftId),
                        tx.pure.u64(params.expirationDate),
                        tx.pure.u64(params.wonkabarPrice),
                        tx.pure.u64(params.maxSupply),
                        tx.object('0x6'), // Clock
                    ],
                });

                // Use wallet adapter for signing and executing the transaction
                const result = await window?.suiWallet?.signAndExecuteTransactionBlock({
                    transactionBlock: tx,
                    options: {
                        showEffects: true,
                        showObjectChanges: true,
                    },
                });

                return result;
            } finally {
                setIsLoading(false);
            }
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['lotteries'] });
            queryClient.invalidateQueries({ queryKey: ['user-lotteries'] });
        },
    });

    // Buy WonkaBars mutation
    const buyWonkaBarsMutation = useMutation({
        mutationFn: async (params: BuyWonkaBarsParams) => {
            if (!currentAccount) throw new Error('No wallet connected');

            setIsLoading(true);
            try {
                const tx = new Transaction();

                const [coin] = tx.splitCoins(tx.gas, [tx.pure.u64(params.totalCost)]);

                tx.moveCall({
                    target: `${MELTYFI_PACKAGE_ID}::meltyfi_core::buy_wonkabars`,
                    arguments: [
                        tx.object(PROTOCOL_OBJECT_ID),
                        tx.object(params.lotteryId),
                        coin,
                        tx.pure.u64(params.quantity),
                        tx.object('0x6'), // Clock
                    ],
                });

                const result = await window?.suiWallet?.signAndExecuteTransactionBlock({
                    transactionBlock: tx,
                    options: {
                        showEffects: true,
                        showObjectChanges: true,
                    },
                });

                return result;
            } finally {
                setIsLoading(false);
            }
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['lotteries'] });
            queryClient.invalidateQueries({ queryKey: ['user-wonkabars'] });
        },
    });

    // Redeem WonkaBars mutation
    const redeemWonkaBarsMutation = useMutation({
        mutationFn: async (wonkaBarsId: string) => {
            if (!currentAccount) throw new Error('No wallet connected');

            setIsLoading(true);
            try {
                const tx = new Transaction();

                tx.moveCall({
                    target: `${MELTYFI_PACKAGE_ID}::meltyfi_core::redeem_wonkabars`,
                    arguments: [
                        tx.object(PROTOCOL_OBJECT_ID),
                        tx.object(wonkaBarsId),
                    ],
                });

                const result = await window?.suiWallet?.signAndExecuteTransactionBlock({
                    transactionBlock: tx,
                    options: {
                        showEffects: true,
                        showObjectChanges: true,
                    },
                });

                return result;
            } finally {
                setIsLoading(false);
            }
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['user-wonkabars'] });
            queryClient.invalidateQueries({ queryKey: ['user-balance'] });
        },
    });

    // Get all lotteries
    const getLotteriesQuery = useQuery({
        queryKey: ['lotteries'],
        queryFn: async () => {
            try {
                const response = await client.getOwnedObjects({
                    filter: {
                        StructType: `${MELTYFI_PACKAGE_ID}::meltyfi_core::Lottery`
                    },
                    options: {
                        showContent: true,
                        showType: true,
                    },
                    owner: PROTOCOL_OBJECT_ID, // Query shared objects
                });

                return response.data.map(item => {
                    if (item.data?.content && 'fields' in item.data.content) {
                        const fields = item.data.content.fields as any;
                        return {
                            id: item.data.objectId,
                            lottery_id: parseInt(fields.lottery_id),
                            owner: fields.owner,
                            state: parseInt(fields.state),
                            expirationDate: parseInt(fields.expiration_date),
                            wonkabarPrice: parseInt(fields.wonkabar_price),
                            maxSupply: parseInt(fields.max_supply),
                            soldCount: parseInt(fields.sold_count),
                            winner: fields.winner,
                        };
                    }
                    return null;
                }).filter(Boolean);
            } catch (error) {
                console.error('Error fetching lotteries:', error);
                return [];
            }
        },
        refetchInterval: 10000,
    });

    // Get user's WonkaBars
    const getUserWonkaBarsQuery = useQuery({
        queryKey: ['user-wonkabars', currentAccount?.address],
        queryFn: async () => {
            if (!currentAccount) return [];

            try {
                const response = await client.getOwnedObjects({
                    owner: currentAccount.address,
                    filter: {
                        StructType: `${MELTYFI_PACKAGE_ID}::wonka_bars::WonkaBars`
                    },
                    options: {
                        showContent: true,
                        showType: true,
                    }
                });

                return response.data.map(item => {
                    if (item.data?.content && 'fields' in item.data.content) {
                        const fields = item.data.content.fields as any;
                        return {
                            id: item.data.objectId,
                            lottery_id: parseInt(fields.lottery_id),
                            quantity: parseInt(fields.quantity),
                            owner: fields.owner,
                        };
                    }
                    return null;
                }).filter(Boolean);
            } catch (error) {
                console.error('Error fetching user WonkaBars:', error);
                return [];
            }
        },
        enabled: !!currentAccount,
        refetchInterval: 10000,
    });

    // Get user's balance
    const getUserBalanceQuery = useQuery({
        queryKey: ['user-balance', currentAccount?.address],
        queryFn: async () => {
            if (!currentAccount) return '0';

            try {
                const balance = await client.getBalance({
                    owner: currentAccount.address,
                    coinType: '0x2::sui::SUI'
                });

                return balance.totalBalance;
            } catch (error) {
                console.error('Error fetching balance:', error);
                return '0';
            }
        },
        enabled: !!currentAccount,
        refetchInterval: 30000,
    });

    return {
        // Mutations
        createLottery: createLotteryMutation.mutate,
        buyWonkaBars: buyWonkaBarsMutation.mutate,
        redeemWonkaBars: redeemWonkaBarsMutation.mutate,

        // Queries
        lotteries: getLotteriesQuery.data || [],
        userWonkaBars: getUserWonkaBarsQuery.data || [],
        userBalance: getUserBalanceQuery.data || '0',

        // Loading states
        isLoading: isLoading ||
            createLotteryMutation.isPending ||
            buyWonkaBarsMutation.isPending ||
            redeemWonkaBarsMutation.isPending,

        isLoadingLotteries: getLotteriesQuery.isLoading,
        isLoadingUserData: getUserWonkaBarsQuery.isLoading || getUserBalanceQuery.isLoading,

        // Error states
        createLotteryError: createLotteryMutation.error,
        buyWonkaBarsError: buyWonkaBarsMutation.error,
        redeemError: redeemWonkaBarsMutation.error,
    };
}