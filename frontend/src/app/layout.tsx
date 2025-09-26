import { Footer } from '@/components/Footer'
import { Navigation } from '@/components/Navigation'
import { Providers } from '@/components/providers/Providers'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'MeltyFi - Making the Illiquid Liquid',
  description: 'The sweetest way to unlock liquidity from your NFTs on Sui blockchain. Create lotteries, fund loans, and everyone wins with our innovative chocolate factory-inspired DeFi protocol.',
  keywords: ['NFT', 'DeFi', 'Sui', 'Lottery', 'Liquidity', 'Blockchain'],
  authors: [{ name: 'MeltyFi Team' }],
  creator: 'MeltyFi',
  publisher: 'MeltyFi',
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <Providers>
          <div className="min-h-screen bg-background flex flex-col">
            <Navigation />
            <main className="flex-1">
              {children}
            </main>
            <Footer />
          </div>
        </Providers>
      </body>
    </html>
  )
}