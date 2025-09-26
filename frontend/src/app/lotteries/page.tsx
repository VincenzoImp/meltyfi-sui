'use client'

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import {
    Clock,
    Coins,
    ExternalLink,
    Image as ImageIcon,
    Plus,
    Search,
    Sparkles,
    TrendingUp,
    Trophy,
    Zap
} from "lucide-react"
import Image from "next/image"
import { useEffect, useState } from "react"

// Mock data for lotteries
const mockLotteries = [
    {
        id: 1,
        title: "Rare CryptoPunk #1234",
        collection: "CryptoPunks",
        image: "https://images.unsplash.com/photo-1620641788421-7a1c342ea42e?w=400",
        tokenId: "1234",
        creator: "0x742d...3892",
        expirationDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000), // 5 days
        wonkaBarPrice: 0.1,
        wonkaBarsSold: 45,
        wonkaBarsMaxSupply: 100,
        totalRaised: 4.5,
        status: "active",
        rarity: "legendary"
    },
    {
        id: 2,
        title: "Cool Ape #5678",
        collection: "Bored Ape Yacht Club",
        image: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400",
        tokenId: "5678",
        creator: "0x891a...7362",
        expirationDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000), // 2 days
        wonkaBarPrice: 0.05,
        wonkaBarsSold: 87,
        wonkaBarsMaxSupply: 150,
        totalRaised: 4.35,
        status: "active",
        rarity: "rare"
    },
    {
        id: 3,
        title: "Abstract Art #999",
        collection: "Art Blocks",
        image: "https://images.unsplash.com/photo-1634193295627-1cdddf751ebf?w=400",
        tokenId: "999",
        creator: "0x234b...1098",
        expirationDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
        wonkaBarPrice: 0.02,
        wonkaBarsSold: 23,
        wonkaBarsMaxSupply: 80,
        totalRaised: 0.46,
        status: "active",
        rarity: "common"
    }
]

// Mock data for user's NFTs
const mockUserNFTs = [
    {
        id: 1,
        title: "My Digital Dragon #777",
        collection: "Digital Dragons",
        image: "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400",
        tokenId: "777",
        contractAddress: "0x123...456"
    },
    {
        id: 2,
        title: "Space Explorer #1122",
        collection: "Space Explorers",
        image: "https://images.unsplash.com/photo-1446776653964-20c1d3a81b06?w=400",
        tokenId: "1122",
        contractAddress: "0x789...012"
    }
]

interface LotteryCardProps {
    lottery: typeof mockLotteries[0]
}

