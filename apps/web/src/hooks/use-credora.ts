"use client";

/**
 * @file use-credora.ts
 * @description Hook exposing Credora protocol state: score, tier, permissions, SBT status.
 */
import { useCredoraClient } from "@/lib/credora-client";
import { useQuery } from "@tanstack/react-query";

export function useCredora() {
  const { client, isReady, hasSigner, address, chainId, isConnected } =
    useCredoraClient();

  const hasSBTQuery = useQuery({
    queryKey: ["credora", "hasSBT", address],
    queryFn: () => (address ? client.hasSBT(address) : Promise.resolve(false)),
    enabled: isReady && !!address,
  });

  const scoreQuery = useQuery({
    queryKey: ["credora", "score", address],
    queryFn: async () => {
      if (!address) return null;
      try {
        return await client.getScore(address);
      } catch {
        return null;
      }
    },
    enabled: isReady && !!address && hasSBTQuery.data === true,
  });

  const tierQuery = useQuery({
    queryKey: ["credora", "tier", address],
    queryFn: () => (address ? client.getTier(address) : null),
    enabled: isReady && !!address && hasSBTQuery.data === true,
  });

  const permissionsQuery = useQuery({
    queryKey: ["credora", "permissions", address],
    queryFn: () => (address ? client.getAllPermissions(address) : []),
    enabled: isReady && !!address,
  });

  return {
    client,
    isReady,
    hasSigner,
    address,
    chainId,
    isConnected,
    hasSBT: hasSBTQuery.data ?? false,
    score: scoreQuery.data,
    tier: tierQuery.data,
    permissions: permissionsQuery.data ?? [],
    isLoading:
      hasSBTQuery.isLoading ||
      scoreQuery.isLoading ||
      tierQuery.isLoading ||
      permissionsQuery.isLoading,
    refetch: () => {
      hasSBTQuery.refetch();
      scoreQuery.refetch();
      tierQuery.refetch();
      permissionsQuery.refetch();
    },
  };
}
