/**
 * @file env.ts
 * @description Centralized environment configuration for the Credora web app.
 * All Next.js public env vars should be accessed through this module for type safety and consistency.
 */

import { z } from "zod";

const envSchema = z.object({
  NEXT_PUBLIC_SUBGRAPH_URL: z.string().optional().default(""),
  NEXT_PUBLIC_CHAIN_ID: z.string().optional().default("421614"),
  NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID: z.string().optional().default(""),
  NEXT_PUBLIC_APP_URL: z.string().optional(),
  NEXT_PUBLIC_SCORE_SBT_ADDRESS: z.string().optional(),
  NEXT_PUBLIC_SCORE_ORACLE_ADDRESS: z.string().optional(),
  NEXT_PUBLIC_PERMISSION_MANAGER_ADDRESS: z.string().optional(),
});

// Validate at module load - log warnings only
const parsed = envSchema.safeParse({
  NEXT_PUBLIC_SUBGRAPH_URL: process.env.NEXT_PUBLIC_SUBGRAPH_URL,
  NEXT_PUBLIC_CHAIN_ID: process.env.NEXT_PUBLIC_CHAIN_ID,
  NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID,
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
  NEXT_PUBLIC_SCORE_SBT_ADDRESS: process.env.NEXT_PUBLIC_SCORE_SBT_ADDRESS,
  NEXT_PUBLIC_SCORE_ORACLE_ADDRESS: process.env.NEXT_PUBLIC_SCORE_ORACLE_ADDRESS,
  NEXT_PUBLIC_PERMISSION_MANAGER_ADDRESS: process.env.NEXT_PUBLIC_PERMISSION_MANAGER_ADDRESS,
});
if (!parsed.success && typeof window === "undefined") {
  console.warn("[Credora] Env validation:", parsed.error.flatten());
}

/**
 * Subgraph GraphQL endpoint.
 * The Graph's hosted service (api.thegraph.com) was sunset in June 2024.
 * Deploy to The Graph Network via Subgraph Studio, then set this URL.
 * Leave unset for local dev without subgraph (app works with empty indexed data).
 */
export const SUBGRAPH_URL =
  process.env.NEXT_PUBLIC_SUBGRAPH_URL?.trim() || "";

/** True only when a valid subgraph URL is configured (avoids CORS errors from deprecated endpoints) */
export const SUBGRAPH_ENABLED = Boolean(
  SUBGRAPH_URL &&
    !SUBGRAPH_URL.includes("api.thegraph.com/subgraphs/name")
);

/** Default chain ID: 421614 = Arbitrum Sepolia, 42161 = Arbitrum One, 11155111 = Sepolia */
export const CHAIN_ID = parseInt(
  process.env.NEXT_PUBLIC_CHAIN_ID || "421614",
  10
);

/** WalletConnect Cloud project ID for wallet connection */
export const WALLETCONNECT_PROJECT_ID =
  process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID?.trim() || "";

/** True when a valid WalletConnect Project ID is set (32-char hex from cloud.walletconnect.com) */
export const WALLETCONNECT_ENABLED = Boolean(
  WALLETCONNECT_PROJECT_ID && WALLETCONNECT_PROJECT_ID.length >= 32
);

/** Optional: Override contract addresses (set after deployment) */
export const CONTRACT_OVERRIDES = {
  scoreSBT: process.env.NEXT_PUBLIC_SCORE_SBT_ADDRESS,
  scoreOracle: process.env.NEXT_PUBLIC_SCORE_ORACLE_ADDRESS,
  permissionManager: process.env.NEXT_PUBLIC_PERMISSION_MANAGER_ADDRESS,
} as const;
