# @credora/oracle

Oracle service for Credora that fetches on-chain data, calculates credit scores, and submits updates to the ScoreOracle contract.

## Prerequisites

- Deployed contracts (ScoreSBT, ScoreOracle, MockDataProvider)
- Oracle address in `authorizedOracles` on ScoreOracle
- MockDataProvider seeded with user data (for dev)

## Setup

```bash
cp .env.example .env
# Edit .env with RPC_URL, ORACLE_PRIVATE_KEY, contract addresses

npm install
npm run dev
```

## Flow

1. Poll for users with SBT who need score updates
2. Fetch wallet/DeFi data from MockDataProvider (or custom DataProvider)
3. Calculate score using SimpleScoring logic
4. Sign update with EIP-712 and submit via `ScoreOracle.submitScoreUpdate`

## Environment

| Variable | Description |
|----------|-------------|
| RPC_URL | Ethereum RPC endpoint |
| ORACLE_PRIVATE_KEY | Private key of authorized oracle |
| SCORE_SBT_ADDRESS | Deployed ScoreSBT |
| SCORE_ORACLE_ADDRESS | Deployed ScoreOracle |
| DATA_PROVIDER_ADDRESS | MockDataProvider or custom |
| UPDATE_INTERVAL | Seconds between update cycles |
