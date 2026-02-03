#!/bin/sh
# Generate ABIs from Foundry contracts for The Graph subgraph
# Run from repo root: ./packages/subgraph/scripts/generate-abis.sh

set -e
ABI_DIR="$(dirname "$0")/../abis"
mkdir -p "$ABI_DIR"

echo "Generating ABIs..."

forge inspect contracts/core/ScoreSBT.sol:ScoreSBT abi > "$ABI_DIR/ScoreSBT.json"
forge inspect contracts/core/PermissionManager.sol:PermissionManager abi > "$ABI_DIR/PermissionManager.json"
forge inspect contracts/core/ScoreOracle.sol:ScoreOracle abi > "$ABI_DIR/ScoreOracle.json"

echo "ABIs written to $ABI_DIR"
