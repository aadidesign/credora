// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IPermissionManager
 * @author Credora Team
 * @notice Interface for the permission management system
 */
interface IPermissionManager {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error PermissionNotFound();
    error PermissionExpired();
    error QuotaExceeded();
    error UnauthorizedCaller();
    error InvalidDuration();
    error InvalidProtocol();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event AccessGranted(
        address indexed user,
        address indexed protocol,
        uint256 expiresAt,
        uint256 maxRequests,
        bytes32 indexed requestId
    );

    event AccessRevoked(
        address indexed user,
        address indexed protocol,
        bytes32 indexed requestId
    );

    event AccessUsed(
        address indexed user,
        address indexed protocol,
        uint256 remainingRequests
    );

    /*//////////////////////////////////////////////////////////////
                              STRUCTURES
    //////////////////////////////////////////////////////////////*/

    struct AccessPermission {
        address protocol;
        uint256 grantedAt;
        uint256 expiresAt;
        uint256 maxRequests;
        uint256 usedRequests;
        bool isActive;
        bytes32 permissionHash;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getPermission(
        address user,
        address protocol
    ) external view returns (AccessPermission memory);

    function hasValidPermission(
        address user,
        address protocol
    ) external view returns (bool);

    function getRemainingQuota(
        address user,
        address protocol
    ) external view returns (uint256);

    function getPermissionHash(
        address user,
        address protocol
    ) external view returns (bytes32);

    function getAllPermissions(
        address user
    ) external view returns (AccessPermission[] memory);

    /*//////////////////////////////////////////////////////////////
                           WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function grantAccess(
        address protocol,
        uint256 duration,
        uint256 maxRequests
    ) external returns (bytes32 permissionId);

    function revokeAccess(address protocol) external;

    function consumeAccess(
        address user,
        address protocol
    ) external returns (bool valid);
}
