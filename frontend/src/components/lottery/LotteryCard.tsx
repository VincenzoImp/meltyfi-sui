// src/components/lottery/LotteryCard.tsx
'use client'

import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import type { Lottery } from '@/types/lottery'
import { formatPercentage, formatSuiAmount, formatTimeRemaining } from '@/utils/formatting'
import { motion } from 'framer-motion'
import {
    Calendar,
    Clock,
    Coins,
    ExternalLink,
    TrendingUp,
    Trophy,
    Users,
    Zap
} from 'lucide-react'
import Image from 'next/image'
import { useState } from 'react'
import { BuyWonkaBarsModal } from './BuyWonkaBarsModal'

interface LotteryCardProps {
    lottery: Lottery
    viewMode: 'grid' | 'list'
}

export function LotteryCard({ lottery, viewMode }: LotteryCardProps) {
    const [isBuyModalOpen, setIsBuyModalOpen] = useState(false)
    const [isImageLoaded, setIsImageLoaded] = useState(false)

    const progress = (lottery.soldCount / lottery.maxSupply) * 100
    const timeRemaining = formatTimeRemaining(lottery.expirationDate)
    const isExpired = Date.now() > lottery.expirationDate
    const isNearlyFull = progress > 80

    const getStatusColor = (state: number) => {
        switch (state) {
            case 0: return 'bg-green-500' // ACTIVE
            case 1: return 'bg-yellow-500' // CANCELLED
            case 2: return 'bg-purple-500' // CONCLUDED
            default: return 'bg-gray-500'
        }
    }

    const getStatusText = (state: number) => {
        switch (state) {
            case 0: return 'Active'
            case 1: return 'Cancelled'
            case 2: return 'Concluded'
            default: return 'Unknown'
        }
    }

    if (viewMode === 'list') {
        return (
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.3 }}
                className="bg-white/10 backdrop-blur-sm rounded-2xl border border-white/20 p-6 hover:border-amber-300/50 transition-all duration-300"
            >
                <div className="flex items-center gap-6">
                    {/* NFT Image */}
                    <div className="relative w-24 h-24 flex-shrink-0">
                        <div className="w-full h-full bg-gradient-to-br from-purple-400/20 to-pink-500/20 rounded-xl overflow-hidden">
                            {lottery.nftImage && (
                                <Image
                                    src={lottery.nftImage}
                                    alt={lottery.name}
                                    fill
                                    className={`object-cover transition-opacity duration-300 ${isImageLoaded ? 'opacity-100' : 'opacity-0'
                                        }`}
                                    onLoad={() => setIsImageLoaded(true)}
                                />
                            )}
                            {!isImageLoaded && (
                                <div className="w-full h-full flex items-center justify-center">
                                    <Trophy className="w-8 h-8 text-amber-300" />
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Content */}
                    <div className="flex-1">
                        <div className="flex items-start justify-between mb-2">
                            <div>
                                <h3 className="text-xl font-bold text-white mb-1">{lottery.name}</h3>
                                <p className="text-gray-400 text-sm">{lottery.description}</p>
                            </div>
                            <Badge className={`${getStatusColor(lottery.state)} text-white`}>
                                {getStatusText(lottery.state)}
                            </Badge>
                        </div>

                        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
                            <div className="text-center">
                                <div className="text-2xl font-bold text-amber-300">
                                    {formatSuiAmount(lottery.wonkabarPrice)}
                                </div>
                                <div className="text-xs text-gray-400">Per WonkaBar</div>
                            </div>

                            <div className="text-center">
                                <div className="text-2xl font-bold text-white">
                                    {lottery.soldCount}/{lottery.maxSupply}
                                </div>
                                <div className="text-xs text-gray-400">Sold</div>
                            </div>

                            <div className="text-center">
                                <div className="text-2xl font-bold text-green-400">
                                    {lottery.participantCount}
                                </div>
                                <div className="text-xs text-gray-400">Participants</div>
                            </div>

                            <div className="text-center">
                                <div className="text-2xl font-bold text-orange-400">
                                    {timeRemaining}
                                </div>
                                <div className="text-xs text-gray-400">Remaining</div>
                            </div>
                        </div>

                        {/* Progress Bar */}
                        <div className="mb-4">
                            <div className="flex justify-between text-sm text-gray-400 mb-2">
                                <span>Progress</span>
                                <span>{formatPercentage(progress)}</span>
                            </div>
                            <div className="w-full bg-gray-700 rounded-full h-2">
                                <motion.div
                                    className="bg-gradient-to-r from-amber-400 to-orange-500 h-2 rounded-full"
                                    style={{ width: `${progress}%` }}
                                    initial={{ width: 0 }}
                                    animate={{ width: `${progress}%` }}
                                    transition={{ duration: 1, ease: "easeOut" }}
                                />
                            </div>
                        </div>

                        <div className="flex items-center justify-between">
                            <div className="flex items-center space-x-4 text-sm text-gray-400">
                                <div className="flex items-center">
                                    <Calendar className="w-4 h-4 mr-1" />
                                    Created by {lottery.owner.slice(0, 6)}...{lottery.owner.slice(-4)}
                                </div>
                            </div>

                            <div className="flex space-x-2">
                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => window.open(`https://suiexplorer.com/object/${lottery.id}`, '_blank')}
                                    className="border-white/20 text-white hover:bg-white/10"
                                >
                                    <ExternalLink className="w-4 h-4" />
                                </Button>

                                {lottery.state === 0 && !isExpired && (
                                    <Button
                                        onClick={() => setIsBuyModalOpen(true)}
                                        disabled={progress >= 100}
                                        className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white"
                                    >
                                        Buy WonkaBars
                                    </Button>
                                )}
                            </div>
                        </div>
                    </div>
                </div>

                <BuyWonkaBarsModal
                    isOpen={isBuyModalOpen}
                    onClose={() => setIsBuyModalOpen(false)}
                    lottery={lottery}
                />
            </motion.div>
        )
    }

    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
            className="group bg-white/10 backdrop-blur-sm rounded-2xl border border-white/20 p-6 hover:border-amber-300/50 hover:bg-white/15 transition-all duration-300 transform hover:scale-[1.02]"
        >
            {/* Header */}
            <div className="flex items-center justify-between mb-4">
                <Badge className={`${getStatusColor(lottery.state)} text-white`}>
                    {getStatusText(lottery.state)}
                </Badge>

                <div className="flex items-center space-x-2">
                    {isNearlyFull && (
                        <Badge className="bg-orange-500 text-white animate-pulse">
                            <Zap className="w-3 h-3 mr-1" />
                            Hot
                        </Badge>
                    )}

                    {lottery.participantCount > 10 && (
                        <Badge className="bg-purple-500 text-white">
                            <TrendingUp className="w-3 h-3 mr-1" />
                            Popular
                        </Badge>
                    )}
                </div>
            </div>

            {/* NFT Image */}
            <div className="relative w-full h-48 mb-4">
                <div className="w-full h-full bg-gradient-to-br from-purple-400/20 to-pink-500/20 rounded-xl overflow-hidden">
                    {lottery.nftImage && (
                        <Image
                            src={lottery.nftImage}
                            alt={lottery.name}
                            fill
                            className={`object-cover transition-opacity duration-300 ${isImageLoaded ? 'opacity-100' : 'opacity-0'
                                }`}
                            onLoad={() => setIsImageLoaded(true)}
                        />
                    )}
                    {!isImageLoaded && (
                        <div className="w-full h-full flex items-center justify-center">
                            <Trophy className="w-12 h-12 text-amber-300" />
                        </div>
                    )}
                </div>
            </div>

            {/* Content */}
            <div className="space-y-4">
                <div>
                    <h3 className="text-xl font-bold text-white group-hover:text-amber-300 transition-colors">
                        {lottery.name}
                    </h3>
                    <p className="text-gray-400 text-sm mt-1 line-clamp-2">
                        {lottery.description}
                    </p>
                </div>

                {/* Stats Grid */}
                <div className="grid grid-cols-2 gap-4 py-4 border-y border-white/10">
                    <div className="text-center">
                        <div className="flex items-center justify-center mb-1">
                            <Coins className="w-4 h-4 text-amber-300 mr-1" />
                        </div>
                        <div className="text-lg font-bold text-amber-300">
                            {formatSuiAmount(lottery.wonkabarPrice)}
                        </div>
                        <div className="text-xs text-gray-400">Per WonkaBar</div>
                    </div>

                    <div className="text-center">
                        <div className="flex items-center justify-center mb-1">
                            <Users className="w-4 h-4 text-green-400 mr-1" />
                        </div>
                        <div className="text-lg font-bold text-white">
                            {lottery.participantCount}
                        </div>
                        <div className="text-xs text-gray-400">Participants</div>
                    </div>
                </div>

                {/* Progress */}
                <div>
                    <div className="flex justify-between text-sm text-gray-400 mb-2">
                        <span>{lottery.soldCount}/{lottery.maxSupply} sold</span>
                        <span>{formatPercentage(progress)}</span>
                    </div>
                    <div className="w-full bg-gray-700 rounded-full h-2">
                        <motion.div
                            className="bg-gradient-to-r from-amber-400 to-orange-500 h-2 rounded-full"
                            style={{ width: `${progress}%` }}
                            initial={{ width: 0 }}
                            animate={{ width: `${progress}%` }}
                            transition={{ duration: 1, ease: "easeOut" }}
                        />
                    </div>
                </div>

                {/* Time Remaining */}
                <div className="flex items-center justify-center text-orange-400">
                    <Clock className="w-4 h-4 mr-2" />
                    <span className="font-medium">
                        {isExpired ? 'Expired' : `${timeRemaining} remaining`}
                    </span>
                </div>

                {/* Action Button */}
                <div className="flex space-x-2">
                    <Button
                        variant="outline"
                        size="sm"
                        onClick={() => window.open(`https://suiexplorer.com/object/${lottery.id}`, '_blank')}
                        className="flex-1 border-white/20 text-white hover:bg-white/10"
                    >
                        <ExternalLink className="w-4 h-4 mr-2" />
                        View Details
                    </Button>

                    {lottery.state === 0 && !isExpired && (
                        <Button
                            onClick={() => setIsBuyModalOpen(true)}
                            disabled={progress >= 100}
                            className="flex-2 bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white disabled:from-gray-500 disabled:to-gray-600"
                        >
                            {progress >= 100 ? 'Sold Out' : 'Buy WonkaBars'}
                        </Button>
                    )}
                </div>
            </div>

            <BuyWonkaBarsModal
                isOpen={isBuyModalOpen}
                onClose={() => setIsBuyModalOpen(false)}
                lottery={lottery}
            />
        </motion.div>
    )
}