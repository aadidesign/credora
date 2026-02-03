"use client";

import { createClient, fetchExchange, cacheExchange } from "urql";
import { SUBGRAPH_URL } from "@/config";

/**
 * GraphQL client for The Graph subgraph.
 * When SUBGRAPH_URL is unset or points to deprecated api.thegraph.com,
 * subgraph hooks use pause:true so no requests are made (avoids CORS errors).
 */
export const graphqlClient = createClient({
  url: SUBGRAPH_URL || "https://localhost/graphql",
  exchanges: [cacheExchange, fetchExchange],
});
