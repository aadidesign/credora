"use client";

import { createClient, fetchExchange, cacheExchange } from "urql";
import { SUBGRAPH_URL } from "@/config";

/**
 * GraphQL client for The Graph subgraph.
 * Used by urql hooks for querying indexed Credora data.
 */
export const graphqlClient = createClient({
  url: SUBGRAPH_URL,
  exchanges: [cacheExchange, fetchExchange],
});
