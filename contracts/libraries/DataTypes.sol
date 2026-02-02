// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title DataTypes
 * @author Credora Team
 * @notice Common data structures used across the protocol
 */
library DataTypes {
    /*//////////////////////////////////////////////////////////////
                            SCORE STRUCTURES
    //////////////////////////////////////////////////////////////*/

    /// @notice Credit score data stored on-chain
    struct CreditScore {
        uint256 score;          // 0-1000 scale
        uint256 lastUpdated;    // Timestamp of last update
        uint256 dataVersion;    // Version of the scoring algorithm
        bytes32 scoreProof;     // Hash for ZK verification (future)
        uint256 updateCount;    // Number of times score has been updated
    }

    /// @notice Score history entry for tracking changes
    struct ScoreHistory {
        uint256 score;
        uint256 timestamp;
        bytes32 transactionHash;
        address updatedBy;
    }

    /// @notice Score calculation input data
    struct ScoreInput {
        uint256 walletAge;          // Days since first transaction
        uint256 transactionVolume;  // Total volume in wei
        uint256 repaidLoans;        // Count of repaid loans
        uint256 totalLoans;         // Count of total loans
        uint256 uniqueProtocols;    // Count of unique protocols
        bytes32 dataHash;           // Hash of raw data
    }

    /// @notice Score calculation output
    struct ScoreOutput {
        uint256 totalScore;
        uint256 walletAgeScore;
        uint256 volumeScore;
        uint256 repaymentScore;
        uint256 diversityScore;
        uint256 calculatedAt;
    }

    /*//////////////////////////////////////////////////////////////
                          PERMISSION STRUCTURES
    //////////////////////////////////////////////////////////////*/

    /// @notice Access permission granted to a protocol
    struct Permission {
        address protocol;
        uint256 grantedAt;
        uint256 expiresAt;
        uint256 maxRequests;
        uint256 usedRequests;
        PermissionStatus status;
        bytes32 permissionHash;
    }

    /// @notice Permission status enum
    enum PermissionStatus {
        None,
        Active,
        Expired,
        Revoked
    }

    /*//////////////////////////////////////////////////////////////
                           ORACLE STRUCTURES
    //////////////////////////////////////////////////////////////*/

    /// @notice Oracle update request
    struct UpdateRequest {
        uint256 requestId;
        address user;
        uint256 requestedAt;
        RequestStatus status;
    }

    /// @notice Request status enum
    enum RequestStatus {
        Pending,
        Fulfilled,
        Cancelled,
        Expired
    }

    /// @notice Signed score update from oracle
    struct SignedUpdate {
        address user;
        uint256 score;
        uint256 timestamp;
        uint256 nonce;
        bytes32 dataHash;
        bytes signature;
    }

    /*//////////////////////////////////////////////////////////////
                          RECOVERY STRUCTURES
    //////////////////////////////////////////////////////////////*/

    /// @notice Recovery request for soulbound token
    struct RecoveryRequest {
        address initiatedBy;
        uint256 initiatedAt;
        uint256 completableAt;
        bool cancelled;
    }

    /*//////////////////////////////////////////////////////////////
                            TIER STRUCTURES
    //////////////////////////////////////////////////////////////*/

    /// @notice Score tier definition
    struct ScoreTier {
        uint8 tier;
        uint256 minScore;
        uint256 maxScore;
        string name;
    }
}
