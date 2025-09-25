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
            <div className="absolute inset-0 bg-gradient-to-br from-background via-muted/50 to-background" />

            {/* Animated gradient overlay */}
            <div className="absolute inset-0 bg-gradient-to-br from-melty-chocolate-50/20 via-melty-gold-50/10 to-melty-purple-50/20 animate-pulse-glow" />

            {/* Grid pattern */}
            <div
              className="absolute inset-0 opacity-[0.02] dark:opacity-[0.05]"
              style={{
                backgroundImage: `
                  radial-gradient(circle at 1px 1px, hsl(var(--foreground)) 1px, transparent 0)
                `,
                backgroundSize: '24px 24px'
              }}
            />

            {/* Floating particles */}
            <div className="absolute top-1/4 left-1/4 w-2 h-2 bg-melty-gold-400/30 rounded-full animate-float" />
            <div className="absolute top-3/4 right-1/4 w-1 h-1 bg-melty-purple-400/40 rounded-full animate-float delay-1000" />
            <div className="absolute bottom-1/3 left-1/3 w-1.5 h-1.5 bg-melty-chocolate-400/30 rounded-full animate-float delay-2000" />
          </div>

          {/* Main Content */}
          <div className="relative min-h-screen flex flex-col">
            {/* Skip to main content for accessibility */}
            <a
              href="#main-content"
              className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 z-50 px-4 py-2 bg-primary text-primary-foreground rounded-md"
            >
              Skip to main content
            </a>

            {/* Page content */}
            <main id="main-content" className="flex-1">
              {children}
            </main>

            {/* Footer placeholder - you can add your footer component here */}
            <footer className="border-t bg-card/50 backdrop-blur-sm">
              <div className="container py-8">
                <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
                  <div className="space-y-4">
                    <h3 className="melty-heading-4 text-primary">MeltyFi</h3>
                    <p className="melty-body-small text-muted-foreground">
                      Making the illiquid liquid through innovative NFT-collateralized lending.
                    </p>
                  </div>

                  <div className="space-y-4">
                    <h4 className="font-semibold">Protocol</h4>
                    <nav className="space-y-2">
                      <a href="/lotteries" className="block melty-body-small text-muted-foreground hover:text-primary transition-colors">
                        Lotteries
                      </a>
                      <a href="/docs" className="block melty-body-small text-muted-foreground hover:text-primary transition-colors">
                        Documentation
                      </a>
                    </nav>
                  </div>

                  <div className="space-y-4">
                    <h4 className="font-semibold">Community</h4>
                    <nav className="space-y-2">
                      <a href="https://github.com/VincenzoImp/MeltyFi" className="block melty-body-small text-muted-foreground hover:text-primary transition-colors">
                        GitHub
                      </a>
                      <a href="#" className="block melty-body-small text-muted-foreground hover:text-primary transition-colors">
                        Discord
                      </a>
                    </nav>
                  </div>

                  <div className="space-y-4">
                    <h4 className="font-semibold">Legal</h4>
                    <nav className="space-y-2">
                      <a href="/privacy" className="block melty-body-small text-muted-foreground hover:text-primary transition-colors">
                        Privacy Policy
                      </a>
                      <a href="/terms" className="block melty-body-small text-muted-foreground hover:text-primary transition-colors">
                        Terms of Service
                      </a>
                    </nav>
                  </div>
                </div>

                <div className="mt-8 pt-8 border-t border-border/50">
                  <div className="flex flex-col sm:flex-row justify-between items-center space-y-4 sm:space-y-0">
                    <p className="melty-body-small text-muted-foreground">
                      © {new Date().getFullYear()} MeltyFi. All rights reserved.
                    </p>
                    <div className="flex items-center space-x-4">
                      <span className="melty-body-small text-muted-foreground">
                        Powered by Sui
                      </span>
                      <div className="w-2 h-2 bg-success rounded-full animate-pulse" title="Network Status: Connected" />
                    </div>
                  </div>
                </div>
              </div>
            </footer>
          </div>
        </Providers>
      </body>
    </html>
  )
}