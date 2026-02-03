# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- **CI/CD** – GitHub Actions (contracts, frontend, subgraph, lint)
- **Subgraph** – Complete mapping handlers (score-sbt, permission-manager, score-oracle)
- **Oracle service** – `packages/oracle` skeleton for automated score updates
- **E2E tests** – Playwright for landing, navigation, health API
- **Docker** – Dockerfile + docker-compose (Anvil, Graph Node, IPFS, Postgres, Frontend)
- **Environment validation** – Zod schema with safeParse (dev warnings)
- **Health API** – `/api/health` with config, subgraph reachability, contract addresses
- **Sentry** – Error monitoring (optional via `NEXT_PUBLIC_SENTRY_DSN`)
- **Storybook** – UI component stories (Button, ScoreGauge)
- **Deployment** – `script/deploy-and-verify.sh`, `script/update-subgraph-addresses.js`
- `.nvmrc` and `.node-version` for Node version consistency
- `CONTRIBUTING.md` for contribution guidelines
- `docs/CREDIT_SCORE_STATUS.md` – credit score & graph status report

### Changed

- Improved `.env.example` with clearer comments

## [1.0.0] – Initial Release

- Core contracts: ScoreSBT, ScoreOracle, PermissionManager
- Scoring algorithms: SimpleScoring, AdvancedScoring
- Next.js frontend with Wagmi, RainbowKit
- TypeScript SDK
- The Graph subgraph schema
