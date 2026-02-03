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
    queryFn: async () => {
      if (!address) return false;
      try {
        return await client.hasSBT(address);
      } catch {
        return false;
      }
    },
    enabled: isReady && !!address,
    retry: false,
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
    queryFn: async () => {
      if (!address) return null;
      try {
        return await client.getTier(address);
      } catch {
        return null;
      }
    },
    enabled: isReady && !!address && hasSBTQuery.data === true,
    retry: false,
  });

  const permissionsQuery = useQuery({
    queryKey: ["credora", "permissions", address],
    queryFn: async () => {
      if (!address) return [];
      try {
        return await client.getAllPermissions(address);
      } catch {
        return [];
      }
    },
    enabled: isReady && !!address,
    retry: false,
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
