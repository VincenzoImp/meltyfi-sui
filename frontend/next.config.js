/** @type {import('next').NextConfig} */
const nextConfig = {
  // Configure Turbopack root to silence workspace warnings
  turbopack: {
    root: __dirname,
  },

  // Remove experimental features causing warnings
  experimental: {
    // Remove optimizeCss and other experimental features for now
    turbo: {
      rules: {
        '*.svg': {
          loaders: ['@svgr/webpack'],
          as: '*.js',
        },
      },
    },
  },

  // Webpack configuration for fallbacks
  webpack: (config, { isServer, dev }) => {
    // Ensure proper CSS handling
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

  // Add transpile packages for better compatibility
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

  // Enable SWC minification
  swcMinify: true,

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
};

module.exports = nextConfig;