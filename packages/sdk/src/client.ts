/**
 * @title Credora SDK Client
 * @description Main client for interacting with Credora protocol
 */

import { ethers, Contract, Signer, Provider, ContractTransactionResponse } from "ethers";
import {
    CreditScore,
    AccessPermission,
    CredoraConfig,
    GrantAccessOptions,
    TransactionResult,
    getScoreTier,
    ScoreTier,
} from "./types";
import { SCORE_SBT_ABI, PERMISSION_MANAGER_ABI, SCORE_ORACLE_ABI } from "./abis";

/**
 * Credora SDK Client
 * @example
 * ```typescript
 * const client = new CredoraClient({
 *   network: NETWORKS.arbitrumSepolia,
 *   signer: wallet
 * });
 *
 * // Get user's score
 * const score = await client.getScore(userAddress);
 *
 * // Grant protocol access
 * await client.grantAccess({
 *   protocol: lendingProtocol,
 *   duration: 30 * 24 * 60 * 60, // 30 days
 *   maxRequests: 1000
 * });
 * ```
 */
export class CredoraClient {
    private readonly config: CredoraConfig;
    private readonly provider: Provider;
    private readonly signer?: Signer;

    private scoreSBT: Contract;
    private permissionManager: Contract;
    private scoreOracle: Contract;

    /**
     * Create a new Credora client
     * @param config - Client configuration
     */
    constructor(config: CredoraConfig) {
        this.config = config;

        if (config.provider) {
            this.provider = config.provider as Provider;
        } else {
            this.provider = new ethers.JsonRpcProvider(config.network.rpcUrl);
        }

        if (config.signer) {
            this.signer = config.signer as Signer;
        }

        const signerOrProvider = this.signer ?? this.provider;

        this.scoreSBT = new Contract(
            config.network.contracts.scoreSBT,
            SCORE_SBT_ABI,
            signerOrProvider
        );

        this.permissionManager = new Contract(
            config.network.contracts.permissionManager,
            PERMISSION_MANAGER_ABI,
            signerOrProvider
        );

        this.scoreOracle = new Contract(
            config.network.contracts.scoreOracle,
            SCORE_ORACLE_ABI,
            signerOrProvider
        );
    }

    /*//////////////////////////////////////////////////////////////
                             SCORE QUERIES
    //////////////////////////////////////////////////////////////*/

    /**
     * Check if an address has a credit score SBT
     * @param address - Address to check
     * @returns Whether the address has an SBT
     */
    async hasSBT(address: string): Promise<boolean> {
        return this.scoreSBT.hasSoulboundToken(address);
    }

    /**
     * Get the credit score for an address
     * @param address - Address to query
     * @returns Credit score data
     */
    async getScore(address: string): Promise<CreditScore> {
        const score = await this.scoreSBT.getScoreByAddress(address);
        return {
            score: score.score,
            lastUpdated: score.lastUpdated,
            dataVersion: score.dataVersion,
            scoreProof: score.scoreProof,
            updateCount: score.updateCount,
        };
    }

    /**
     * Get just the score value for an address
     * @param address - Address to query
     * @returns Score value (0-1000)
     */
    async getScoreValue(address: string): Promise<number> {
        const score = await this.scoreSBT.getScoreValue(address);
        return Number(score);
    }

    /**
     * Get the tier for an address
     * @param address - Address to query
     * @returns Score tier information
     */
    async getTier(address: string): Promise<ScoreTier> {
        const scoreValue = await this.getScoreValue(address);
        return getScoreTier(scoreValue);
    }

    /**
     * Check if a score is stale
     * @param address - Address to check
     * @param maxAgeSeconds - Maximum acceptable age in seconds
     * @returns Whether the score is stale
     */
    async isScoreStale(address: string, maxAgeSeconds: number): Promise<boolean> {
        const tokenId = await this.scoreSBT.getTokenIdByAddress(address);
        return this.scoreSBT.isScoreStale(tokenId, maxAgeSeconds);
    }

    /**
     * Get the token ID for an address
     * @param address - Address to query
     * @returns Token ID or 0 if none
     */
    async getTokenId(address: string): Promise<bigint> {
        return this.scoreSBT.getTokenIdByAddress(address);
    }

    /*//////////////////////////////////////////////////////////////
                            SBT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Mint a credit score SBT for the connected signer
     * @returns Transaction result with token ID
     */
    async mintSBT(): Promise<TransactionResult & { tokenId: bigint }> {
        this.requireSigner();

        const tx: ContractTransactionResponse = await this.scoreSBT.mintSelf();
        const receipt = await tx.wait();

        if (!receipt) {
            throw new Error("Transaction failed");
        }

        // Parse the ScoreMinted event to get token ID
        const event = receipt.logs.find((log) => {
            try {
                const parsed = this.scoreSBT.interface.parseLog({
                    topics: log.topics as string[],
                    data: log.data,
                });
                return parsed?.name === "ScoreMinted";
            } catch {
                return false;
            }
        });

        let tokenId = BigInt(0);
        if (event) {
            const parsed = this.scoreSBT.interface.parseLog({
                topics: event.topics as string[],
                data: event.data,
            });
            tokenId = parsed?.args.tokenId ?? BigInt(0);
        }

        return {
            hash: receipt.hash,
            success: receipt.status === 1,
            blockNumber: receipt.blockNumber,
            gasUsed: receipt.gasUsed,
            tokenId,
        };
    }

