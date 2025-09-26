/** @type {import('next').NextConfig} */
const nextConfig = {
  // Configure Turbopack properly for Next.js 15
  turbopack: {
    root: __dirname,
  },

  // Webpack configuration for fallbacks
  webpack: (config, { isServer }) => {
    // Ensure proper fallbacks for browser environment
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
        crypto: false,
      };
    }

    // Handle SVG imports
    config.module.rules.push({
      test: /\.svg$/,
      use: ['@svgr/webpack'],
    });

    return config;
  },

  // Transpile packages for better compatibility
  transpilePackages: [
    '@mysten/dapp-kit',
    '@mysten/sui',
    '@mysten/wallet-kit',
    '@tanstack/react-query'
  ],

  // Image optimization
  images: {
    domains: ['images.unsplash.com', 'ipfs.io'],
    formats: ['image/webp', 'image/avif'],
  },

  // Optimize build output
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },

  // Headers for security
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'origin-when-cross-origin',
          },
        ],
      },
    ];
  },

  // Environment variables
  env: {
    CUSTOM_KEY: process.env.CUSTOM_KEY,
  },
};

module.exports = nextConfig;