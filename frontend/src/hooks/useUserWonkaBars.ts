import { useCurrentAccount, useSuiClient } from "@mysten/dapp-kit"
import { useQuery } from "@tanstack/react-query"
import { MELTYFI_PACKAGE_ID } from "../constants/contracts"

// src/hooks/useUserWonkaBars.ts
export function useUserWonkaBars() {
    const suiClient = useSuiClient()
    const currentAccount = useCurrentAccount()

    return useQuery({
        queryKey: ['user-wonkabars', currentAccount?.address],
        queryFn: async () => {
            if (!currentAccount) return []

            const response = await suiClient.getOwnedObjects({
                owner: currentAccount.address,
                filter: {
                    StructType: `${MELTYFI_PACKAGE_ID}::wonka_bars::WonkaBars`
                },
                options: {
                    showContent: true,
                    showType: true,
                }
            })

            return response.data.map(item => {
                if (item.data?.content && 'fields' in item.data.content) {
                    const fields = item.data.content.fields as any
                    return {
                        id: fields.id.id,
                        lottery_id: parseInt(fields.lottery_id),
                        quantity: parseInt(fields.quantity),
                        owner: fields.owner,
                        name: fields.name,
                        description: fields.description,
                        image_url: fields.image_url,
                    }
                }
                return null
            }).filter(Boolean)
        },
        enabled: !!currentAccount,
        refetchInterval: 10000,
    })
}