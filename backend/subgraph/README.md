# Credora Subgraph

GraphQL subgraph for indexing Credora protocol data.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Generate types:
```bash
graph codegen
```

3. Build:
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
