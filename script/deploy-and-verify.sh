#!/bin/sh
# Deploy Credora contracts and verify on block explorer
# Usage: ./script/deploy-and-verify.sh [network]
# Requires: DEPLOYER_PRIVATE_KEY, ARBITRUM_SEPOLIA_RPC_URL, ARBISCAN_API_KEY

set -e
NETWORK=${1:-arbitrum-sepolia}

echo "Deploying to $NETWORK..."

# Deploy
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$(eval echo \$$(echo ${NETWORK} | tr 'a-z' 'A-Z' | tr '-' '_')_RPC_URL)" \
  --broadcast \
  --verify \
  --etherscan-api-key "$(eval echo \$$(echo ${NETWORK} | tr 'a-z' 'A-Z' | tr '-' '_' | sed 's/ARBITRUM_SEPOLIA/ARBISCAN/' )_API_KEY)"

# Extract addresses from broadcast artifact and output for .env
echo ""
echo "Add to .env:"
echo "NEXT_PUBLIC_SCORE_SBT_ADDRESS=<from broadcast>"
echo "NEXT_PUBLIC_SCORE_ORACLE_ADDRESS=<from broadcast>"
echo "NEXT_PUBLIC_PERMISSION_MANAGER_ADDRESS=<from broadcast>"
