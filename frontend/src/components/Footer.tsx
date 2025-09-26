'use client'

import { Github, Sparkles } from "lucide-react"
import Link from "next/link"

export function Footer() {
    return (
        <footer className="border-t border-border bg-background">
            <div className="container mx-auto px-6 py-12">
                <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
                    {/* Logo and Description */}
                    <div className="md:col-span-2">
                        <div className="flex items-center space-x-3 mb-4">
                            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-amber-400 to-orange-500 flex items-center justify-center">
                                <Sparkles className="w-5 h-5 text-white" />
                            </div>
                            <span className="text-xl font-bold bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
                                MeltyFi
                            </span>
                        </div>
                        <p className="text-muted-foreground max-w-md leading-relaxed">
                            The sweetest way to unlock liquidity from your NFTs on Sui blockchain.
                            Making the illiquid liquid, one lottery at a time.
                        </p>
                        <div className="mt-6 flex items-center space-x-4">
                            <Link
                                href="https://twitter.com/meltyfi"
                                target="_blank"
                                className="text-muted-foreground hover:text-foreground transition-colors"
                            >
                                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z" />
                                </svg>
                            </Link>
                            <Link
                                href="https://discord.gg/meltyfi"
                                target="_blank"
                                className="text-muted-foreground hover:text-foreground transition-colors"
                            >
                                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M20.317 4.37a19.791 19.791 0 00-4.885-1.515.074.074 0 00-.079.037c-.211.375-.445.864-.608 1.25a18.27 18.27 0 00-5.487 0 12.64 12.64 0 00-.617-1.25.077.077 0 00-.079-.037A19.736 19.736 0 003.677 4.37a.07.07 0 00-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 00.031.057 19.9 19.9 0 005.993 3.03.078.078 0 00.084-.028c.462-.63.874-1.295 1.226-1.994a.076.076 0 00-.041-.106 13.107 13.107 0 01-1.872-.892.077.077 0 01-.008-.128 10.2 10.2 0 00.372-.292.074.074 0 01.077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 01.078.01c.12.098.246.198.373.292a.077.077 0 01-.006.127 12.299 12.299 0 01-1.873.892.077.077 0 00-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 00.084.028 19.839 19.839 0 006.002-3.03.077.077 0 00.032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 00-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z" />
                                </svg>
                            </Link>
                            <Link
                                href="https://github.com/VincenzoImp/MeltyFi"
                                target="_blank"
                                className="text-muted-foreground hover:text-foreground transition-colors"
                            >
                                <Github className="w-5 h-5" />
                            </Link>
                        </div>
                    </div>

                    {/* Quick Links */}
                    <div>
                        <h3 className="font-semibold mb-4">Quick Links</h3>
                        <div className="space-y-2">
                            <Link href="/" className="block text-muted-foreground hover:text-foreground transition-colors">
                                Home
                            </Link>
                            <Link href="/lotteries" className="block text-muted-foreground hover:text-foreground transition-colors">
                                Browse Lotteries
                            </Link>
                            <Link href="/profile" className="block text-muted-foreground hover:text-foreground transition-colors">
                                Profile
                            </Link>
                            <Link href="https://docs.meltyfi.com" target="_blank" className="block text-muted-foreground hover:text-foreground transition-colors">
                                Documentation
                            </Link>
                        </div>
                    </div>

                    {/* Legal */}
                    <div>
                        <h3 className="font-semibold mb-4">Legal</h3>
                        <div className="space-y-2">
                            <Link href="/privacy" className="block text-muted-foreground hover:text-foreground transition-colors">
                                Privacy Policy
                            </Link>
                            <Link href="/terms" className="block text-muted-foreground hover:text-foreground transition-colors">
                                Terms of Service
                            </Link>
                            <Link href="/security" className="block text-muted-foreground hover:text-foreground transition-colors">
                                Security
                            </Link>
                            <Link href="/contact" className="block text-muted-foreground hover:text-foreground transition-colors">
                                Contact Us
                            </Link>
                        </div>
                    </div>
                </div>

                {/* Bottom Section */}
                <div className="mt-12 pt-8 border-t border-border flex flex-col md:flex-row items-center justify-between">
                    <div className="text-muted-foreground text-sm">
                        &copy; 2025 MeltyFi Protocol. Making the illiquid liquid.
                    </div>
                    <div className="mt-4 md:mt-0 flex items-center space-x-6 text-sm">
                        <div className="flex items-center space-x-2">
                            <div className="w-2 h-2 rounded-full bg-green-500"></div>
                            <span className="text-muted-foreground">Sui Network</span>
                        </div>
                        <div className="text-muted-foreground">
                            Built with ❤️ for the Sui ecosystem
                        </div>
                    </div>
                </div>
            </div>
        </footer>
    )
}