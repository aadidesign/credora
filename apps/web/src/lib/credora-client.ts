"use client";

/**
 * @file credora-client.ts
 * @description React hook for CredoraClient instantiation with Wagmi signer/provider.
 */
import { CredoraClient as SDKClient, NETWORKS, getNetworkByChainId } from "@credora/sdk";
import { BrowserProvider, JsonRpcSigner } from "ethers";
import { useEffect, useMemo, useState } from "react";
import { useAccount, useWalletClient } from "wagmi";
import { CHAIN_ID } from "@/config";

export function useCredoraClient() {
  const { address, chainId, isConnected } = useAccount();
  const { data: walletClient } = useWalletClient();
  const [provider, setProvider] = useState<BrowserProvider | null>(null);
  const [signer, setSigner] = useState<JsonRpcSigner | null>(null);

  useEffect(() => {
    if (typeof window === "undefined" || !window.ethereum) return;

    const init = async () => {
      try {
        const browserProvider = new BrowserProvider(window.ethereum);
        setProvider(browserProvider);
        if (walletClient && address) {
          const s = await browserProvider.getSigner();
          setSigner(s);
        } else {
          setSigner(null);
        }
      } catch {
        setProvider(null);
        setSigner(null);
      }
    };

    init();
  }, [walletClient, address]);

  const client = useMemo(() => {
    const network = getNetworkByChainId(chainId || CHAIN_ID) || NETWORKS.arbitrumSepolia;
    return new SDKClient({
      network,
      provider: provider ?? undefined,
      signer: signer ?? undefined,
    });
  }, [chainId, provider, signer]);

  return {
    client,
    isReady: !!provider,
    hasSigner: !!signer,
    address,
    chainId,
    isConnected,
  };
}
