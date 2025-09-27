'use client';

import {
    CHOCOLATE_FACTORY_ID,
    MELTYFI_PACKAGE_ID,
    PROTOCOL_OBJECT_ID,
    WONKA_BAR_TYPE
} from '@/constants/contracts';
import {
    useCurrentAccount,
    useSignAndExecuteTransactionBlock,
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
}

export interface WonkaBar {
    id: string;
    lotteryId: string;
    owner: string;
}

export function useMeltyFi() {
    const currentAccount = useCurrentAccount();
    const suiClient = useSuiClient();
    const queryClient = useQueryClient();
    const { mutateAsync: signAndExecuteTransactionBlock } = useSignAndExecuteTransactionBlock();

    // Fetch all lotteries
    const { data: lotteries = [], isLoading: isLoadingLotteries } = useQuery({
        queryKey: ['lotteries', PROTOCOL_OBJECT_ID],
        queryFn: async () => {
            if (!PROTOCOL_OBJECT_ID) return [];

            try {
                const protocol = await suiClient.getObject({
                    id: PROTOCOL_OBJECT_ID,
                    options: { showContent: true }
                });

                if (protocol.data?.content?.dataType !== 'moveObject') return [];

                const fields = protocol.data.content.fields as any;
                const lotteryIds = fields.active_lotteries || [];

                const lotteryPromises = lotteryIds.map(async (lotteryId: string) => {
                    const lottery = await suiClient.getObject({
                        id: lotteryId,
                        options: { showContent: true }
                    });

                    if (lottery.data?.content?.dataType !== 'moveObject') return null;

                    const lotteryFields = lottery.data.content.fields as any;

                    return {
                        id: lotteryId,
                        lotteryId: lotteryFields.lottery_id,
                        owner: lotteryFields.owner,
                        state: ['ACTIVE', 'CANCELLED', 'CONCLUDED'][lotteryFields.state] as Lottery['state'],
                        expirationDate: Number(lotteryFields.expiration_date),
                        wonkaBarPrice: lotteryFields.wonkabar_price,
                        maxSupply: lotteryFields.max_supply,
                        soldCount: lotteryFields.sold_count,
                        winner: lotteryFields.winner,
                        collateralNft: {
                            id: lotteryFields.collateral_nft,
                            name: 'NFT',
                            imageUrl: ''
                        }
                    };
                });

                const results = await Promise.all(lotteryPromises);
                return results.filter((l): l is Lottery => l !== null);
            } catch (error) {
                console.error('Error fetching lotteries:', error);
                return [];
            }
        },
        enabled: !!PROTOCOL_OBJECT_ID,
        refetchInterval: 10000,
    });

    // Fetch user's WonkaBars
    const { data: userWonkaBars = [], isLoading: isLoadingWonkaBars } = useQuery({
        queryKey: ['wonkaBars', currentAccount?.address],
        queryFn: async () => {
            if (!currentAccount?.address) return [];

            try {
                const objects = await suiClient.getOwnedObjects({
                    owner: currentAccount.address,
                    filter: { StructType: WONKA_BAR_TYPE },
                    options: { showContent: true }
                });

                return objects.data
                    .map((obj: SuiObjectResponse) => {
                        if (obj.data?.content?.dataType !== 'moveObject') return null;
                        const fields = obj.data.content.fields as any;
                        return {
                            id: obj.data.objectId,
                            lotteryId: fields.lottery_id,
                            owner: fields.owner
                        };
                    })
                    .filter((w): w is WonkaBar => w !== null);
            } catch (error) {
                console.error('Error fetching WonkaBars:', error);
                return [];
            }
        },
        enabled: !!currentAccount?.address,
        refetchInterval: 10000,
    });

    // Fetch user's SUI balance
    const { data: userBalance = '0' } = useQuery({
        queryKey: ['balance', currentAccount?.address],
        queryFn: async () => {
            if (!currentAccount?.address) return '0';

            try {
                const balance = await suiClient.getBalance({
                    owner: currentAccount.address,
                    coinType: '0x2::sui::SUI'
                });
                return (Number(balance.totalBalance) / 1_000_000_000).toFixed(4);
            } catch (error) {
                console.error('Error fetching balance:', error);
                return '0';
            }
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
            durationDays
        }: {
            nftId: string;
            wonkaBarPrice: string;
            maxSupply: string;
            durationDays: number;
        }) => {
            if (!currentAccount?.address) throw new Error('Wallet not connected');

            const tx = new Transaction();

            const priceInMist = Math.floor(parseFloat(wonkaBarPrice) * 1_000_000_000);
            const expirationMs = Date.now() + (durationDays * 24 * 60 * 60 * 1000);

            tx.moveCall({
                target: `${MELTYFI_PACKAGE_ID}::core::create_lottery`,
                arguments: [
                    tx.object(PROTOCOL_OBJECT_ID),
                    tx.object(nftId),
                    tx.pure.u64(priceInMist),
                    tx.pure.u64(maxSupply),
                    tx.pure.u64(expirationMs),
                ],
            });

            const result = await signAndExecuteTransactionBlock({
                transactionBlock: tx,
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
            console.error('Error creating lottery:', error);
            toast.error('Failed to create lottery');
        },
    });

    // Buy WonkaBars mutation
    const { mutateAsync: buyWonkaBars, isPending: isBuyingWonkaBars } = useMutation({
        mutationFn: async ({
            lotteryId,
            quantity,
            totalPrice
        }: {
            lotteryId: string;
            quantity: number;
            totalPrice: string;
        }) => {
            if (!currentAccount?.address) throw new Error('Wallet not connected');

            const tx = new Transaction();

            const priceInMist = Math.floor(parseFloat(totalPrice) * 1_000_000_000);
            const [coin] = tx.splitCoins(tx.gas, [priceInMist]);

            tx.moveCall({
                target: `${MELTYFI_PACKAGE_ID}::core::buy_wonkabar`,
                arguments: [
                    tx.object(PROTOCOL_OBJECT_ID),
                    tx.object(lotteryId),
                    tx.pure.u64(quantity),
                    coin,
                    tx.object(CHOCOLATE_FACTORY_ID),
                ],
            });

            const result = await signAndExecuteTransactionBlock({
                transactionBlock: tx,
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
            wonkaBarId
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

            const result = await signAndExecuteTransactionBlock({
                transactionBlock: tx,
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
        userBalance,

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