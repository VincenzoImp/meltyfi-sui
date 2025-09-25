// src/app/layout.tsx
import { Providers } from '@/components/providers/Providers'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'MeltyFi - Making the Illiquid Liquid',
  description: 'NFT-collateralized lending through lottery mechanics on Sui blockchain',
  keywords: ['DeFi', 'NFT', 'Sui', 'Lottery', 'Lending', 'Blockchain'],
  authors: [{ name: 'MeltyFi Team' }],
  openGraph: {
    title: 'MeltyFi Protocol',
    description: 'Where Charlie\'s chocolate factory meets DeFi innovation!',
    images: ['/images/meltyfi-og.png'],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'MeltyFi Protocol',
    description: 'NFT-collateralized lending through lottery mechanics',
    images: ['/images/meltyfi-twitter.png'],
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
          <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900">
            <div className="min-h-screen bg-gradient-to-br from-amber-50/10 to-orange-100/10 backdrop-blur-sm">
              {children}
            </div>
          </div>
        </Providers>
      </body>
    </html>
  )
}