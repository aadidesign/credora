"use client";

import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { arbitrum, arbitrumSepolia, sepolia } from "wagmi/chains";
import { WALLETCONNECT_PROJECT_ID } from "@/config";

/**
 * Supported chains for the Credora protocol
 */
export const chains = [
  arbitrumSepolia,
  arbitrum,
  sepolia,
  {
    id: 31337,
    name: "Anvil Local",
    nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
    rpcUrls: {
      default: { http: ["http://127.0.0.1:8545"] },
    },
  },
] as const;

/**
 * Wagmi config for RainbowKit wallet connection.
 * Uses default wallets from RainbowKit which handles wallet detection safely.
 * SSR is disabled to avoid MetaMask private field access errors during hydration.
 */
export const config = getDefaultConfig({
  appName: "Credora",
  projectId: WALLETCONNECT_PROJECT_ID || "00000000000000000000000000000000",
  chains,
  ssr: false,
});
