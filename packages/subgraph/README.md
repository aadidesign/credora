# @credora/subgraph

The Graph subgraph for indexing Credora protocol events (ScoreSBT, PermissionManager, ScoreOracle).

## Location

This package lives in `packages/subgraph` as part of the Credora monorepo.

## Setup

1. Add ABIs to `abis/` and mapping handlers to `src/mappings/` before building.
2. Install dependencies:

```bash
npm install
```

3. Generate types:

```bash
graph codegen
```

4. Build:

```bash
graph build
```

## Deployment

### Local (Graph Node)

```bash
graph create --node http://localhost:8020/ credora/credit-scores
graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 credora/credit-scores
```

### Hosted Service

```bash
graph auth --product hosted-service <ACCESS_TOKEN>
graph deploy --product hosted-service <GITHUB_USER>/credora-credit-scores
```

### Subgraph Studio (Decentralized)

```bash
graph auth --studio <DEPLOY_KEY>
graph deploy --studio credora-credit-scores
```
