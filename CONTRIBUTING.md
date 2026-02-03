# Contributing to Credora

Thanks for your interest in contributing! This document provides guidelines for contributing to the Credora project.

## Development Setup

### Prerequisites

- **Foundry** – [Install](https://book.getfoundry.sh/getting-started/installation)
- **Node.js** >= 18 (we use v20; see `.nvmrc`)
- **Git**

### Quick Start

```bash
# Clone and install
git clone https://github.com/your-username/credora.git
cd credora

# Install Foundry dependencies
forge install

# Install OpenZeppelin
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit

# Node dependencies
npm install
cd packages/sdk && npm install && cd ../..
cd apps/web && npm install && cd ../..
```

### Running Tests

```bash
# Smart contracts
forge test

# Frontend (from apps/web)
npm run dev
```

## Pull Request Process

1. Fork the repository and create a feature branch.
2. Make your changes. Ensure:
   - `forge test` passes for contract changes
   - `npm run build` passes for frontend/SDK changes
   - `npm run lint` passes in apps/web
3. Write or update tests as needed.
4. Submit a PR with a clear description of the change.
5. Address review feedback.

## Code Style

- **Solidity:** Follow [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)
- **TypeScript/React:** Use the existing patterns; run `npm run lint` before committing

## Project Structure

- `contracts/` – Solidity smart contracts
- `apps/web/` – Next.js frontend
- `packages/sdk/` – TypeScript SDK
- `packages/subgraph/` – The Graph subgraph
- `script/` – Deployment scripts
- `test/` – Foundry tests

## Questions?

Open an issue for questions or discussion.
