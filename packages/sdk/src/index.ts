/**
 * @title Credora SDK
 * @description TypeScript SDK for Credora decentralized credit scoring protocol
 * @author Credora Team
 * @version 1.0.0
 */

// Main client
export { CredoraClient } from "./client";

// Types
export {
    CreditScore,
    AccessPermission,
    WalletData,
    DeFiData,
    ScoreOutput,
    ScoreTier,
    ContractAddresses,
    NetworkConfig,
    CredoraConfig,
    GrantAccessOptions,
    ScoreUpdateRequest,
    TransactionResult,
    SCORE_TIERS,
    getScoreTier,
} from "./types";

// Networks
export {
    NETWORKS,
    ARBITRUM_SEPOLIA,
    ARBITRUM_ONE,
    SEPOLIA,
    LOCAL,
    getNetworkByChainId,
} from "./networks";

// ABIs
export {
    SCORE_SBT_ABI,
    PERMISSION_MANAGER_ABI,
    SCORE_ORACLE_ABI,
    SIMPLE_SCORING_ABI,
} from "./abis";

/**
 * SDK Version
 */
export const VERSION = "1.0.0";

/**
 * Protocol constants
 */
export const CONSTANTS = {
    MAX_SCORE: 1000,
    MIN_SCORE: 0,
    MIN_PERMISSION_DURATION: 3600, // 1 hour in seconds
    MAX_PERMISSION_DURATION: 31536000, // 365 days in seconds
    MAX_REQUESTS_PER_PERMISSION: 1000000,
    RECOVERY_COOLDOWN: 604800, // 7 days in seconds
    MIN_UPDATE_INTERVAL: 3600, // 1 hour in seconds
} as const;
