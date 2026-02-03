"use client";

/**
 * @file credora-client.ts
 * @description React hook for CredoraClient instantiation with Wagmi signer/provider.
 */
import { CredoraClient as SDKClient, NETWORKS, getNetworkByChainId, type NetworkConfig } from "@credora/sdk";
import { BrowserProvider, JsonRpcSigner } from "ethers";
import { useEffect, useMemo, useState } from "react";
import { useAccount, useWalletClient } from "wagmi";
import { CHAIN_ID, CONTRACT_OVERRIDES } from "@/config";

/** Merge env contract overrides into network config */
function applyContractOverrides(network: NetworkConfig): NetworkConfig {
  const overrides = CONTRACT_OVERRIDES;
  if (!overrides.scoreSBT && !overrides.permissionManager) return network;
  return {
    ...network,
    contracts: {
      ...network.contracts,
      ...(overrides.scoreSBT && { scoreSBT: overrides.scoreSBT }),
      ...(overrides.scoreOracle && { scoreOracle: overrides.scoreOracle }),
      ...(overrides.permissionManager && { permissionManager: overrides.permissionManager }),
    },
  };
}

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
    const baseNetwork = getNetworkByChainId(chainId || CHAIN_ID) || NETWORKS.arbitrumSepolia;
    const network = applyContractOverrides(baseNetwork);
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
