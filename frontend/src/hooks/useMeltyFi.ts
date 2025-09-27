'use client';

import {
    MELTYFI_PACKAGE_ID,
    PROTOCOL_OBJECT_ID,
    WONKA_BAR_TYPE
} from '@/constants/contracts';
import {
    useCurrentAccount,
    useSignAndExecuteTransaction, // Changed from useSignAndExecuteTransactionBlock
    useSuiClient
} from '@mysten/dapp-kit';
import type { SuiObjectResponse } from '@mysten/sui/client';
import { Transaction } from '@mysten/sui/transactions';
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
    participants: number;
}

export interface WonkaBar {
    id: string;
    lotteryId: string;
    owner: string;
    wonNumber: string;
}

export function useMeltyFi() {
    const currentAccount = useCurrentAccount();
    const suiClient = useSuiClient();
    const queryClient = useQueryClient();
    const { mutateAsync: signAndExecuteTransaction } = useSignAndExecuteTransaction(); // Changed name

    // Fetch all lotteries
    const { data: lotteries = [], isLoading: isLoadingLotteries } = useQuery({
        queryKey: ['lotteries'],
        queryFn: async () => {
            // Implementation to fetch lotteries from blockchain
            const objects = await suiClient.getOwnedObjects({
                owner: PROTOCOL_OBJECT_ID,
                options: {
                    showContent: true,
                    showDisplay: true,
                    showType: true,
                },
            });

            // Parse and transform lottery data
            return objects.data.map((obj: SuiObjectResponse) => {
                // Your parsing logic here
                return {} as Lottery;
            });
        },
        refetchInterval: 10000, // Refetch every 10 seconds
    });

    // Fetch user's WonkaBars
    const { data: userWonkaBars = [], isLoading: isLoadingWonkaBars } = useQuery({
        queryKey: ['wonkaBars', currentAccount?.address],
        queryFn: async () => {
            if (!currentAccount?.address) return [];

            const objects = await suiClient.getOwnedObjects({
                owner: currentAccount.address,
                filter: { StructType: WONKA_BAR_TYPE },
                options: {
                    showContent: true,
                    showDisplay: true,
                    showType: true,
                },
            });

            return objects.data.map((obj: SuiObjectResponse) => {
                // Your parsing logic here
                return {} as WonkaBar;
            });
        },
        enabled: !!currentAccount?.address,
        refetchInterval: 10000,
    });

    // Create lottery mutation
    const { mutateAsync: createLottery, isPending: isCreatingLottery } = useMutation({
        mutationFn: async ({
            nftId,
            wonkaBarPrice,
            maxSupply,
            expirationDate, // Renamed from 'duration' to be more accurate
        }: {
            nftId: string;
            wonkaBarPrice: string;
            maxSupply: string;
            expirationDate: string; // Absolute timestamp as string
        }) => {
            if (!currentAccount?.address) throw new Error('Wallet not connected');

            const tx = new Transaction();

            tx.moveCall({
                target: `${MELTYFI_PACKAGE_ID}::core::create_lottery`,
                arguments: [
                    tx.object(PROTOCOL_OBJECT_ID),
                    tx.object(nftId),
                    tx.pure.u64(expirationDate), // Convert string to u64 for Move contract
                    tx.pure.u64(wonkaBarPrice),
                    tx.pure.u64(maxSupply),
                    tx.object('0x6'), // Clock object
                ],
            });

            const result = await signAndExecuteTransaction({
                transaction: tx,
                options: {
                    showEffects: true,
                    showObjectChanges: true,
                },
            });

            return result;
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['lotteries'] });
            toast.success('Lottery created successfully!');
        },
        onError: (error) => {
            console.error('Failed to create lottery:', error);
            toast.error('Failed to create lottery');
        },
    });

    // Buy WonkaBars mutation
    const { mutateAsync: buyWonkaBars, isPending: isBuyingWonkaBars } = useMutation({
        mutationFn: async ({
            lotteryId,
            quantity,
            payment,
        }: {
            lotteryId: string;
            quantity: number;
            payment: string;
        }) => {
            if (!currentAccount?.address) throw new Error('Wallet not connected');

            const tx = new Transaction();

            tx.moveCall({
                target: `${MELTYFI_PACKAGE_ID}::core::buy_wonkabar`,
                arguments: [
                    tx.object(PROTOCOL_OBJECT_ID),
                    tx.object(lotteryId),
                    tx.pure.u64(quantity),
                    tx.object(payment),
                ],
            });

            // Changed: use the new API
            const result = await signAndExecuteTransaction({
                transaction: tx, // Changed from transactionBlock
                options: {
                    showEffects: true,
                    showObjectChanges: true,
                },
            });

            return result;
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['lotteries'] });
            queryClient.invalidateQueries({ queryKey: ['wonkaBars'] });
            toast.success('WonkaBars purchased successfully!');
        },
        onError: (error) => {
            console.error('Error buying WonkaBars:', error);
            toast.error('Failed to buy WonkaBars');
        },
    });

    // Redeem WonkaBar mutation
    const { mutateAsync: redeemWonkaBars, isPending: isRedeemingWonkaBars } = useMutation({
        mutationFn: async ({
            lotteryId,
            wonkaBarId,
        }: {
            lotteryId: string;
            wonkaBarId: string;
        }) => {
            if (!currentAccount?.address) throw new Error('Wallet not connected');

            const tx = new Transaction();

            tx.moveCall({
                target: `${MELTYFI_PACKAGE_ID}::core::redeem_wonkabar`,
                arguments: [
                    tx.object(PROTOCOL_OBJECT_ID),
                    tx.object(lotteryId),
                    tx.object(wonkaBarId),
                ],
            });

            // Changed: use the new API
            const result = await signAndExecuteTransaction({
                transaction: tx, // Changed from transactionBlock
                options: {
                    showEffects: true,
                    showObjectChanges: true,
                },
            });

            return result;
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['lotteries'] });
            queryClient.invalidateQueries({ queryKey: ['wonkaBars'] });
            queryClient.invalidateQueries({ queryKey: ['balance'] });
            toast.success('WonkaBar redeemed successfully!');
        },
        onError: (error) => {
            console.error('Error redeeming WonkaBar:', error);
            toast.error('Failed to redeem WonkaBar');
        },
    });

    return {
        // Data
        lotteries,
        userWonkaBars,

        // Loading states
        isLoadingLotteries,
        isLoadingWonkaBars,

        // Mutations
        createLottery,
        isCreatingLottery,
        buyWonkaBars,
        isBuyingWonkaBars,
        redeemWonkaBars,
        isRedeemingWonkaBars,
    };
}