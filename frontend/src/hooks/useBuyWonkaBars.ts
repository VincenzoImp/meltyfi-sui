import { useCurrentAccount, useSuiClient } from "@mysten/dapp-kit"
import { TransactionBlock } from "@mysten/sui.js/transactions"
import { useMutation, useQueryClient } from "@tanstack/react-query"
import { MELTYFI_PACKAGE_ID, PROTOCOL_OBJECT_ID } from "../constants/contracts"

// src/hooks/useBuyWonkaBars.ts
export function useBuyWonkaBars() {
    const suiClient = useSuiClient()
    const currentAccount = useCurrentAccount()
    const queryClient = useQueryClient()

    return useMutation({
        mutationFn: async (params: {
            lotteryId: string,
            quantity: number,
            totalCost: number,
            chocolateFactoryId: string
        }) => {
            if (!currentAccount) throw new Error('No account connected')

            const txb = new TransactionBlock()

            // Split coin for payment
            const coin = txb.splitCoins(txb.gas, [txb.pure(params.totalCost)])

            // Call buy_wonkabars function
            txb.moveCall({
                target: `${MELTYFI_PACKAGE_ID}::meltyfi_core::buy_wonkabars`,
                arguments: [
                    txb.object(PROTOCOL_OBJECT_ID),
                    txb.object(params.lotteryId),
                    coin,
                    txb.pure(params.quantity),
                    txb.object(params.chocolateFactoryId), // Add ChocolateFactory parameter
                    txb.object('0x6'), // Clock object
                ],
            })

            txb.setGasBudget(10_000_000)

            // Use wallet adapter to sign and execute the transaction block
            const response = await currentAccount?.signAndExecuteTransactionBlock({
                transactionBlock: txb,
                options: {
                    showEffects: true,
                    showObjectChanges: true,
                },
            })

            return response
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['lotteries'] })
            queryClient.invalidateQueries({ queryKey: ['user-wonkabars'] })
            queryClient.invalidateQueries({ queryKey: ['user-chocochips'] })
        },
    })
}