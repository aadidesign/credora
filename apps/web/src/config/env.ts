/**
 * @file env.ts
 * @description Centralized environment configuration for the Credora web app.
 * All Next.js public env vars should be accessed through this module for type safety and consistency.
 */

/** Subgraph GraphQL endpoint (The Graph) */
export const SUBGRAPH_URL =
  process.env.NEXT_PUBLIC_SUBGRAPH_URL ||
  "https://api.thegraph.com/subgraphs/name/credora/credit-scores";

/** Default chain ID: 421614 = Arbitrum Sepolia, 42161 = Arbitrum One, 11155111 = Sepolia */
export const CHAIN_ID = parseInt(
  process.env.NEXT_PUBLIC_CHAIN_ID || "421614",
  10
);

/** WalletConnect Cloud project ID for wallet connection */
export const WALLETCONNECT_PROJECT_ID =
  process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || "credora-web3-app";
