/**
 * @title Credora SDK Types
 * @description TypeScript type definitions for Credora protocol
 */

/**
 * Credit score data structure
 */
export interface CreditScore {
    /** Score value (0-1000) */
    score: bigint;
    /** Timestamp of last update */
    lastUpdated: bigint;
    /** Version of scoring algorithm used */
    dataVersion: bigint;
    /** Proof hash for ZK verification */
    scoreProof: string;
    /** Number of times score has been updated */
    updateCount: bigint;
}

/**
 * Access permission structure
 */
export interface AccessPermission {
    /** Protocol address */
    protocol: string;
    /** When permission was granted */
    grantedAt: bigint;
    /** When permission expires */
    expiresAt: bigint;
    /** Maximum allowed requests */
    maxRequests: bigint;
    /** Requests already used */
    usedRequests: bigint;
    /** Whether permission is active */
    isActive: boolean;
    /** Unique permission hash */
    permissionHash: string;
}

/**
 * Wallet data for scoring
 */
export interface WalletData {
    /** Unix timestamp of first transaction */
    firstTransactionTime: bigint;
    /** Total number of transactions */
    totalTransactionCount: bigint;
    /** Total transaction volume in wei */
    totalVolumeWei: bigint;
    /** Unix timestamp of last activity */
    lastActiveTime: bigint;
}

/**
 * DeFi interaction data for scoring
 */
export interface DeFiData {
    /** Total number of loans taken */
    totalLoansCount: bigint;
    /** Number of successfully repaid loans */
    repaidLoansCount: bigint;
    /** Number of defaulted loans */
    defaultedLoansCount: bigint;
    /** Total amount borrowed in wei */
    totalBorrowedWei: bigint;
    /** Total amount repaid in wei */
    totalRepaidWei: bigint;
    /** Number of unique protocols interacted with */
    uniqueProtocolsUsed: bigint;
}

/**
 * Score calculation output
 */
export interface ScoreOutput {
    /** Total calculated score */
    totalScore: bigint;
    /** Wallet age component score */
    walletAgeScore: bigint;
    /** Transaction volume component score */
    volumeScore: bigint;
    /** Repayment history component score */
    repaymentScore: bigint;
    /** Protocol diversity component score */
    diversityScore: bigint;
    /** Calculation timestamp */
    calculatedAt: bigint;
}

/**
 * Score tier information
 */
export interface ScoreTier {
    /** Tier level (0-3) */
    tier: number;
    /** Tier name */
    name: string;
    /** Minimum score for this tier */
    minScore: number;
    /** Maximum score for this tier */
    maxScore: number;
    /** Description of tier benefits */
    description: string;
}

/**
 * Contract addresses configuration
 */
export interface ContractAddresses {
    scoreSBT: string;
    scoreOracle: string;
    permissionManager: string;
    simpleScoring?: string;
    advancedScoring?: string;
    dataProvider?: string;
}

/**
 * Network configuration
 */
export interface NetworkConfig {
    chainId: number;
    name: string;
    rpcUrl: string;
    blockExplorer: string;
    contracts: ContractAddresses;
}

/**
 * SDK configuration options
 */
export interface CredoraConfig {
    /** Network to connect to */
    network: NetworkConfig;
    /** Optional signer for write operations */
    signer?: unknown;
    /** Optional provider for read operations */
    provider?: unknown;
}

/**
 * Permission grant options
 */
export interface GrantAccessOptions {
    /** Protocol address to grant access to */
    protocol: string;
    /** Duration in seconds */
    duration: number;
    /** Maximum number of requests */
    maxRequests: number;
}

/**
 * Score update request
 */
export interface ScoreUpdateRequest {
    /** User address */
    user: string;
    /** New score value */
    score: number;
    /** Data hash for verification */
    dataHash: string;
}

/**
 * Transaction result
 */
export interface TransactionResult {
    /** Transaction hash */
    hash: string;
    /** Whether transaction was successful */
    success: boolean;
    /** Block number */
    blockNumber: number;
    /** Gas used */
    gasUsed: bigint;
}

/**
 * Score tier thresholds
 */
export const SCORE_TIERS: ScoreTier[] = [
    {
        tier: 0,
        name: "Newcomer",
        minScore: 0,
        maxScore: 299,
        description: "New to DeFi with minimal history"
    },
    {
        tier: 1,
        name: "Established",
        minScore: 300,
        maxScore: 549,
        description: "Some DeFi experience with moderate history"
    },
    {
        tier: 2,
        name: "Trusted",
        minScore: 550,
        maxScore: 749,
        description: "Solid track record in DeFi"
    },
    {
        tier: 3,
        name: "Prime",
        minScore: 750,
        maxScore: 1000,
        description: "Excellent credit history and reputation"
    }
];

/**
 * Get tier for a given score
 */
export function getScoreTier(score: number): ScoreTier {
    for (const tier of SCORE_TIERS) {
        if (score >= tier.minScore && score <= tier.maxScore) {
            return tier;
        }
    }
    return SCORE_TIERS[0];
}
