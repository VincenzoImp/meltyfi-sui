// src/hooks/useLotteries.ts
import { MELTYFI_PACKAGE_ID } from '@/constants/contracts'
import type { Lottery } from '@/types/lottery'
import { useSuiClient } from '@mysten/dapp-kit'
import { useQuery } from '@tanstack/react-query'

interface FilterState {
    status: 'all' | 'active' | 'concluded' | 'cancelled'
    priceRange: [number, number]
    timeRange: 'all' | '24h' | '7d' | '30d'
    sortBy: 'newest' | 'ending_soon' | 'price_low' | 'price_high' | 'popular'
}

export function useLotteries(filters: FilterState) {
    const suiClient = useSuiClient()

    return useQuery({
        queryKey: ['lotteries', filters],
        queryFn: async (): Promise<Lottery[]> => {
            try {
                // Get all lottery objects
                const response = await suiClient.getOwnedObjects({
                    filter: {
                        StructType: `${MELTYFI_PACKAGE_ID}::meltyfi_core::Lottery`
                    },
                    options: {
                        showContent: true,
                        showType: true,
                    }
                })

                // Transform the response into our Lottery type
                const lotteries: Lottery[] = []

                for (const item of response.data) {
                    if (item.data?.content && 'fields' in item.data.content) {
                        const fields = item.data.content.fields as any

                        // Create lottery object from on-chain data
                        const lottery: Lottery = {
                            id: fields.id.id,
                            lottery_id: parseInt(fields.lottery_id),
                            name: `Lottery #${fields.lottery_id}`,
                            description: 'NFT-backed lottery with WonkaBar tickets',
                            owner: fields.owner,
                            state: parseInt(fields.state),
                            expirationDate: parseInt(fields.expiration_date),
                            wonkabarPrice: parseInt(fields.wonkabar_price),
                            maxSupply: parseInt(fields.max_supply),
                            soldCount: parseInt(fields.sold_count),
                            winner: fields.winner,
                            nftImage: '/images/default-nft.png', // Default image
                            participantCount: 0, // Would need to calculate from participants table
                            totalValue: parseInt(fields.wonkabar_price) * parseInt(fields.sold_count),
                            timeRemaining: Math.max(0, parseInt(fields.expiration_date) - Date.now())
                        }

                        lotteries.push(lottery)
                    }
                }

                // Apply filters
                let filtered = lotteries

                // Status filter
                if (filters.status !== 'all') {
                    const statusMap = { active: 0, cancelled: 1, concluded: 2 }
                    filtered = filtered.filter(l => l.state === statusMap[filters.status])
                }

                // Price range filter
                filtered = filtered.filter(l =>
                    l.wonkabarPrice >= filters.priceRange[0] * 1_000_000_000 &&
                    l.wonkabarPrice <= filters.priceRange[1] * 1_000_000_000
                )

                // Time range filter
                if (filters.timeRange !== 'all') {
                    const now = Date.now()
                    const timeRanges = {
                        '24h': 24 * 60 * 60 * 1000,
                        '7d': 7 * 24 * 60 * 60 * 1000,
                        '30d': 30 * 24 * 60 * 60 * 1000
                    }
                    const timeLimit = now + timeRanges[filters.timeRange]
                    filtered = filtered.filter(l => l.expirationDate <= timeLimit)
                }

                // Sort
                switch (filters.sortBy) {
                    case 'newest':
                        filtered.sort((a, b) => b.lottery_id - a.lottery_id)
                        break
                    case 'ending_soon':
                        filtered.sort((a, b) => a.expirationDate - b.expirationDate)
                        break
                    case 'price_low':
                        filtered.sort((a, b) => a.wonkabarPrice - b.wonkabarPrice)
                        break
                    case 'price_high':
                        filtered.sort((a, b) => b.wonkabarPrice - a.wonkabarPrice)
                        break
                    case 'popular':
                        filtered.sort((a, b) => b.soldCount - a.soldCount)
                        break
                }

                return filtered
            } catch (error) {
                console.error('Error fetching lotteries:', error)
                throw error
            }
        },
        refetchInterval: 10000, // Refetch every 10 seconds
        staleTime: 5000, // Consider data stale after 5 seconds
    })
}