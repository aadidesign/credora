/**
 * @title Network Configurations
 * @description Pre-configured networks for Credora SDK
 */

import { NetworkConfig } from "./types";

/**
 * Arbitrum Sepolia testnet configuration
 */
export const ARBITRUM_SEPOLIA: NetworkConfig = {
    chainId: 421614,
    name: "Arbitrum Sepolia",
    rpcUrl: "https://sepolia-rollup.arbitrum.io/rpc",
    blockExplorer: "https://sepolia.arbiscan.io",
    contracts: {
        scoreSBT: "0x0000000000000000000000000000000000000000", // To be filled after deployment
        scoreOracle: "0x0000000000000000000000000000000000000000",
        permissionManager: "0x0000000000000000000000000000000000000000",
        simpleScoring: "0x0000000000000000000000000000000000000000",
    },
};

/**
 * Arbitrum mainnet configuration
 */
export const ARBITRUM_ONE: NetworkConfig = {
    chainId: 42161,
    name: "Arbitrum One",
    rpcUrl: "https://arb1.arbitrum.io/rpc",
    blockExplorer: "https://arbiscan.io",
    contracts: {
        scoreSBT: "0x0000000000000000000000000000000000000000", // To be filled after deployment
        scoreOracle: "0x0000000000000000000000000000000000000000",
        permissionManager: "0x0000000000000000000000000000000000000000",
        simpleScoring: "0x0000000000000000000000000000000000000000",
    },
};

/**
 * Sepolia testnet configuration
 */
export const SEPOLIA: NetworkConfig = {
    chainId: 11155111,
    name: "Sepolia",
    rpcUrl: "https://rpc.sepolia.org",
    blockExplorer: "https://sepolia.etherscan.io",
    contracts: {
        scoreSBT: "0x0000000000000000000000000000000000000000",
        scoreOracle: "0x0000000000000000000000000000000000000000",
        permissionManager: "0x0000000000000000000000000000000000000000",
    },
};

/**
 * Local Anvil development configuration
 */
export const LOCAL: NetworkConfig = {
    chainId: 31337,
    name: "Anvil Local",
    rpcUrl: "http://127.0.0.1:8545",
    blockExplorer: "",
    contracts: {
        scoreSBT: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
        scoreOracle: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
        permissionManager: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
        simpleScoring: "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9",
        dataProvider: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
    },
};

/**
 * All available networks
 */
export const NETWORKS = {
    arbitrumSepolia: ARBITRUM_SEPOLIA,
    arbitrumOne: ARBITRUM_ONE,
    sepolia: SEPOLIA,
    local: LOCAL,
} as const;

/**
 * Get network by chain ID
 * @param chainId - Chain ID to look up
 * @returns Network config or undefined
 */
export function getNetworkByChainId(chainId: number): NetworkConfig | undefined {
    return Object.values(NETWORKS).find((n) => n.chainId === chainId);
}
