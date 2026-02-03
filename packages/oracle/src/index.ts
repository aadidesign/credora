/**
 * @file index.ts
 * @description Credora Oracle Service - Fetches data, calculates scores, submits to ScoreOracle
 *
 * Flow:
 * 1. Poll for users with SBT who need score updates
 * 2. Fetch wallet/DeFi data (from MockDataProvider or The Graph)
 * 3. Calculate score (SimpleScoring logic or call contract)
 * 4. Sign and submit via ScoreOracle.submitScoreUpdate
 *
 * Requires: Deployed contracts, oracle key in authorizedOracles
 */

import "dotenv/config";
import { ethers } from "ethers";
import { CredoraClient, NETWORKS, getNetworkByChainId } from "@credora/sdk";

const RPC_URL = process.env.RPC_URL || "http://127.0.0.1:8545";
const ORACLE_PRIVATE_KEY = process.env.ORACLE_PRIVATE_KEY;
const UPDATE_INTERVAL = parseInt(process.env.UPDATE_INTERVAL || "300", 10);

async function main() {
  if (!ORACLE_PRIVATE_KEY) {
    console.error("[Oracle] ORACLE_PRIVATE_KEY required. Set in .env");
    process.exit(1);
  }

  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const signer = new ethers.Wallet(ORACLE_PRIVATE_KEY, provider);
  const chainId = (await provider.getNetwork()).chainId;

  const network = getNetworkByChainId(Number(chainId)) || NETWORKS.arbitrumSepolia;
  const client = new CredoraClient({
    network,
    signer,
    provider,
  });

  console.log("[Oracle] Credora Oracle Service started");
  console.log("[Oracle] Chain ID:", chainId.toString());
  console.log("[Oracle] Oracle address:", await signer.getAddress());
  console.log("[Oracle] Update interval:", UPDATE_INTERVAL, "s");

  async function runUpdateCycle() {
    try {
      // TODO: Fetch users with SBT from subgraph or contract events
      // TODO: For each user, get data from DataProvider, calculate score
      // TODO: Call scoreOracle.submitScoreUpdate(update, signature)
      console.log("[Oracle] Update cycle - no users configured yet");
    } catch (err) {
      console.error("[Oracle] Cycle error:", err);
    }
  }

  await runUpdateCycle();
  setInterval(runUpdateCycle, UPDATE_INTERVAL * 1000);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
