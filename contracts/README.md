# Credora Smart Contracts

Solidity contracts for the Credora protocol.

## Structure

```
contracts/
├── core/           # ScoreSBT, ScoreOracle, PermissionManager, MockDataProvider
├── interfaces/     # Protocol interfaces
├── libraries/      # ScoreMath, PermissionLogic, DataTypes
├── scoring/        # BaseScoringAlgorithm, SimpleScoring, AdvancedScoring
└── upgradeability/ # ScoreProxy (UUPS)
```

## Build

```bash
forge build
```
