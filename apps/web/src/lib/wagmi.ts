"use client";

import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { arbitrum, arbitrumSepolia, sepolia } from "wagmi/chains";
import { WALLETCONNECT_PROJECT_ID } from "@/config";

/** Wagmi config for RainbowKit wallet connection */
export const config = getDefaultConfig({
  appName: "Credora",
  projectId: WALLETCONNECT_PROJECT_ID,
  chains: [
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
  ],
  ssr: true,
});
