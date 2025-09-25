// next.config.ts
import { NextConfig } from 'next';
import path from 'path';

const nextConfig: NextConfig = {
  // Configure Turbopack correctly (no longer in experimental)
  turbopack: {
    root: path.resolve(__dirname),
  },

  // Handle static assets
  trailingSlash: false,

  // Transpile packages if needed (for Sui packages)
  transpilePackages: ['@mysten/sui', '@mysten/dapp-kit'],

  // Environment variables that should be available on the client side
  env: {
    NEXT_PUBLIC_SUI_NETWORK: process.env.NEXT_PUBLIC_SUI_NETWORK || 'testnet',
  },
};

export default nextConfig;