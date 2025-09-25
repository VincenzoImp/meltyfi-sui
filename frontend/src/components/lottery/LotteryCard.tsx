'use client';

import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { formatSui, timeUntilExpiration } from '@/lib/utils';
import { Clock, Coins, Trophy, Users } from 'lucide-react';
import { useState } from 'react';

interface LotteryCardProps {
    lottery: {
        id: string;
        nftImage: string;
        nftName: string;
        ticketPrice: number;
        maxTickets: number;
        soldTickets: number;
        expirationDate: number;
        state: 'active' | 'concluded' | 'cancelled';
        winner?: string;
    };
    onBuyTickets?: (lotteryId: string, quantity: number) => Promise<void>;
}

export function LotteryCard({ lottery, onBuyTickets }: LotteryCardProps) {
    const [quantity, setQuantity] = useState(1);
    const [isLoading, setIsLoading] = useState(false);

    const handleBuyTickets = async () => {
        if (!onBuyTickets) return;

        setIsLoading(true);
        try {
            await onBuyTickets(lottery.id, quantity);
        } catch (error) {
            console.error('Failed to buy tickets:', error);
        } finally {
            setIsLoading(false);
        }
    };

    const progressPercentage = (lottery.soldTickets / lottery.maxTickets) * 100;
    const isExpired = lottery.expirationDate < Date.now();
    const canPurchase = lottery.state === 'active' && !isExpired;

    return (
        <Card className="overflow-hidden">
            <div className="aspect-square relative">
                <img
                    src={lottery.nftImage}
                    alt={lottery.nftName}
                    className="w-full h-full object-cover"
                />
                <Badge
                    className="absolute top-2 right-2"
                    variant={
                        lottery.state === 'active' ? 'default' :
                            lottery.state === 'concluded' ? 'secondary' : 'destructive'
                    }
                >
                    {lottery.state.toUpperCase()}
                </Badge>
            </div>

            <CardHeader>
                <CardTitle className="text-lg">{lottery.nftName}</CardTitle>
                <div className="flex items-center gap-4 text-sm text-muted-foreground">
                    <div className="flex items-center gap-1">
                        <Coins className="h-4 w-4" />
                        {formatSui(lottery.ticketPrice)} SUI
                    </div>
                    <div className="flex items-center gap-1">
                        <Users className="h-4 w-4" />
                        {lottery.soldTickets}/{lottery.maxTickets}
                    </div>
                </div>
            </CardHeader>

            <CardContent className="space-y-4">
                {/* Progress Bar */}
                <div className="space-y-2">
                    <div className="flex justify-between text-sm">
                        <span>Progress</span>
                        <span>{progressPercentage.toFixed(1)}%</span>
                    </div>
                    <div className="w-full bg-secondary rounded-full h-2">
                        <div
                            className="bg-primary h-2 rounded-full transition-all"
                            style={{ width: `${progressPercentage}%` }}
                        />
                    </div>
                </div>

                {/* Timer */}
                <div className="flex items-center gap-2 text-sm">
                    <Clock className="h-4 w-4" />
                    <span>
                        {isExpired ? 'Expired' : timeUntilExpiration(lottery.expirationDate)}
                    </span>
                </div>

                {/* Winner Display */}
                {lottery.state === 'concluded' && lottery.winner && (
                    <div className="flex items-center gap-2 text-sm bg-yellow-50 dark:bg-yellow-900/20 p-2 rounded">
                        <Trophy className="h-4 w-4 text-yellow-600" />
                        <span>Winner: {lottery.winner.slice(0, 6)}...{lottery.winner.slice(-4)}</span>
                    </div>
                )}
            </CardContent>

            <CardFooter>
                {canPurchase && (
                    <div className="w-full space-y-3">
                        <div className="flex items-center gap-2">
                            <input
                                type="number"
                                min="1"
                                max={Math.min(10, lottery.maxTickets - lottery.soldTickets)}
                                value={quantity}
                                onChange={(e) => setQuantity(Number(e.target.value))}
                                className="flex-1 px-3 py-2 border rounded-md"
                            />
                            <Button
                                onClick={handleBuyTickets}
                                disabled={isLoading}
                                className="flex-1"
                            >
                                {isLoading ? 'Buying...' : `Buy ${quantity} Ticket${quantity > 1 ? 's' : ''}`}
                            </Button>
                        </div>
                        <div className="text-xs text-center text-muted-foreground">
                            Total: {formatSui(lottery.ticketPrice * quantity)} SUI
                        </div>
                    </div>
                )}

                {lottery.state === 'active' && isExpired && (
                    <Button variant="outline" disabled className="w-full">
                        Lottery Expired
                    </Button>
                )}

                {lottery.state === 'concluded' && (
                    <Button variant="secondary" disabled className="w-full">
                        Lottery Concluded
                    </Button>
                )}

                {lottery.state === 'cancelled' && (
                    <Button variant="destructive" disabled className="w-full">
                        Lottery Cancelled
                    </Button>
                )}
            </CardFooter>
        </Card>
    );
}