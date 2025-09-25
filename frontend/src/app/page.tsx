'use client';

import { LotteryCard } from '@/components/lottery/LotteryCard';
import { Button } from '@/components/ui/button';
import { WalletConnection } from '@/components/wallet/WalletConnection';
import { Plus, Sparkles } from 'lucide-react';
import { useState } from 'react';

// Mock data for development
const mockLotteries = [
  {
    id: '1',
    nftImage: 'https://via.placeholder.com/300x300/8B5CF6/FFFFFF?text=CryptoPunk',
    nftName: 'CryptoPunk #1234',
    ticketPrice: 100000000, // 0.1 SUI in MIST
    maxTickets: 100,
    soldTickets: 45,
    expirationDate: Date.now() + 24 * 60 * 60 * 1000, // 24 hours
    state: 'active' as const,
  },
  {
    id: '2',
    nftImage: 'https://via.placeholder.com/300x300/F59E0B/FFFFFF?text=Bored+Ape',
    nftName: 'Bored Ape #5678',
    ticketPrice: 250000000, // 0.25 SUI in MIST
    maxTickets: 200,
    soldTickets: 150,
    expirationDate: Date.now() + 48 * 60 * 60 * 1000, // 48 hours
    state: 'active' as const,
  },
  {
    id: '3',
    nftImage: 'https://via.placeholder.com/300x300/10B981/FFFFFF?text=Azuki',
    nftName: 'Azuki #9999',
    ticketPrice: 500000000, // 0.5 SUI in MIST
    maxTickets: 50,
    soldTickets: 50,
    expirationDate: Date.now() - 60 * 60 * 1000, // 1 hour ago
    state: 'concluded' as const,
    winner: '0x742d35Cc6635C0532925a3b8D31d3d69a28F9B2C',
  },
];

export default function HomePage() {
  const [lotteries, setLotteries] = useState(mockLotteries);

  const handleBuyTickets = async (lotteryId: string, quantity: number) => {
    // TODO: Implement actual ticket purchasing logic
    console.log(`Buying ${quantity} tickets for lottery ${lotteryId}`);

    // Mock implementation
    await new Promise(resolve => setTimeout(resolve, 2000));

    setLotteries(prev =>
      prev.map(lottery =>
        lottery.id === lotteryId
          ? { ...lottery, soldTickets: lottery.soldTickets + quantity }
          : lottery
      )
    );
  };

  return (
    <div className="min-h-screen">
      {/* Header */}
      <header className="border-b border-white/10 backdrop-blur-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-2 text-2xl font-bold bg-gradient-to-r from-yellow-400 to-orange-500 bg-clip-text text-transparent">
                <Sparkles className="h-8 w-8 text-yellow-400" />
                MeltyFi
              </div>
              <div className="hidden sm:block text-sm text-muted-foreground">
                Making the illiquid liquid
              </div>
            </div>
            <WalletConnection />
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="py-16 text-center">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <h1 className="text-4xl sm:text-6xl font-bold bg-gradient-to-r from-purple-400 via-pink-400 to-yellow-400 bg-clip-text text-transparent mb-6">
            Welcome to the Chocolate Factory of DeFi
          </h1>
          <p className="text-xl text-muted-foreground mb-8 max-w-2xl mx-auto">
            Unlock the value of your NFTs through innovative lottery mechanics.
            Win amazing NFT prizes or earn ChocoChip rewards!
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" className="text-lg">
              <Plus className="mr-2 h-5 w-5" />
              Create Lottery
            </Button>
            <Button size="lg" variant="outline" className="text-lg">
              Learn More
            </Button>
          </div>
        </div>
      </section>

      {/* Active Lotteries */}
      <section className="py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold mb-4">Active Lotteries</h2>
            <p className="text-muted-foreground">
              Participate in ongoing lotteries and win amazing NFT prizes!
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {lotteries.map((lottery) => (
              <LotteryCard
                key={lottery.id}
                lottery={lottery}
                onBuyTickets={handleBuyTickets}
              />
            ))}
          </div>

          {lotteries.length === 0 && (
            <div className="text-center py-12">
              <p className="text-muted-foreground text-lg">
                No active lotteries at the moment. Check back soon!
              </p>
            </div>
          )}
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-white/10 py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center text-muted-foreground">
            <p>&copy; 2024 MeltyFi Protocol. Making the illiquid liquid. 🍫</p>
          </div>
        </div>
      </footer>
    </div>
  );
}