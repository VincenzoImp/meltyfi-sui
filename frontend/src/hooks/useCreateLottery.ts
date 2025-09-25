// src/hooks/useCreateLottery.ts
import { PROTOCOL_OBJECT_ID } from '@/constants/contracts'
import { useCurrentAccount } from '@mysten/dapp-kit'
import { TransactionBlock } from '@mysten/sui.js/transactions'
import { useMutation, useQueryClient } from '@tanstack/react-query'

interface CreateLotteryParams {
    nftId: string
    expirationDate: number
    wonkabarPrice: number
    maxSupply: number
}

export function useCreateLottery() {
    const suiClient = useSuiClient()
    const currentAccount = useCurrentAccount()
    const queryClient = useQueryClient()

    return useMutation({
        mutationFn: async (params: CreateLotteryParams) => {
            if (!currentAccount) throw new Error('No account connected')

            const txb = new TransactionBlock()

            // Call create_lottery function
            const result = txb.moveCall({
                target: `${MELTYFI_PACKAGE_ID}::meltyfi_core::create_lottery`,
                arguments: [
                    txb.object(PROTOCOL_OBJECT_ID),
                    txb.object(params.nftId),
                    txb.pure(params.expirationDate),
                    txb.pure(params.wonkabarPrice),
                    txb.pure(params.maxSupply),
                    txb.object('0x6'), // Clock object
                ],
            })

            // Set gas budget
            txb.setGasBudget(10_000_000)

            // Execute transaction
            const response = await suiClient.signAndExecuteTransactionBlock({
                transactionBlock: txb,
                signer: currentAccount,
                options: {
                    showEffects: true,
                    showObjectChanges: true,
                },
            })

            return response
        },
        onSuccess: () => {
            // Invalidate lotteries query to refetch data
            queryClient.invalidateQueries({ queryKey: ['lotteries'] })
        },
    })
}