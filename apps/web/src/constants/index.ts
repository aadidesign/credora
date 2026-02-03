/**
 * @file constants/index.ts
 * @description Application-wide constants.
 */

/** Supported chain IDs for the Credora protocol */
export const SUPPORTED_CHAIN_IDS = [421614, 42161, 11155111, 31337] as const;

/** Chain ID for Arbitrum Sepolia testnet */
export const ARBITRUM_SEPOLIA_CHAIN_ID = 421614;

/** Chain ID for Arbitrum One mainnet */
export const ARBITRUM_ONE_CHAIN_ID = 42161;

/** Chain ID for Sepolia testnet */
export const SEPOLIA_CHAIN_ID = 11155111;

/** Chain ID for local Anvil development */
export const LOCAL_CHAIN_ID = 31337;

/** Application route paths */
export const ROUTES = {
  HOME: "/",
  DASHBOARD: "/dashboard",
  SCORE: "/score",
  PERMISSIONS: "/permissions",
} as const;
