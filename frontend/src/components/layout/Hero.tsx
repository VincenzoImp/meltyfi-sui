// src/components/layout/Hero.tsx
'use client'

import { Button } from '@/components/ui/button'
import { useCurrentAccount } from '@mysten/dapp-kit'
import { motion } from 'framer-motion'
import {
    ArrowRight,
    ChevronDown,
    Shield,
    Sparkles,
    Trophy,
    Zap
} from 'lucide-react'
import Link from 'next/link'
import { useEffect, useState } from 'react'

export function Hero() {
    const currentAccount = useCurrentAccount()
    const [isVisible, setIsVisible] = useState(false)

    useEffect(() => {
        setIsVisible(true)
    }, [])

    const scrollToHowItWorks = () => {
        document.getElementById('how-it-works')?.scrollIntoView({
            behavior: 'smooth'
        })
    }

    const features = [
        {
            icon: Shield,
            title: "Zero Liquidation Risk",
            description: "NFTs are never forcibly liquidated due to price fluctuations"
        },
        {
            icon: Trophy,
            title: "Win-Win Design",
            description: "Benefits for both borrowers and lenders through lottery mechanics"
        },
        {
            icon: Zap,
            title: "Instant Funding",
            description: "Get liquidity immediately when lenders buy your WonkaBars"
        }
    ]

    return (
        <section className="relative overflow-hidden py-20 lg:py-32">
            {/* Animated Background Elements */}
            <div className="absolute inset-0">
                <div className="absolute top-1/4 left-1/4 w-64 h-64 bg-gradient-to-r from-amber-400/20 to-orange-500/20 rounded-full blur-3xl animate-pulse" />
                <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-gradient-to-r from-purple-400/20 to-pink-500/20 rounded-full blur-3xl animate-pulse delay-1000" />
                <div className="absolute top-3/4 left-1/2 w-48 h-48 bg-gradient-to-r from-blue-400/20 to-indigo-500/20 rounded-full blur-2xl animate-bounce" style={{ animationDuration: '3s' }} />
            </div>

            <div className="relative container mx-auto px-4 sm:px-6 lg:px-8">
                <div className="max-w-4xl mx-auto text-center">
                    {/* Main Heading */}
                    <motion.div
                        initial={{ opacity: 0, y: 30 }}
                        animate={{ opacity: isVisible ? 1 : 0, y: isVisible ? 0 : 30 }}
                        transition={{ duration: 0.8 }}
                        className="space-y-6"
                    >
                        <div className="inline-flex items-center px-4 py-2 rounded-full bg-gradient-to-r from-amber-400/20 to-orange-500/20 border border-amber-300/30 text-amber-300 text-sm font-medium">
                            <Sparkles className="w-4 h-4 mr-2" />
                            Now on Sui Blockchain
                        </div>

                        <h1 className="text-4xl sm:text-6xl lg:text-7xl font-bold tracking-tight">
                            <span className="block text-white">Making the</span>
                            <span className="block bg-gradient-to-r from-amber-300 via-orange-400 to-amber-500 bg-clip-text text-transparent">
                                Illiquid Liquid
                            </span>
                        </h1>

                        <p className="text-xl sm:text-2xl text-gray-300 max-w-3xl mx-auto leading-relaxed">
                            NFT-collateralized lending through <strong className="text-amber-300">lottery mechanics</strong>
                            {' '}inspired by Charlie's chocolate factory. Break your NFT into WonkaBars,
                            fund your needs, and let the golden ticket decide the winner!
                        </p>
                    </motion.div>

                    {/* Call to Action Buttons */}
                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: isVisible ? 1 : 0, y: isVisible ? 0 : 20 }}
                        transition={{ duration: 0.8, delay: 0.2 }}
                        className="flex flex-col sm:flex-row gap-4 justify-center items-center mt-10"
                    >
                        <Link href="/lotteries">
                            <Button size="lg" className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white font-semibold px-8 py-3 rounded-full shadow-lg hover:shadow-xl transform hover:scale-105 transition-all duration-200">
                                Start Lending
                                <ArrowRight className="ml-2 h-5 w-5" />
                            </Button>
                        </Link>

                        {currentAccount ? (
                            <Link href="/profile">
                                <Button variant="outline" size="lg" className="border-amber-300/50 text-amber-300 hover:bg-amber-300/10 px-8 py-3 rounded-full">
                                    View Profile
                                </Button>
                            </Link>
                        ) : (
                            <Button variant="outline" size="lg" className="border-amber-300/50 text-amber-300 hover:bg-amber-300/10 px-8 py-3 rounded-full">
                                Connect Wallet First
                            </Button>
                        )}
                    </motion.div>

                    {/* Key Features */}
                    <motion.div
                        initial={{ opacity: 0, y: 30 }}
                        animate={{ opacity: isVisible ? 1 : 0, y: isVisible ? 0 : 30 }}
                        transition={{ duration: 0.8, delay: 0.4 }}
                        className="grid md:grid-cols-3 gap-8 mt-20"
                    >
                        {features.map((feature, index) => {
                            const Icon = feature.icon
                            return (
                                <div
                                    key={index}
                                    className="group p-6 rounded-2xl bg-white/5 backdrop-blur-sm border border-white/10 hover:border-amber-300/30 transition-all duration-300 hover:bg-white/10"
                                >
                                    <div className="flex flex-col items-center text-center space-y-4">
                                        <div className="p-3 rounded-full bg-gradient-to-r from-amber-400/20 to-orange-500/20 group-hover:from-amber-400/30 group-hover:to-orange-500/30 transition-colors">
                                            <Icon className="h-8 w-8 text-amber-300" />
                                        </div>
                                        <h3 className="text-xl font-semibold text-white">
                                            {feature.title}
                                        </h3>
                                        <p className="text-gray-400 leading-relaxed">
                                            {feature.description}
                                        </p>
                                    </div>
                                </div>
                            )
                        })}
                    </motion.div>

                    {/* Scroll indicator */}
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: isVisible ? 1 : 0 }}
                        transition={{ duration: 1, delay: 0.8 }}
                        className="mt-16"
                    >
                        <button
                            onClick={scrollToHowItWorks}
                            className="flex flex-col items-center space-y-2 text-gray-400 hover:text-amber-300 transition-colors group"
                        >
                            <span className="text-sm">Learn How It Works</span>
                            <ChevronDown className="h-6 w-6 animate-bounce group-hover:text-amber-300" />
                        </button>
                    </motion.div>
                </div>
            </div>
        </section>
    )
}