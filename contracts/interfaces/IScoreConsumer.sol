// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IScoreConsumer
 * @author Credora Team
 * @notice Interface for protocols consuming credit scores
 * @dev Implement this interface to integrate with Credora scoring system
 */
interface IScoreConsumer {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when permission to access score is invalid
    error InvalidPermission();

    /// @notice Thrown when permission has expired
    error PermissionExpired();

    /// @notice Thrown when score is too stale
    error ScoreTooStale();

    /// @notice Thrown when protocol has exceeded its query quota
    error QuotaExceeded();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a score is queried by an external protocol
    /// @param user The user whose score was queried
    /// @param protocol The protocol that queried the score
    /// @param score The score value returned
    event ScoreQueried(address indexed user, address indexed protocol, uint256 score);

    /*//////////////////////////////////////////////////////////////
                              STRUCTURES
    //////////////////////////////////////////////////////////////*/

    /// @notice Score data structure returned to consumers
    struct ScoreData {
        uint256 score;          // Score value (0-1000)
        uint256 lastUpdated;    // Timestamp of last update
        uint256 dataVersion;    // Version of scoring algorithm used
        bool isValid;           // Whether the score is currently valid
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get a user's credit score with permission verification
     * @param user The user whose score is being requested
     * @param permissionProof Proof of permission to access this score
     * @return score The user's credit score (0-1000)
     * @return lastUpdated Timestamp when the score was last updated
     */
    function getScoreWithPermission(
        address user,
        bytes32 permissionProof
    ) external view returns (uint256 score, uint256 lastUpdated);

    /**
     * @notice Get detailed score data with permission verification
     * @param user The user whose score is being requested
     * @param permissionProof Proof of permission to access this score
     * @return scoreData Full score data including validity info
     */
    function getScoreDataWithPermission(
        address user,
        bytes32 permissionProof
    ) external view returns (ScoreData memory scoreData);

    /**
     * @notice Check if a protocol has valid permission to query a user's score
     * @param user The user whose permission is being checked
     * @param protocol The protocol requesting access
     * @return isValid True if permission is valid and not expired
     */
    function isValidPermission(
        address user,
        address protocol
    ) external view returns (bool isValid);

    /**
     * @notice Check if a score meets minimum freshness requirements
     * @param user The user whose score is being checked
     * @param maxAgeSeconds Maximum acceptable age of the score
     * @return isFresh True if score is within acceptable age
     */
    function isScoreFresh(
        address user,
        uint256 maxAgeSeconds
    ) external view returns (bool isFresh);

    /**
     * @notice Get the minimum score required for a specific tier
     * @param tier The tier level (0-3, where 3 is highest)
     * @return minimumScore The minimum score for the tier
     */
    function getTierThreshold(uint8 tier) external view returns (uint256 minimumScore);

    /**
     * @notice Determine user's tier based on their score
     * @param user The user to check
     * @param permissionProof Permission to access the score
     * @return tier The user's current tier (0-3)
     */
    function getUserTier(
        address user,
        bytes32 permissionProof
    ) external view returns (uint8 tier);
}
