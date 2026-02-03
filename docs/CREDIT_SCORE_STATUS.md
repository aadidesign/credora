# Credora Credit Score & Graph – Status Report

## Executive Summary

| Component | Status | Notes |
|-----------|--------|-------|
| **Scoring algorithms** | ✅ Working | SimpleScoring & AdvancedScoring tested |
| **Smart contracts** | ✅ Ready | Need deployment |
| **The Graph subgraph** | ⚠️ Incomplete | Mappings missing, cannot index |
| **Oracle / Score updates** | ❌ Not automated | No backend service |
| **Frontend score display** | ✅ Working | Reads from contract when deployed |

---

## 1. Credit Score Algorithms

### SimpleScoring (MVP)

- **Location:** `contracts/scoring/SimpleScoring.sol`
- **Status:** Implemented and tested
- **Factors:**
  - Wallet Age (20%): `sqrt(days_active) × 10`
  - Transaction Volume (25%): `log10(total_eth) × 100`
  - Repayment History (35%): `(repaid / total) × 1000`
  - Protocol Diversity (20%): `(unique_protocols / 10) × 1000`

### AdvancedScoring (Upgradeable)

- **Location:** `contracts/scoring/AdvancedScoring.sol`
- **Status:** Implemented
- **Adds:** Longevity bonus, loyalty bonus, whale discount, minimum thresholds

### Verification

```powershell
cd d:\credora
forge test --match-path test/unit/ScoringAlgorithm.t.sol -vvv
forge test --match-path test/integration/FullFlow.t.sol -vvv
```

---

## 2. The Graph (Real-Time Indexing)

### Current State

- **Subgraph schema:** ✅ `packages/subgraph/schema.graphql`
- **Subgraph config:** ✅ `packages/subgraph/subgraph.yaml`
- **Event handlers (mappings):** ❌ **Missing** – `subgraph.yaml` references:
  - `./src/mappings/score-sbt.ts`
  - `./src/mappings/permission-manager.ts`
  - `./src/mappings/score-oracle.ts`

  These files are not in `packages/subgraph/`. The subgraph **cannot be built or deployed** without them.

### Contract Addresses in Subgraph

All data sources use `0x0000000000000000000000000000000000000000`. Update after deployment.

### To Enable Real-Time Graphs

1. Implement mapping files in `packages/subgraph/src/mappings/`
2. Build subgraph: `graph codegen && graph build`
3. Deploy to [Subgraph Studio](https://thegraph.com/studio)
4. Set `NEXT_PUBLIC_SUBGRAPH_URL` in `.env.local`

---

## 3. Score Update Flow (Oracle)

### How It Works

1. User mints SBT (score = 0 initially)
2. **Off-chain:** Backend fetches data → runs scoring → signs update
3. **On-chain:** Oracle calls `ScoreOracle.submitScoreUpdate(update, signature)`
4. ScoreSBT stores the new score and emits `ScoreUpdated`
5. Subgraph indexes the event (once mappings exist)

### Oracle Service

A minimal oracle service exists at `packages/oracle/`:

- Fetches data, runs scoring, submits to ScoreOracle
- Run: `cd packages/oracle && npm run dev`
- See `packages/oracle/README.md` for setup

The service skeleton is in place; implement user polling and score calculation as needed.

### Options to Get Scores Updated

1. **Manual (dev):** Use `MockDataProvider` + `SimpleScoring.calculateScore()` + `submitScoreUpdateDirect`
2. **Production:** Add a backend service that:
   - Implements IDataProvider or aggregates from The Graph / other sources
   - Runs SimpleScoring logic (or calls the contract)
   - Signs updates with an oracle private key
   - Submits via `submitScoreUpdate`

---

## 4. Frontend Data Flow

### Where the Frontend Gets Data

| Data | Source | When |
|------|--------|------|
| Current score | ScoreSBT contract (SDK) | Always, when contracts deployed |
| Score history | The Graph (subgraph) | Only when subgraph deployed and URL set |
| Permissions | PermissionManager (SDK) | Always |

### Subgraph Usage

- `useSubgraphScoreUpdates` – score history
- `useSubgraphUser` – user aggregate
- `useSubgraphPermissions` – permissions (optional)
- `useSubgraphProtocolStats` – protocol stats

All subgraph hooks use `pause: true` when `SUBGRAPH_ENABLED` is false (no URL or deprecated URL).

---

## 5. Verification Checklist

### Run Tests

```powershell
cd d:\credora

# Unit tests
forge test

# With gas report
forge test --gas-report

# Scoring algorithm
forge test --match-path test/unit/ScoringAlgorithm.t.sol -vvv

# Integration flow
forge test --match-path test/integration/FullFlow.t.sol -vvv
```

### Local Deployment

```powershell
# Terminal 1: Anvil
anvil

# Terminal 2: Deploy
forge script script/Deploy.s.sol:DeployLocal --fork-url http://localhost:8545 --broadcast

# Set in apps/web/.env.local:
# NEXT_PUBLIC_CHAIN_ID=31337
# NEXT_PUBLIC_SCORE_SBT_ADDRESS=<from deploy output>
# etc.
```

### Manual Score Update (Local)

1. Mint SBT via frontend
2. Seed MockDataProvider with data
3. Call `SimpleScoring.calculateScore(user)`
4. Call `ScoreOracle.submitScoreUpdateDirect(user, score, hash)` as oracle

---

## 6. Summary: What’s Needed for Production

| Item | Action |
|------|--------|
| Deploy contracts | Run Deploy script on target network |
| Configure frontend | Set contract addresses in `.env.local` |
| Subgraph mappings | Implement `score-sbt.ts`, `permission-manager.ts`, `score-oracle.ts` |
| Deploy subgraph | Build and deploy to Subgraph Studio |
| Oracle service | Build backend that calculates and submits score updates |