function LotteryCard({ lottery }: LotteryCardProps) {
    const progressPercentage = (lottery.wonkaBarsSold / lottery.wonkaBarsMaxSupply) * 100
    const timeLeft = lottery.expirationDate.getTime() - Date.now()
    const daysLeft = Math.ceil(timeLeft / (1000 * 60 * 60 * 24))

    const getRarityColor = (rarity: string) => {
        switch (rarity) {
            case 'legendary': return 'bg-amber-500'
            case 'rare': return 'bg-purple-500'
            case 'common': return 'bg-blue-500'
            default: return 'bg-gray-500'
        }
    }

    return (
        <Card className="group hover:shadow-xl transition-all duration-300 overflow-hidden border-white/10 bg-white/5 backdrop-blur-sm">
            <div className="relative">
                <div className="aspect-square relative overflow-hidden">
                    <Image
                        src={lottery.image}
                        alt={lottery.title}
                        fill
                        className="object-cover group-hover:scale-105 transition-transform duration-300"
                    />
                    <div className="absolute top-4 left-4">
                        <Badge className={`${getRarityColor(lottery.rarity)} text-white capitalize`}>
                            {lottery.rarity}
                        </Badge>
                    </div>
                    <div className="absolute top-4 right-4">
                        <Badge variant="secondary" className="bg-black/50 text-white">
                            <Clock className="w-3 h-3 mr-1" />
                            {daysLeft}d left
                        </Badge>
                    </div>
                </div>
            </div>

            <CardContent className="p-6">
                <div className="space-y-4">
                    <div>
                        <h3 className="text-lg font-semibold text-white group-hover:text-purple-300 transition-colors">
                            {lottery.title}
                        </h3>
                        <p className="text-sm text-white/60">{lottery.collection} #{lottery.tokenId}</p>
                    </div>

                    <div className="space-y-2">
                        <div className="flex justify-between text-sm">
                            <span className="text-white/60">Progress</span>
                            <span className="text-white font-medium">
                                {lottery.wonkaBarsSold}/{lottery.wonkaBarsMaxSupply} WonkaBars
                            </span>
                        </div>
                        <div className="w-full bg-white/10 rounded-full h-2">
                            <div
                                className="bg-gradient-to-r from-purple-500 to-pink-500 h-2 rounded-full transition-all duration-500"
                                style={{ width: `${progressPercentage}%` }}
                            />
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4 text-sm">
                        <div>
                            <p className="text-white/60">WonkaBar Price</p>
                            <p className="text-white font-semibold">{lottery.wonkaBarPrice} SUI</p>
                        </div>
                        <div>
                            <p className="text-white/60">Total Raised</p>
                            <p className="text-white font-semibold">{lottery.totalRaised} SUI</p>
                        </div>
                    </div>

                    <div className="flex space-x-2 pt-2">
                        <Dialog>
                            <DialogTrigger asChild>
                                <Button className="flex-1 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700">
                                    <Coins className="w-4 h-4 mr-2" />
                                    Buy WonkaBars
                                </Button>
                            </DialogTrigger>
                            <DialogContent className="bg-gray-900 border-white/10">
                                <BuyWonkaBarModal lottery={lottery} />
                            </DialogContent>
                        </Dialog>
                        <Button variant="outline" size="sm" className="border-white/20 text-white hover:bg-white/10">
                            <ExternalLink className="w-4 h-4" />
                        </Button>
                    </div>
                </div>
            </CardContent>
        </Card>
    )
}

interface BuyWonkaBarModalProps {
    lottery: typeof mockLotteries[0]
}

function BuyWonkaBarModal({ lottery }: BuyWonkaBarModalProps) {
    const [quantity, setQuantity] = useState(1)
    const maxQuantity = lottery.wonkaBarsMaxSupply - lottery.wonkaBarsSold
    const totalCost = quantity * lottery.wonkaBarPrice

    return (
        <>
            <DialogHeader>
                <DialogTitle className="text-white">Buy WonkaBars</DialogTitle>
                <DialogDescription className="text-white/60">
                    Purchase WonkaBars for {lottery.title} and join the lottery!
                </DialogDescription>
            </DialogHeader>

            <div className="space-y-6">
                <div className="flex items-center space-x-4">
                    <div className="relative w-20 h-20 rounded-lg overflow-hidden">
                        <Image src={lottery.image} alt={lottery.title} fill className="object-cover" />
                    </div>
                    <div>
                        <h4 className="font-semibold text-white">{lottery.title}</h4>
                        <p className="text-sm text-white/60">{lottery.collection} #{lottery.tokenId}</p>
                    </div>
                </div>

                <div className="space-y-4">
                    <div>
                        <Label htmlFor="quantity" className="text-white">Quantity</Label>
                        <Input
                            id="quantity"
                            type="number"
                            min="1"
                            max={maxQuantity}
                            value={quantity}
                            onChange={(e) => setQuantity(Math.max(1, Math.min(maxQuantity, parseInt(e.target.value) || 1)))}
                            className="bg-white/5 border-white/10 text-white"
                        />
                        <p className="text-xs text-white/60 mt-1">
                            Max available: {maxQuantity} WonkaBars
                        </p>
                    </div>

                    <div className="bg-white/5 rounded-lg p-4 space-y-2">
                        <div className="flex justify-between">
                            <span className="text-white/60">Price per WonkaBar</span>
                            <span className="text-white">{lottery.wonkaBarPrice} SUI</span>
                        </div>
                        <div className="flex justify-between">
                            <span className="text-white/60">Quantity</span>
                            <span className="text-white">{quantity}</span>
                        </div>
                        <div className="border-t border-white/10 pt-2 flex justify-between font-semibold">
                            <span className="text-white">Total Cost</span>
                            <span className="text-white">{totalCost.toFixed(3)} SUI</span>
                        </div>
                    </div>

                    <div className="text-sm text-white/60 space-y-1">
                        <p>• You'll have a {((quantity / lottery.wonkaBarsMaxSupply) * 100).toFixed(2)}% chance to win</p>
                        <p>• All participants receive ChocoChip rewards</p>
                        <p>• If lottery is cancelled, you get a full refund + ChocoChips</p>
                    </div>
                </div>
            </div>

            <DialogFooter>
                <Button
                    className="w-full bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700"
                    disabled={quantity < 1 || quantity > maxQuantity}
                >
                    <Coins className="w-4 h-4 mr-2" />
                    Buy {quantity} WonkaBar{quantity > 1 ? 's' : ''} for {totalCost.toFixed(3)} SUI
                </Button>
            </DialogFooter>
        </>
    )
}

