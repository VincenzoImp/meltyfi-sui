import { Providers } from '@/components/providers/Providers'
import type { Metadata } from 'next'
import { Inter, JetBrains_Mono } from 'next/font/google'
import './globals.css'

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter'
})

const jetBrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-jetbrains'
})

export const metadata: Metadata = {
  title: {
    default: 'MeltyFi - Making the Illiquid Liquid',
    template: '%s | MeltyFi'
  },
  description: 'NFT-collateralized lending through lottery mechanics on Sui blockchain. Where Charlie\'s chocolate factory meets DeFi innovation.',
  keywords: [
    'DeFi',
    'NFT',
    'Sui',
    'Lottery',
    'Lending',
    'Blockchain',
    'Smart Contracts',
    'Web3',
    'Cryptocurrency',
    'Digital Assets'
  ],
  authors: [{ name: 'MeltyFi Team', url: 'https://meltyfi.com' }],
  creator: 'MeltyFi Team',
  metadataBase: new URL('https://meltyfi.com'),
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://meltyfi.com',
    title: 'MeltyFi Protocol',
    description: 'NFT-collateralized lending through lottery mechanics on Sui blockchain',
    siteName: 'MeltyFi',
    images: [
      {
        url: '/images/meltyfi-og.png',
        width: 1200,
        height: 630,
        alt: 'MeltyFi Protocol - Making the Illiquid Liquid',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'MeltyFi Protocol',
    description: 'Where Charlie\'s chocolate factory meets DeFi innovation!',
    images: ['/images/meltyfi-twitter.png'],
    creator: '@MeltyFi',
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  icons: {
    icon: [
      { url: '/favicon.ico' },
      { url: '/favicon-16x16.png', sizes: '16x16', type: 'image/png' },
      { url: '/favicon-32x32.png', sizes: '32x32', type: 'image/png' },
    ],
    apple: [
      { url: '/apple-touch-icon.png', sizes: '180x180', type: 'image/png' },
    ],
  },
  manifest: '/site.webmanifest',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={`${inter.variable} ${jetBrainsMono.variable}`}
    >
      <body className="font-sans antialiased">
        <Providers>
          {/* Background Pattern */}
          <div className="fixed inset-0 -z-50">
            {/* Base gradient */}
            <div className="absolute inset-0 bg-gradient-to-br from-background via-background to-muted/20" />

            {/* Subtle pattern overlay */}
            <div
              className="absolute inset-0 opacity-[0.015] dark:opacity-[0.02]"
              style={{
                backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23000000' fill-opacity='1'%3E%3Ccircle cx='30' cy='30' r='1'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
              }}
            />

            {/* Ambient light effects */}
            <div className="absolute top-0 left-1/4 w-96 h-96 bg-primary/5 rounded-full blur-3xl" />
            <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-purple-500/5 rounded-full blur-3xl" />
          </div>

          {/* Main App Content */}
          <div className="relative min-h-screen flex flex-col">
            {children}
          </div>
        </Providers>
      </body>
    </html>
  )
}