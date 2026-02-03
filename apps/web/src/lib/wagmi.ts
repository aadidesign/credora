"use client";

import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import {
  metaMaskWallet,
  injectedWallet,
  walletConnectWallet,
} from "@rainbow-me/rainbowkit/wallets";
import { arbitrum, arbitrumSepolia, sepolia } from "wagmi/chains";
import { WALLETCONNECT_PROJECT_ID, WALLETCONNECT_ENABLED } from "@/config";

const chains = [
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
 * Curated wallet list: MetaMask + Injected (+ WalletConnect when configured).
 * Excludes Trust, Phantom, Rainbow, etc. to avoid multiple wallet popups.
 */
const wallets = [
  {
    groupName: "Recommended",
    wallets: [
      metaMaskWallet,
      ...(WALLETCONNECT_ENABLED ? [walletConnectWallet] : []),
      injectedWallet,
    ],
  },
];

/** Wagmi config for RainbowKit wallet connection */
export const config = getDefaultConfig({
  appName: "Credora",
  projectId: WALLETCONNECT_PROJECT_ID || "00000000000000000000000000000000",
  chains,
  wallets,
  ssr: true,
});
