// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IPermissionManager} from "../interfaces/IPermissionManager.sol";
import {PermissionLogic} from "../libraries/PermissionLogic.sol";
import {ScoreSBT} from "./ScoreSBT.sol";

/**
 * @title PermissionManager
 * @author Credora Team
 * @notice Manages access permissions for protocols to query user credit scores
 * @dev Implements time-limited, quota-based permission system
 *
 * Key Features:
 * - User-controlled permission grants
 * - Time-limited access
 * - Request quota enforcement
 * - Protocol whitelisting (optional)
 */
contract PermissionManager is Ownable, ReentrancyGuard, IPermissionManager {
    using EnumerableSet for EnumerableSet.AddressSet;
    using PermissionLogic for PermissionLogic.PermissionParams;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Minimum permission duration (1 hour)
    uint256 public constant MIN_DURATION = 1 hours;

    /// @notice Maximum permission duration (365 days)
    uint256 public constant MAX_DURATION = 365 days;

    /// @notice Maximum requests per permission
    uint256 public constant MAX_REQUESTS = 1_000_000;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Reference to the ScoreSBT contract
    ScoreSBT public immutable scoreSBT;

    /// @notice Permissions: user => protocol => permission
    mapping(address => mapping(address => AccessPermission)) private _permissions;

    /// @notice List of protocols with permission per user
    mapping(address => EnumerableSet.AddressSet) private _userProtocols;

    /// @notice Nonce per user for unique permission hashes
    mapping(address => uint256) private _permissionNonces;

    /// @notice Whitelisted protocols (optional feature)
    mapping(address => bool) public whitelistedProtocols;

    /// @notice Whether protocol whitelisting is enabled
    bool public whitelistEnabled;

    /// @notice Authorized consumers (contracts that can call consumeAccess)
    mapping(address => bool) public authorizedConsumers;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the whitelist status changes
    event WhitelistStatusChanged(bool enabled);

    /// @notice Emitted when a protocol is whitelisted or removed
    event ProtocolWhitelistChanged(address indexed protocol, bool whitelisted);

    /// @notice Emitted when an authorized consumer is added or removed
    event AuthorizedConsumerChanged(address indexed consumer, bool authorized);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the PermissionManager contract
     * @param _scoreSBT Address of the ScoreSBT contract
     * @param initialOwner Initial owner address
     */
    constructor(address _scoreSBT, address initialOwner) Ownable(initialOwner) {
        require(_scoreSBT != address(0), "Invalid ScoreSBT address");
        scoreSBT = ScoreSBT(_scoreSBT);
        whitelistEnabled = false;
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Restrict to users with SBT
    modifier onlyScoreOwner() {
        require(scoreSBT.hasSoulboundToken(msg.sender), "No credit score SBT");
        _;
    }

    /// @notice Validate protocol address
    modifier validProtocol(address protocol) {
        if (protocol == address(0)) revert InvalidProtocol();
        if (whitelistEnabled && !whitelistedProtocols[protocol]) revert InvalidProtocol();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                       PERMISSION MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IPermissionManager
     */
    function grantAccess(
        address protocol,
        uint256 duration,
        uint256 maxRequests
    ) external onlyScoreOwner validProtocol(protocol) nonReentrant returns (bytes32 permissionId) {
        // Validate duration
        if (duration < MIN_DURATION || duration > MAX_DURATION) revert InvalidDuration();

        // Validate max requests
        if (maxRequests == 0 || maxRequests > MAX_REQUESTS) revert InvalidDuration();

        uint256 currentNonce = _permissionNonces[msg.sender]++;
        uint256 expiresAt = block.timestamp + duration;

        // Generate permission hash
        PermissionLogic.PermissionParams memory params = PermissionLogic.PermissionParams({
            user: msg.sender,
            protocol: protocol,
            grantedAt: block.timestamp,
            expiresAt: expiresAt,
            maxRequests: maxRequests,
            nonce: currentNonce
        });

        permissionId = params.generatePermissionHash();

        // Store permission
        _permissions[msg.sender][protocol] = AccessPermission({
            protocol: protocol,
            grantedAt: block.timestamp,
            expiresAt: expiresAt,
            maxRequests: maxRequests,
            usedRequests: 0,
            isActive: true,
            permissionHash: permissionId
        });

        // Add to user's protocol list
        _userProtocols[msg.sender].add(protocol);

        emit AccessGranted(msg.sender, protocol, expiresAt, maxRequests, permissionId);
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function revokeAccess(address protocol) external onlyScoreOwner nonReentrant {
        AccessPermission storage permission = _permissions[msg.sender][protocol];

        if (!permission.isActive) revert PermissionNotFound();

        bytes32 permissionId = permission.permissionHash;
        permission.isActive = false;

        _userProtocols[msg.sender].remove(protocol);

        emit AccessRevoked(msg.sender, protocol, permissionId);
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function consumeAccess(
        address user,
        address protocol
    ) external nonReentrant returns (bool valid) {
        // Only authorized consumers or the protocol itself can consume access
        require(
            msg.sender == protocol || authorizedConsumers[msg.sender],
            "Unauthorized consumer"
        );

        AccessPermission storage permission = _permissions[user][protocol];

        // Check if permission exists and is active
        if (!permission.isActive) return false;

        // Check expiration
        if (block.timestamp >= permission.expiresAt) {
            permission.isActive = false;
            return false;
        }

        // Check quota
        if (permission.usedRequests >= permission.maxRequests) {
            return false;
        }

        // Consume one request
        permission.usedRequests++;

        uint256 remaining = permission.maxRequests - permission.usedRequests;
        emit AccessUsed(user, protocol, remaining);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IPermissionManager
     */
    function getPermission(
        address user,
        address protocol
    ) external view returns (AccessPermission memory) {
        return _permissions[user][protocol];
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function hasValidPermission(
        address user,
        address protocol
    ) external view returns (bool) {
        AccessPermission storage permission = _permissions[user][protocol];

        return permission.isActive &&
               block.timestamp < permission.expiresAt &&
               permission.usedRequests < permission.maxRequests;
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function getRemainingQuota(
        address user,
        address protocol
    ) external view returns (uint256) {
        AccessPermission storage permission = _permissions[user][protocol];

        if (!permission.isActive || block.timestamp >= permission.expiresAt) {
            return 0;
        }

        if (permission.usedRequests >= permission.maxRequests) {
            return 0;
        }

        return permission.maxRequests - permission.usedRequests;
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function getPermissionHash(
        address user,
        address protocol
    ) external view returns (bytes32) {
        return _permissions[user][protocol].permissionHash;
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function getAllPermissions(
        address user
    ) external view returns (AccessPermission[] memory permissions) {
        uint256 count = _userProtocols[user].length();
        permissions = new AccessPermission[](count);

        for (uint256 i = 0; i < count; i++) {
            address protocol = _userProtocols[user].at(i);
            permissions[i] = _permissions[user][protocol];
        }
    }

    /**
     * @notice Get the number of protocols with permission
     * @param user The user to query
     * @return count Number of protocols
     */
    function getPermissionCount(address user) external view returns (uint256 count) {
        return _userProtocols[user].length();
    }

    /**
     * @notice Get remaining time for a permission
     * @param user The user to query
     * @param protocol The protocol to query
     * @return remaining Seconds remaining, or 0 if expired
     */
    function getRemainingTime(
        address user,
        address protocol
    ) external view returns (uint256 remaining) {
        AccessPermission storage permission = _permissions[user][protocol];

        if (!permission.isActive || block.timestamp >= permission.expiresAt) {
            return 0;
        }

        return permission.expiresAt - block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                         ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Enable or disable protocol whitelisting
     * @param enabled Whether whitelisting is enabled
     */
    function setWhitelistEnabled(bool enabled) external onlyOwner {
        whitelistEnabled = enabled;
        emit WhitelistStatusChanged(enabled);
    }

    /**
     * @notice Add or remove a protocol from the whitelist
     * @param protocol The protocol address
     * @param whitelisted Whether to whitelist
     */
    function setProtocolWhitelist(address protocol, bool whitelisted) external onlyOwner {
        require(protocol != address(0), "Invalid protocol");
        whitelistedProtocols[protocol] = whitelisted;
        emit ProtocolWhitelistChanged(protocol, whitelisted);
    }

    /**
     * @notice Add or remove an authorized consumer
     * @param consumer The consumer address
     * @param authorized Whether to authorize
     */
    function setAuthorizedConsumer(address consumer, bool authorized) external onlyOwner {
        require(consumer != address(0), "Invalid consumer");
        authorizedConsumers[consumer] = authorized;
        emit AuthorizedConsumerChanged(consumer, authorized);
    }

    /**
     * @notice Batch whitelist protocols
     * @param protocols Array of protocol addresses
     * @param whitelisted Whether to whitelist
     */
    function batchSetProtocolWhitelist(
        address[] calldata protocols,
        bool whitelisted
    ) external onlyOwner {
        for (uint256 i = 0; i < protocols.length; i++) {
            if (protocols[i] != address(0)) {
                whitelistedProtocols[protocols[i]] = whitelisted;
                emit ProtocolWhitelistChanged(protocols[i], whitelisted);
            }
        }
    }
}
