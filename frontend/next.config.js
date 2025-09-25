/** @type {import('next').NextConfig} */
const nextConfig = {
  // Remove turbopack for now as it may be causing issues
  experimental: {
    // Remove optimizeCss as it requires critters package
    // optimizeCss: true,
  },
  webpack: (config, { isServer }) => {
    // Ensure proper CSS handling
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
      };
    }
    return config;
  },
  // Add transpile packages if needed
  transpilePackages: [
    '@mysten/dapp-kit',
    '@mysten/sui',
    '@mysten/wallet-kit'
  ],
};

module.exports = nextConfig;