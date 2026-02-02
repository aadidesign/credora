// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title PermissionLogic
 * @author Credora Team
 * @notice Library for permission management logic
 * @dev Provides utilities for permission hash generation and validation
 */
library PermissionLogic {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Minimum permission duration (1 hour)
    uint256 public constant MIN_DURATION = 1 hours;

    /// @notice Maximum permission duration (365 days)
    uint256 public constant MAX_DURATION = 365 days;

    /// @notice Maximum requests per permission
    uint256 public constant MAX_REQUESTS = 1_000_000;

    /// @notice Domain separator type hash
    bytes32 public constant PERMISSION_TYPEHASH = keccak256(
        "Permission(address user,address protocol,uint256 expiresAt,uint256 maxRequests,uint256 nonce)"
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when duration is out of valid range
    error InvalidDuration();

    /// @notice Thrown when max requests exceeds limit
    error InvalidMaxRequests();

    /// @notice Thrown when permission has expired
    error PermissionExpired();

    /// @notice Thrown when permission is not yet active
    error PermissionNotActive();

    /// @notice Thrown when quota has been exhausted
    error QuotaExhausted();

    /*//////////////////////////////////////////////////////////////
                              STRUCTURES
    //////////////////////////////////////////////////////////////*/

    /// @notice Permission data used for hash generation
    struct PermissionParams {
        address user;
        address protocol;
        uint256 grantedAt;
        uint256 expiresAt;
        uint256 maxRequests;
        uint256 nonce;
    }

    /*//////////////////////////////////////////////////////////////
                         HASH GENERATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Generate a unique permission hash
     * @param params The permission parameters
     * @return hash The computed permission hash
     */
    function generatePermissionHash(
        PermissionParams memory params
    ) internal pure returns (bytes32 hash) {
        hash = keccak256(
            abi.encodePacked(
                PERMISSION_TYPEHASH,
                params.user,
                params.protocol,
                params.grantedAt,
                params.expiresAt,
                params.maxRequests,
                params.nonce
            )
        );
    }

    /**
     * @notice Generate a simple permission ID
     * @param user The user granting permission
     * @param protocol The protocol receiving permission
     * @param timestamp The grant timestamp
     * @return id The permission ID
     */
    function generatePermissionId(
        address user,
        address protocol,
        uint256 timestamp
    ) internal pure returns (bytes32 id) {
        id = keccak256(abi.encodePacked(user, protocol, timestamp));
    }

    /**
     * @notice Generate proof hash for score access
     * @dev Used by protocols to prove they have permission
     * @param user The user whose score is being accessed
     * @param protocol The protocol accessing the score
     * @param permissionHash The original permission hash
     * @param timestamp Current timestamp
     * @return proof The access proof hash
     */
    function generateAccessProof(
        address user,
        address protocol,
        bytes32 permissionHash,
        uint256 timestamp
    ) internal pure returns (bytes32 proof) {
        proof = keccak256(abi.encodePacked(user, protocol, permissionHash, timestamp));
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Validate permission duration
     * @param duration The duration to validate
     * @return valid True if duration is valid
     */
    function validateDuration(uint256 duration) internal pure returns (bool valid) {
        return duration >= MIN_DURATION && duration <= MAX_DURATION;
    }

    /**
     * @notice Validate max requests
     * @param maxRequests The max requests to validate
     * @return valid True if max requests is valid
     */
    function validateMaxRequests(uint256 maxRequests) internal pure returns (bool valid) {
        return maxRequests > 0 && maxRequests <= MAX_REQUESTS;
    }

    /**
     * @notice Check if permission is currently active
     * @param grantedAt When the permission was granted
     * @param expiresAt When the permission expires
     * @param currentTime Current block timestamp
     * @return active True if permission is active
     */
    function isActive(
        uint256 grantedAt,
        uint256 expiresAt,
        uint256 currentTime
    ) internal pure returns (bool active) {
        return currentTime >= grantedAt && currentTime < expiresAt;
    }

    /**
     * @notice Check if quota is available
     * @param usedRequests Number of requests already used
     * @param maxRequests Maximum allowed requests
     * @return available True if quota is available
     */
    function hasQuota(
        uint256 usedRequests,
        uint256 maxRequests
    ) internal pure returns (bool available) {
        return usedRequests < maxRequests;
    }

    /**
     * @notice Full permission validation
     * @param grantedAt When granted
     * @param expiresAt When expires
     * @param usedRequests Requests used
     * @param maxRequests Max requests
     * @param currentTime Current time
     * @return valid True if permission is fully valid
     */
    function validatePermission(
        uint256 grantedAt,
        uint256 expiresAt,
        uint256 usedRequests,
        uint256 maxRequests,
        uint256 currentTime
    ) internal pure returns (bool valid) {
        return isActive(grantedAt, expiresAt, currentTime) && hasQuota(usedRequests, maxRequests);
    }

    /*//////////////////////////////////////////////////////////////
                         UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculate remaining quota
     * @param usedRequests Requests already used
     * @param maxRequests Maximum requests allowed
     * @return remaining Number of requests remaining
     */
    function remainingQuota(
        uint256 usedRequests,
        uint256 maxRequests
    ) internal pure returns (uint256 remaining) {
        if (usedRequests >= maxRequests) return 0;
        return maxRequests - usedRequests;
    }

    /**
     * @notice Calculate remaining time
     * @param expiresAt Expiration timestamp
     * @param currentTime Current timestamp
     * @return remaining Seconds remaining, or 0 if expired
     */
    function remainingTime(
        uint256 expiresAt,
        uint256 currentTime
    ) internal pure returns (uint256 remaining) {
        if (currentTime >= expiresAt) return 0;
        return expiresAt - currentTime;
    }

    /**
     * @notice Calculate expiration timestamp from duration
     * @param currentTime Current timestamp
     * @param duration Duration in seconds
     * @return expiresAt Expiration timestamp
     */
    function calculateExpiration(
        uint256 currentTime,
        uint256 duration
    ) internal pure returns (uint256 expiresAt) {
        return currentTime + duration;
    }
}
