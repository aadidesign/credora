const path = require('path');

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  transpilePackages: ['@credora/sdk'],
  webpack: (config) => {
    config.externals.push('pino-pretty', 'encoding');
    config.resolve.alias = {
      ...config.resolve.alias,
      '@react-native-async-storage/async-storage': path.resolve(__dirname, 'src/lib/empty-module.js'),
    };
    return config;
  },
};

module.exports = nextConfig;
