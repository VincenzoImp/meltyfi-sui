// src/utils/formatting.ts
export function formatSuiAmount(amount: number | string): string {
    const num = typeof amount === 'string' ? parseInt(amount) : amount
    const sui = num / 1_000_000_000 // Convert MIST to SUI

    if (sui < 0.001) return '< 0.001 SUI'
    if (sui < 1) return `${sui.toFixed(3)} SUI`
    if (sui < 1000) return `${sui.toFixed(2)} SUI`
    if (sui < 1000000) return `${(sui / 1000).toFixed(1)}K SUI`
    return `${(sui / 1000000).toFixed(1)}M SUI`
}

export function formatTimeRemaining(expirationDate: number): string {
    const now = Date.now()
    const diff = expirationDate - now

    if (diff <= 0) return 'Expired'

    const days = Math.floor(diff / (1000 * 60 * 60 * 24))
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))

    if (days > 0) return `${days}d ${hours}h`
    if (hours > 0) return `${hours}h ${minutes}m`
    return `${minutes}m`
}

export function formatPercentage(value: number): string {
    return `${Math.round(value)}%`
}

export function formatAddress(address: string): string {
    if (address.length <= 12) return address
    return `${address.slice(0, 6)}...${address.slice(-4)}`
}

export function formatNumber(num: number): string {
    if (num < 1000) return num.toString()
    if (num < 1000000) return `${(num / 1000).toFixed(1)}K`
    return `${(num / 1000000).toFixed(1)}M`
}