interface NFTCardProps {
    nft: typeof mockUserNFTs[0]
}

function NFTCard({ nft }: NFTCardProps) {
    return (
        <Card className="group hover:shadow-xl transition-all duration-300 overflow-hidden border-white/10 bg-white/5 backdrop-blur-sm">
            <div className="aspect-square relative overflow-hidden">
                <Image
                    src={nft.image}
                    alt={nft.title}
                    fill
                    className="object-cover group-hover:scale-105 transition-transform duration-300"
                />
            </div>

            <CardContent className="p-6">
                <div className="space-y-4">
                    <div>
                        <h3 className="text-lg font-semibold text-white group-hover:text-purple-300 transition-colors">
                            {nft.title}
                        </h3>
                        <p className="text-sm text-white/60">{nft.collection} #{nft.tokenId}</p>
                    </div>

                    <Dialog>
                        <DialogTrigger asChild>
                            <Button className="w-full bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-700 hover:to-orange-700">
                                <Plus className="w-4 h-4 mr-2" />
                                Create Lottery
                            </Button>
                        </DialogTrigger>
                        <DialogContent className="bg-gray-900 border-white/10 max-w-lg">
                            <CreateLotteryModal nft={nft} />
                        </DialogContent>
                    </Dialog>
                </div>
            </CardContent>
        </Card>
    )
}

interface CreateLotteryModalProps {
    nft: typeof mockUserNFTs[0]
}

function CreateLotteryModal({ nft }: CreateLotteryModalProps) {
    const [wonkaBarPrice, setWonkaBarPrice] = useState("0.1")
    const [maxSupply, setMaxSupply] = useState("100")
    const [duration, setDuration] = useState("7")

    const totalRevenue = parseFloat(wonkaBarPrice) * parseInt(maxSupply) || 0
    const userReceives = totalRevenue * 0.95 // 95% to user, 5% protocol fee

    return (
        <>
            <DialogHeader>
                <DialogTitle className="text-white">Create Lottery</DialogTitle>
                <DialogDescription className="text-white/60">
                    Create a lottery with your NFT and set the parameters.
                </DialogDescription>
            </DialogHeader>

            <div className="space-y-6">
                <div className="flex items-center space-x-4">
                    <div className="relative w-20 h-20 rounded-lg overflow-hidden">
                        <Image src={nft.image} alt={nft.title} fill className="object-cover" />
                    </div>
                    <div>
                        <h4 className="font-semibold text-white">{nft.title}</h4>
                        <p className="text-sm text-white/60">{nft.collection} #{nft.tokenId}</p>
                    </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                    <div>
                        <Label htmlFor="wonkabar-price" className="text-white">WonkaBar Price (SUI)</Label>
                        <Input
                            id="wonkabar-price"
                            type="number"
                            step="0.01"
                            min="0.01"
                            value={wonkaBarPrice}
                            onChange={(e) => setWonkaBarPrice(e.target.value)}
                            className="bg-white/5 border-white/10 text-white"
                        />
                    </div>
                    <div>
                        <Label htmlFor="max-supply" className="text-white">Max WonkaBars</Label>
                        <Input
                            id="max-supply"
                            type="number"
                            min="5"
                            max="1000"
                            value={maxSupply}
                            onChange={(e) => setMaxSupply(e.target.value)}
                            className="bg-white/5 border-white/10 text-white"
                        />
                    </div>
                </div>

                <div>
                    <Label htmlFor="duration" className="text-white">Duration (days)</Label>
                    <Select value={duration} onValueChange={setDuration}>
                        <SelectTrigger className="bg-white/5 border-white/10 text-white">
                            <SelectValue />
                        </SelectTrigger>
                        <SelectContent className="bg-gray-900 border-white/10">
                            <SelectItem value="1">1 day</SelectItem>
                            <SelectItem value="3">3 days</SelectItem>
                            <SelectItem value="7">7 days</SelectItem>
                            <SelectItem value="14">14 days</SelectItem>
                            <SelectItem value="30">30 days</SelectItem>
                        </SelectContent>
                    </Select>
                </div>

                <div className="bg-white/5 rounded-lg p-4 space-y-2">
                    <div className="flex justify-between">
                        <span className="text-white/60">Total Possible Revenue</span>
                        <span className="text-white">{totalRevenue.toFixed(3)} SUI</span>
                    </div>
                    <div className="flex justify-between">
                        <span className="text-white/60">Protocol Fee (5%)</span>
                        <span className="text-white">{(totalRevenue * 0.05).toFixed(3)} SUI</span>
                    </div>
                    <div className="border-t border-white/10 pt-2 flex justify-between font-semibold">
                        <span className="text-white">You Receive (95%)</span>
                        <span className="text-white">{userReceives.toFixed(3)} SUI</span>
                    </div>
                </div>

                <div className="text-sm text-white/60 space-y-1">
                    <p>• You'll receive funds immediately as WonkaBars are sold</p>
                    <p>• Repay before expiration to get your NFT back + ChocoChips</p>
                    <p>• If not repaid, a random WonkaBar holder wins your NFT</p>
                </div>
            </div>

            <DialogFooter>
                <Button
                    className="w-full bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-700 hover:to-orange-700"
                >
                    <Sparkles className="w-4 h-4 mr-2" />
                    Create Lottery
                </Button>
            </DialogFooter>
        </>
    )
}

