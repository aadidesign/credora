"use client";

/**
 * @file use-subgraph.ts
 * @description Urql hooks for The Graph subgraph queries (User, ScoreUpdates, Permissions).
 * When subgraph is not configured, queries are paused to avoid CORS errors.
 */
import { useQuery } from "urql";
import { useAccount } from "wagmi";
import {
  GET_USER_QUERY,
  GET_SCORE_UPDATES_QUERY,
  GET_PERMISSIONS_QUERY,
  GET_PROTOCOL_STATS_QUERY,
} from "@/lib/graphql/queries";
import { SUBGRAPH_ENABLED } from "@/config";

export function useSubgraphUser() {
  const { address } = useAccount();
  const id = address ? address.toLowerCase() : "";

  const [result] = useQuery({
    query: GET_USER_QUERY,
    variables: { id },
    pause: !address || !SUBGRAPH_ENABLED,
  });

  return {
    user: result.data?.user,
    isLoading: result.fetching,
    error: result.error,
  };
}

export function useSubgraphScoreUpdates(first = 10) {
  const { address } = useAccount();
  const owner = address ? address.toLowerCase() : "";

  const [result] = useQuery({
    query: GET_SCORE_UPDATES_QUERY,
    variables: { owner, first },
    pause: !address || !SUBGRAPH_ENABLED,
  });

  return {
    scoreUpdates: result.data?.scoreUpdates ?? [],
    isLoading: result.fetching,
    error: result.error,
  };
}

export function useSubgraphPermissions() {
  const { address } = useAccount();
  const user = address ? address.toLowerCase() : "";

  const [result] = useQuery({
    query: GET_PERMISSIONS_QUERY,
    variables: { user },
    pause: !address || !SUBGRAPH_ENABLED,
  });

  return {
    permissions: result.data?.permissions ?? [],
    isLoading: result.fetching,
    error: result.error,
  };
}

/** For protocol integrators: get stats for a protocol address */
export function useSubgraphProtocolStats(protocolAddress: string | undefined) {
  const id = protocolAddress ? protocolAddress.toLowerCase() : "";

  const [result] = useQuery({
    query: GET_PROTOCOL_STATS_QUERY,
    variables: { id },
    pause: !protocolAddress || !SUBGRAPH_ENABLED,
  });

  return {
    protocolStats: result.data?.protocolStats,
    isLoading: result.fetching,
    error: result.error,
  };
}