    /**
     * Burn the connected signer's SBT
     * @returns Transaction result
     */
    async burnSBT(): Promise<TransactionResult> {
        this.requireSigner();

        const address = await this.signer!.getAddress();
        const tokenId = await this.getTokenId(address);

        const tx: ContractTransactionResponse = await this.scoreSBT.burn(tokenId);
        const receipt = await tx.wait();

        if (!receipt) {
            throw new Error("Transaction failed");
        }

        return {
            hash: receipt.hash,
            success: receipt.status === 1,
            blockNumber: receipt.blockNumber,
            gasUsed: receipt.gasUsed,
        };
    }

    /*//////////////////////////////////////////////////////////////
                          PERMISSION OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Grant access to a protocol
     * @param options - Grant access options
     * @returns Transaction result with permission ID
     */
    async grantAccess(
        options: GrantAccessOptions
    ): Promise<TransactionResult & { permissionId: string }> {
        this.requireSigner();

        const tx: ContractTransactionResponse = await this.permissionManager.grantAccess(
            options.protocol,
            options.duration,
            options.maxRequests
        );
        const receipt = await tx.wait();

        if (!receipt) {
            throw new Error("Transaction failed");
        }

        // Parse AccessGranted event
        const event = receipt.logs.find((log) => {
            try {
                const parsed = this.permissionManager.interface.parseLog({
                    topics: log.topics as string[],
                    data: log.data,
                });
                return parsed?.name === "AccessGranted";
            } catch {
                return false;
            }
        });

        let permissionId = "";
        if (event) {
            const parsed = this.permissionManager.interface.parseLog({
                topics: event.topics as string[],
                data: event.data,
            });
            permissionId = parsed?.args.requestId ?? "";
        }

        return {
            hash: receipt.hash,
            success: receipt.status === 1,
            blockNumber: receipt.blockNumber,
            gasUsed: receipt.gasUsed,
            permissionId,
        };
    }

    /**
     * Revoke access from a protocol
     * @param protocol - Protocol address to revoke
     * @returns Transaction result
     */
    async revokeAccess(protocol: string): Promise<TransactionResult> {
        this.requireSigner();

        const tx: ContractTransactionResponse = await this.permissionManager.revokeAccess(protocol);
        const receipt = await tx.wait();

        if (!receipt) {
            throw new Error("Transaction failed");
        }

        return {
            hash: receipt.hash,
            success: receipt.status === 1,
            blockNumber: receipt.blockNumber,
            gasUsed: receipt.gasUsed,
        };
    }

    /**
     * Get permission for a user-protocol pair
     * @param user - User address
     * @param protocol - Protocol address
     * @returns Permission data
     */
    async getPermission(user: string, protocol: string): Promise<AccessPermission> {
        const perm = await this.permissionManager.getPermission(user, protocol);
        return {
            protocol: perm.protocol,
            grantedAt: perm.grantedAt,
            expiresAt: perm.expiresAt,
            maxRequests: perm.maxRequests,
            usedRequests: perm.usedRequests,
            isActive: perm.isActive,
            permissionHash: perm.permissionHash,
        };
    }

    /**
     * Check if permission is valid
     * @param user - User address
     * @param protocol - Protocol address
     * @returns Whether permission is valid
     */
    async hasValidPermission(user: string, protocol: string): Promise<boolean> {
        return this.permissionManager.hasValidPermission(user, protocol);
    }

    /**
     * Get remaining quota for a permission
     * @param user - User address
     * @param protocol - Protocol address
     * @returns Remaining requests
     */
    async getRemainingQuota(user: string, protocol: string): Promise<bigint> {
        return this.permissionManager.getRemainingQuota(user, protocol);
    }

    /**
     * Get all permissions for a user
     * @param user - User address
     * @returns Array of permissions
     */
    async getAllPermissions(user: string): Promise<AccessPermission[]> {
        const perms = await this.permissionManager.getAllPermissions(user);
        return perms.map((perm: AccessPermission) => ({
            protocol: perm.protocol,
            grantedAt: perm.grantedAt,
            expiresAt: perm.expiresAt,
            maxRequests: perm.maxRequests,
            usedRequests: perm.usedRequests,
            isActive: perm.isActive,
            permissionHash: perm.permissionHash,
        }));
    }

    /*//////////////////////////////////////////////////////////////
                            RECOVERY OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Set recovery address for the connected signer's SBT
     * @param recoveryAddress - Address authorized for recovery
     * @returns Transaction result
     */
    async setRecoveryAddress(recoveryAddress: string): Promise<TransactionResult> {
        this.requireSigner();

        const address = await this.signer!.getAddress();
        const tokenId = await this.getTokenId(address);

        const tx: ContractTransactionResponse = await this.scoreSBT.setRecoveryAddress(
            tokenId,
            recoveryAddress
        );
        const receipt = await tx.wait();

        if (!receipt) {
            throw new Error("Transaction failed");
        }

        return {
            hash: receipt.hash,
            success: receipt.status === 1,
            blockNumber: receipt.blockNumber,
            gasUsed: receipt.gasUsed,
        };
    }

    /*//////////////////////////////////////////////////////////////
                              UTILITIES
    //////////////////////////////////////////////////////////////*/

    /**
     * Get contract addresses
     * @returns Contract addresses for current network
     */
    getContractAddresses() {
        return this.config.network.contracts;
    }

    /**
     * Get the score oracle contract instance (for requestScoreUpdate etc.)
     */
    getScoreOracleContract() {
        return this.scoreOracle;
    }

    /**
     * Get network configuration
     * @returns Current network config
     */
    getNetwork() {
        return this.config.network;
    }

    /**
     * Require a signer for write operations
     */
    private requireSigner(): void {
        if (!this.signer) {
            throw new Error("Signer required for this operation");
        }
    }
}
