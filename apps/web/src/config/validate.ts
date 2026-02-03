/**
 * @file validate.ts
 * @description Environment variable validation. Logs warnings in dev for missing config.
 */

import { SUBGRAPH_ENABLED, WALLETCONNECT_ENABLED } from "./env";

const isDev = process.env.NODE_ENV === "development";

export function validateEnv(): { valid: boolean; warnings: string[] } {
  const warnings: string[] = [];

  if (isDev) {
    if (!SUBGRAPH_ENABLED) {
      warnings.push(
        "Subgraph not configured. Set NEXT_PUBLIC_SUBGRAPH_URL for score history."
      );
    }
    if (!WALLETCONNECT_ENABLED) {
      warnings.push(
        "WalletConnect not configured. Set NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID for QR wallet support."
      );
    }
  }

  if (warnings.length > 0) {
    console.warn("[Credora] Config warnings:", warnings);
  }

  return {
    valid: true,
    warnings,
  };
}
