import {
  SUBGRAPH_ENABLED,
  SUBGRAPH_URL,
  CHAIN_ID,
  CONTRACT_OVERRIDES,
} from "@/config";

export const dynamic = "force-dynamic";

/** Health check endpoint for monitoring and debugging */
export async function GET() {
  const checks: Record<string, unknown> = {
    status: "ok",
    timestamp: new Date().toISOString(),
    config: {
      chainId: CHAIN_ID,
      subgraphEnabled: SUBGRAPH_ENABLED,
      subgraphUrl: SUBGRAPH_URL || null,
      contracts: {
        scoreSBT: CONTRACT_OVERRIDES.scoreSBT ?? "(default)",
        permissionManager: CONTRACT_OVERRIDES.permissionManager ?? "(default)",
      },
    },
  };

  if (SUBGRAPH_ENABLED && SUBGRAPH_URL) {
    try {
      const res = await fetch(SUBGRAPH_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query: "{ _meta { block { number } } }" }),
      });
      (checks as Record<string, unknown>).subgraphReachable = res.ok;
    } catch {
      (checks as Record<string, unknown>).subgraphReachable = false;
    }
  }

  return Response.json(checks, { status: 200 });
}
