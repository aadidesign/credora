<p align="center">
  <img src="https://img.shields.io/badge/Solidity-0.8.24-blue" alt="Solidity">
  <img src="https://img.shields.io/badge/Foundry-Framework-red" alt="Foundry">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
  <img src="https://img.shields.io/badge/Status-Production--Ready-brightgreen" alt="Status">
</p>

# 🔐 Credora

**Decentralized Credit Scoring Protocol for Web3**

> Credora is a trustless, on-chain credit scoring system using Soulbound Tokens (SBTs) to bridge DeFi lending protocols with verifiable on-chain reputation. Enable uncollateralized lending at scale with privacy-preserving, composable credit scores.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Smart Contracts](#smart-contracts)
- [SDK Usage](#sdk-usage)
- [Testing](#testing)
- [Deployment](#deployment)
- [Protocol Integration](#protocol-integration)
- [Security](#security)
- [Contributing](#contributing)
- [License](#license)

---

## 🌐 Overview

### The Problem

Traditional credit scoring relies on centralized data silos controlled by a few entities. In DeFi, this creates a barrier to uncollateralized lending despite rich on-chain behavioral data.

### The Solution

Credora creates a **decentralized credit scoring infrastructure** that:

- 📊 **Aggregates on-chain data** from multiple protocols via The Graph
- 🪪 **Issues Soulbound NFTs** representing non-transferable credit scores
- 🔐 **Enables permissioned access** - users control who sees their score
- 🔮 **Future-proofs for privacy** with ZK-compatible architecture

### Key Metrics

| Metric | Target |
|--------|--------|
| Score Update | < 150k gas |
| Permission Grant | < 80k gas |
| Score Query | < 30k gas |
| Score Range | 0 - 1000 |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                        │
├─────────────────────────────────────────────────────────────┤
│  Lending Protocols │ Identity DApps │ DAO Governance Tools  │
└───────────────────────────┬─────────────────────────────────┘
                            │ SDK / Smart Contract Calls
┌─────────────────────────────────────────────────────────────┐
│                    Protocol Layer                           │
├──────────────┬──────────────┬──────────────┬───────────────┤
│   ScoreSBT   │ ScoreOracle  │ Permission   │   Scoring     │
│   (ERC-721)  │   (Oracle)   │   Manager    │   Algorithms  │
└──────────────┴───────┬──────┴──────────────┴───────────────┘
                       │ On-chain Events
┌─────────────────────────────────────────────────────────────┐
│                    Data Layer                               │
├──────────────┬──────────────┬──────────────────────────────┤
│  The Graph   │   Chainlink  │    Backend Services          │
│  Subgraphs   │   Keepers    │    (Score Calculator)        │
└──────────────┴──────────────┴──────────────────────────────┘
```

---

## ✨ Features

### Core Features

- **🪪 Soulbound Credit Scores** - Non-transferable ERC-721 tokens storing credit scores
- **📈 Multi-Factor Scoring** - Wallet age, transaction volume, repayment history, protocol diversity
- **🔐 Permissioned Access** - Time-limited, quota-based permission system
- **🔄 Oracle System** - Signature-verified score updates with rate limiting
- **🛡️ Emergency Recovery** - 7-day cooldown recovery mechanism for lost keys

### Scoring Factors

| Factor | Weight | Calculation |
|--------|--------|-------------|
| Wallet Age | 20% | `sqrt(days_active) × 10` |
| Transaction Volume | 25% | `log10(total_eth) × 100` |
| Repayment History | 35% | `(repaid / total) × 1000` |
| Protocol Diversity | 20% | `(unique_protocols / 10) × 1000` |

### Score Tiers

| Tier | Score Range | Description |
|------|-------------|-------------|
| **Newcomer** | 0 - 299 | New to DeFi with minimal history |
| **Established** | 300 - 549 | Some DeFi experience |
| **Trusted** | 550 - 749 | Solid track record |
| **Prime** | 750 - 1000 | Excellent credit history |

---

## 📦 Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) >= 18.0.0
- [Git](https://git-scm.com/)

### Clone and Setup

```bash
# Clone the repository
git clone https://github.com/your-username/credora.git
cd credora

# Install Foundry dependencies
forge install

# Install Node.js dependencies for SDK
cd packages/sdk && npm install && cd ../..
```

### Install OpenZeppelin

```bash
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
```

---

## 🚀 Quick Start

### 1. Compile Contracts

```bash
forge build
```

### 2. Run Tests

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run specific test file
forge test --match-path test/unit/ScoreSBT.t.sol -vvv
```

### 3. Deploy Locally

```bash
# Start Anvil
anvil

# Deploy (in another terminal)
forge script script/Deploy.s.sol:DeployLocal --fork-url http://localhost:8545 --broadcast
```

### 4. Interact with Contracts

```bash
# Mint an SBT
cast send $SCORE_SBT "mintSelf()" --private-key $PRIVATE_KEY

# Check score
cast call $SCORE_SBT "getScoreValue(address)" $USER_ADDRESS
```

---

## 📄 Smart Contracts

### Contract Structure

```
contracts/
├── core/
│   ├── ScoreSBT.sol           # ERC-721 Soulbound Token
│   ├── ScoreOracle.sol        # Oracle for score updates
│   ├── PermissionManager.sol  # Access control system
│   └── MockDataProvider.sol   # Testing data provider
├── scoring/
│   ├── BaseScoringAlgorithm.sol   # Abstract scoring base
│   ├── SimpleScoring.sol          # MVP implementation
│   └── AdvancedScoring.sol        # Upgradeable advanced scoring
├── interfaces/
│   ├── ISoulbound.sol         # Soulbound interface
│   ├── IScoreConsumer.sol     # Protocol integration interface
│   ├── IDataProvider.sol      # Data source interface
│   ├── IScoreOracle.sol       # Oracle interface
│   └── IPermissionManager.sol # Permission interface
├── libraries/
│   ├── ScoreMath.sol          # Math operations
│   ├── PermissionLogic.sol    # Permission utilities
│   └── DataTypes.sol          # Common structures
└── upgradeability/
    └── ScoreProxy.sol         # UUPS proxy
```

### Key Contracts

#### ScoreSBT.sol

The core Soulbound Token storing credit scores:

```solidity
// Mint your credit score NFT
uint256 tokenId = scoreSBT.mintSelf();

// Get score data
CreditScore memory score = scoreSBT.getScoreByAddress(user);
// score.score = 750
// score.lastUpdated = 1706900000
// score.dataVersion = 1
```

#### PermissionManager.sol

User-controlled access permissions:

```solidity
// Grant access to a lending protocol
bytes32 permissionId = permissionManager.grantAccess(
    lendingProtocol,  // Protocol address
    30 days,          // Duration
    1000              // Max requests
);

// Check permission
bool valid = permissionManager.hasValidPermission(user, protocol);

// Revoke access
permissionManager.revokeAccess(protocol);
```

#### ScoreOracle.sol

Trusted oracle for score updates:

```solidity
// Submit score update (oracle only)
scoreOracle.submitScoreUpdateDirect(
    user,           // User address
    750,            // New score
    dataHash        // Calculation proof
);
```

---

## 💻 SDK Usage

### Installation

```bash
npm install @credora/sdk ethers
```

### Basic Usage

```typescript
import { CredoraClient, NETWORKS } from '@credora/sdk';
import { ethers } from 'ethers';

// Initialize client
const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

const client = new CredoraClient({
  network: NETWORKS.arbitrumSepolia,
  signer: wallet,
});

// Check if user has SBT
const hasSBT = await client.hasSBT(userAddress);

// Get credit score
const score = await client.getScore(userAddress);
console.log(`Score: ${score.score}, Last Updated: ${score.lastUpdated}`);

// Get tier
const tier = await client.getTier(userAddress);
console.log(`Tier: ${tier.name} (${tier.minScore}-${tier.maxScore})`);

// Mint SBT
const result = await client.mintSBT();
console.log(`Token ID: ${result.tokenId}`);

// Grant access to protocol
await client.grantAccess({
  protocol: lendingProtocol,
  duration: 30 * 24 * 60 * 60, // 30 days
  maxRequests: 1000,
});

// Check permissions
const hasAccess = await client.hasValidPermission(user, protocol);
const quota = await client.getRemainingQuota(user, protocol);
```

---

## 🧪 Testing

### Test Structure

```
test/
├── unit/
│   ├── ScoreSBT.t.sol         # 30+ unit tests
│   ├── ScoringAlgorithm.t.sol # Math and scoring tests
│   └── PermissionManager.t.sol # Permission tests
├── integration/
│   └── FullFlow.t.sol         # End-to-end tests
├── fuzz/
│   └── ScoreCalculationFuzz.t.sol # Fuzz testing
└── invariant/
    └── ScoreInvariant.t.sol   # Invariant tests
```

### Commands

```bash
# All tests
forge test

# With verbosity
forge test -vvv

# Gas report
forge test --gas-report

# Coverage
forge coverage

# Fuzz testing (10,000 runs)
forge test --fuzz-runs 10000

# Specific test
forge test --match-test test_Mint -vvv
```

### Key Test Scenarios

- ✅ SBT minting and burning
- ✅ Soulbound transfer restrictions
- ✅ Score update mechanics
- ✅ Permission grant/revoke flow
- ✅ Quota enforcement
- ✅ Recovery mechanism
- ✅ Score bounds (0-1000)
- ✅ Monotonicity of scoring factors
- ✅ One-token-per-address invariant

---

## 🚢 Deployment

### Environment Setup

```bash
cp .env.example .env
# Edit .env with your values
```

Required variables:
```
DEPLOYER_PRIVATE_KEY=0x...
ARBITRUM_SEPOLIA_RPC_URL=https://...
ARBISCAN_API_KEY=...
```

### Deploy to Testnet

```bash
# Deploy to Arbitrum Sepolia
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

### Verify Contracts

```bash
forge verify-contract \
  $CONTRACT_ADDRESS \
  src/core/ScoreSBT.sol:ScoreSBT \
  --chain arbitrum-sepolia \
  --etherscan-api-key $ARBISCAN_API_KEY
```

---

## 🔌 Protocol Integration

### For Lending Protocols

Integrate Credora in **under 50 lines of code**:

```solidity
import {IScoreConsumer} from "@credora/interfaces/IScoreConsumer.sol";

contract UncollateralizedLoan {
    IScoreConsumer public credora;
    IPermissionManager public permissions;
    
    function calculateLoanTerms(
        address borrower
    ) external view returns (uint256 creditLimit) {
        // Verify permission
        require(
            permissions.hasValidPermission(borrower, address(this)),
            "No permission"
        );
        
        // Consume access
        permissions.consumeAccess(borrower, address(this));
        
        // Get score
        uint256 score = credora.getScoreValue(borrower);
        
        // Calculate terms based on score
        if (score >= 750) {
            creditLimit = 100 ether; // Prime tier
        } else if (score >= 550) {
            creditLimit = 50 ether;  // Trusted tier
        } else if (score >= 300) {
            creditLimit = 10 ether;  // Established tier
        } else {
            creditLimit = 0;         // Requires collateral
        }
    }
}
```

---

## 🔒 Security

### Audit Status

⚠️ **Note**: This codebase has not been audited. Use at your own risk in production.

### Security Features

- **Rate Limiting**: Minimum 1-hour interval between score updates
- **Sybil Resistance**: Minimum wallet age and transaction requirements
- **Manipulation Detection**: Monitoring for rapid score changes
- **Access Control**: Owner-only administrative functions
- **Reentrancy Protection**: ReentrancyGuard on all state-changing functions

### Attack Mitigations

| Attack Vector | Mitigation |
|---------------|------------|
| Score Manipulation | Time-weighted averaging, rate limiting |
| Sybil Attacks | Minimum history requirements |
| Permission Abuse | Quota limits, expiration |
| Key Compromise | 7-day recovery cooldown |

### Responsible Disclosure

Found a vulnerability? Please email security@credora.io

---

## 📊 Monitoring

### Tenderly Integration

The `monitoring/alerts.yaml` file includes pre-configured alerts:

- 🚨 Rapid score increases (>200 in 24h)
- ⚠️ Oracle downtime (no updates in 48h)
- 🔐 Permission abuse detection
- 📈 Ownership transfer alerts

### The Graph Subgraph

Query indexed data:

```graphql
query GetUserScore($address: Bytes!) {
  user(id: $address) {
    currentScore
    totalScoreUpdates
    activePermissions
    lastActivityAt
  }
}

query GetProtocolStats($protocol: Bytes!) {
  protocolStats(id: $protocol) {
    totalPermissionsReceived
    activePermissions
    totalAccessUsed
  }
}
```

---

## 📁 Project Structure

```
credora/
├── contracts/           # Solidity smart contracts
├── script/              # Deployment scripts
├── test/                # Foundry tests
├── packages/
│   └── sdk/             # TypeScript SDK
├── backend/
│   └── subgraph/        # The Graph configuration
├── monitoring/          # Alert configurations
├── foundry.toml         # Foundry configuration
├── remappings.txt       # Import remappings
└── README.md
```

---

## 🗺️ Roadmap

### Phase 1: Foundation ✅
- Core SBT implementation
- Basic scoring algorithm
- Permission system
- Foundry test suite

### Phase 2: Production (Current)
- Oracle integration
- Multi-network deployment
- Security audit
- SDK release

### Phase 3: Advanced Features
- ZK-proof integration
- Cross-chain score syncing
- Decentralized oracle network
- Governance mechanisms

---

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines first.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Contact

- **Twitter**: [@CredoraProtocol](https://twitter.com/CredoraProtocol)
- **Discord**: [Join our community](https://discord.gg/credora)
- **Email**: hello@credora.io

---

<p align="center">
  <strong>Built for the decentralized future 🚀</strong>
</p>