export default function LotteriesPage() {
    const [searchTerm, setSearchTerm] = useState("")
    const [sortBy, setSortBy] = useState("ending-soon")
    const [filterBy, setFilterBy] = useState("all")
    const [lotteries, setLotteries] = useState(mockLotteries)

    useEffect(() => {
        // Filter and sort lotteries based on user selections
        let filtered = mockLotteries.filter(lottery =>
            lottery.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
            lottery.collection.toLowerCase().includes(searchTerm.toLowerCase())
        )

        if (filterBy !== "all") {
            filtered = filtered.filter(lottery => lottery.rarity === filterBy)
        }

        // Sort lotteries
        filtered.sort((a, b) => {
            switch (sortBy) {
                case "ending-soon":
                    return a.expirationDate.getTime() - b.expirationDate.getTime()
                case "most-funded":
                    return b.totalRaised - a.totalRaised
                case "highest-prize":
                    return b.wonkaBarPrice - a.wonkaBarPrice
                default:
                    return 0
            }
        })

        setLotteries(filtered)
    }, [searchTerm, sortBy, filterBy])

    return (
        <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900">
            {/* Background Elements */}
            <div className="fixed inset-0 overflow-hidden pointer-events-none">
                <div className="absolute -top-1/2 -left-1/2 w-full h-full bg-gradient-radial from-purple-500/10 via-transparent to-transparent" />
                <div className="absolute -bottom-1/2 -right-1/2 w-full h-full bg-gradient-radial from-blue-500/10 via-transparent to-transparent" />
            </div>

            <div className="relative z-10 container mx-auto px-6 py-12">
                {/* Header */}
                <div className="text-center mb-12">
                    <h1 className="text-5xl font-bold mb-6 bg-gradient-to-r from-purple-400 to-pink-500 bg-clip-text text-transparent">
                        NFT Lotteries
                    </h1>
                    <p className="text-xl text-white/80 max-w-3xl mx-auto">
                        Discover exciting NFT lotteries or create your own. Turn your illiquid assets into instant liquidity!
                    </p>
                </div>

                <Tabs defaultValue="browse" className="space-y-8">
                    <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-6">
                        <TabsList className="bg-white/10 border-white/20">
                            <TabsTrigger value="browse" className="data-[state=active]:bg-purple-600">
                                <Trophy className="w-4 h-4 mr-2" />
                                Browse Lotteries
                            </TabsTrigger>
                            <TabsTrigger value="create" className="data-[state=active]:bg-amber-600">
                                <Plus className="w-4 h-4 mr-2" />
                                Create Lottery
                            </TabsTrigger>
                        </TabsList>

                        {/* Stats */}
                        <div className="flex items-center space-x-6 text-sm">
                            <div className="flex items-center space-x-2">
                                <TrendingUp className="w-4 h-4 text-green-400" />
                                <span className="text-white/60">Active Lotteries:</span>
                                <span className="text-white font-semibold">47</span>
                            </div>
                            <div className="flex items-center space-x-2">
                                <Coins className="w-4 h-4 text-amber-400" />
                                <span className="text-white/60">Total Volume:</span>
                                <span className="text-white font-semibold">2.4M SUI</span>
                            </div>
                        </div>
                    </div>

                    <TabsContent value="browse" className="space-y-6">
                        {/* Search and Filters */}
                        <div className="flex flex-col lg:flex-row gap-4">
                            <div className="relative flex-1">
                                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-white/60" />
                                <Input
                                    placeholder="Search lotteries..."
                                    value={searchTerm}
                                    onChange={(e) => setSearchTerm(e.target.value)}
                                    className="pl-10 bg-white/5 border-white/10 text-white placeholder:text-white/60"
                                />
                            </div>

                            <Select value={sortBy} onValueChange={setSortBy}>
                                <SelectTrigger className="w-48 bg-white/5 border-white/10 text-white">
                                    <SelectValue />
                                </SelectTrigger>
                                <SelectContent className="bg-gray-900 border-white/10">
                                    <SelectItem value="ending-soon">Ending Soon</SelectItem>
                                    <SelectItem value="most-funded">Most Funded</SelectItem>
                                    <SelectItem value="highest-prize">Highest Prize</SelectItem>
                                </SelectContent>
                            </Select>

                            <Select value={filterBy} onValueChange={setFilterBy}>
                                <SelectTrigger className="w-48 bg-white/5 border-white/10 text-white">
                                    <SelectValue />
                                </SelectTrigger>
                                <SelectContent className="bg-gray-900 border-white/10">
                                    <SelectItem value="all">All Rarities</SelectItem>
                                    <SelectItem value="legendary">Legendary</SelectItem>
                                    <SelectItem value="rare">Rare</SelectItem>
                                    <SelectItem value="common">Common</SelectItem>
                                </SelectContent>
                            </Select>
                        </div>

                        {/* Lottery Grid */}
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                            {lotteries.map((lottery) => (
                                <LotteryCard key={lottery.id} lottery={lottery} />
                            ))}
                        </div>

                        {lotteries.length === 0 && (
                            <div className="text-center py-12">
                                <Trophy className="w-12 h-12 text-white/40 mx-auto mb-4" />
                                <h3 className="text-lg font-semibold text-white mb-2">No lotteries found</h3>
                                <p className="text-white/60">Try adjusting your search or filters</p>
                            </div>
                        )}
                    </TabsContent>

                    <TabsContent value="create" className="space-y-6">
                        <div className="text-center mb-8">
                            <h2 className="text-3xl font-bold text-white mb-4">Create a New Lottery</h2>
                            <p className="text-white/60">
                                Select one of your NFTs below to create a lottery and unlock instant liquidity
                            </p>
                        </div>

                        {/* User's NFTs Grid */}
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                            {mockUserNFTs.map((nft) => (
                                <NFTCard key={nft.id} nft={nft} />
                            ))}
                        </div>

                        {mockUserNFTs.length === 0 && (
                            <Card className="border-white/10 bg-white/5 backdrop-blur-sm p-12 text-center">
                                <ImageIcon className="w-12 h-12 text-white/40 mx-auto mb-4" />
                                <h3 className="text-lg font-semibold text-white mb-2">No NFTs found</h3>
                                <p className="text-white/60 mb-6">
                                    Connect your Sui wallet to see your NFTs and create lotteries
                                </p>
                                <Button className="bg-gradient-to-r from-purple-600 to-pink-600">
                                    <Zap className="w-4 h-4 mr-2" />
                                    Connect Wallet
                                </Button>
                            </Card>
                        )}
                    </TabsContent>
                </Tabs>
            </div>
        </div>
    )
}