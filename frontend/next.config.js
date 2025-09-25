/** @type {import('next').NextConfig} */
const nextConfig = {
  turbopack: {
    root: '/Users/vincenzo/Documents/GitHub/meltyfi-sui',
  },
  experimental: {
    // Ensure CSS is processed correctly
    optimizeCss: true,
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
};

module.exports = nextConfig;