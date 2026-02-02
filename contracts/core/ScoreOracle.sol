// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {IScoreOracle} from "../interfaces/IScoreOracle.sol";
import {ScoreSBT} from "./ScoreSBT.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title ScoreOracle
 * @author Credora Team
 * @notice Oracle system for updating credit scores with signature verification
 * @dev Supports multiple authorized oracles with rate limiting
 *
 * Key Features:
 * - Multi-oracle support with consensus (optional)
 * - Signature verification for updates
 * - Rate limiting to prevent manipulation
 * - Request queue for score updates
 */
contract ScoreOracle is Ownable, ReentrancyGuard, IScoreOracle {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Default minimum update interval (1 hour)
    uint256 public constant DEFAULT_MIN_UPDATE_INTERVAL = 1 hours;

    /// @notice Maximum allowed score
    uint256 public constant MAX_SCORE = 1000;

    /// @notice Request expiration time (24 hours)
    uint256 public constant REQUEST_EXPIRATION = 24 hours;

    /// @notice Domain separator for EIP-712
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @notice Score update type hash for EIP-712
    bytes32 public constant SCORE_UPDATE_TYPEHASH = keccak256(
        "ScoreUpdate(address user,uint256 score,uint256 timestamp,uint256 nonce,bytes32 dataHash)"
    );

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Reference to the ScoreSBT contract
    ScoreSBT public immutable scoreSBT;

    /// @notice Mapping of authorized oracles
    mapping(address => bool) public authorizedOracles;

    /// @notice Array of authorized oracle addresses
    address[] public oracleList;

    /// @notice Minimum interval between updates per user
    uint256 public minUpdateInterval;

    /// @notice Last update timestamp per user
    mapping(address => uint256) public lastUpdateTime;

    /// @notice Nonce per user for replay protection
    mapping(address => uint256) public nonces;

    /// @notice Request ID counter
    uint256 private _requestIdCounter;

    /// @notice Pending update requests
    mapping(uint256 => DataTypes.UpdateRequest) public updateRequests;

    /// @notice User to pending request ID
    mapping(address => uint256) public pendingRequestId;

    /// @notice Required consensus (number of oracles that must agree)
    uint256 public requiredConsensus;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the ScoreOracle contract
     * @param _scoreSBT Address of the ScoreSBT contract
     * @param initialOwner Initial owner address
     * @param initialOracles Array of initial oracle addresses
     */
    constructor(
        address _scoreSBT,
        address initialOwner,
        address[] memory initialOracles
    ) Ownable(initialOwner) {
        require(_scoreSBT != address(0), "Invalid ScoreSBT address");

        scoreSBT = ScoreSBT(_scoreSBT);
        minUpdateInterval = DEFAULT_MIN_UPDATE_INTERVAL;
        requiredConsensus = 1; // Default: single oracle is sufficient
        _requestIdCounter = 1;

        // Build domain separator for EIP-712
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Credora Score Oracle")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        // Add initial oracles
        for (uint256 i = 0; i < initialOracles.length; i++) {
            if (initialOracles[i] != address(0)) {
                authorizedOracles[initialOracles[i]] = true;
                oracleList.push(initialOracles[i]);
                emit OracleAdded(initialOracles[i]);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Restrict to authorized oracles
    modifier onlyOracle() {
        if (!authorizedOracles[msg.sender]) revert OracleNotAuthorized();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        SCORE UPDATE REQUESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IScoreOracle
     */
    function requestScoreUpdate(address user) external returns (uint256 requestId) {
        require(user != address(0), "Invalid user address");
        require(scoreSBT.hasSoulboundToken(user), "User has no SBT");

        // Check if there's already a pending request
        uint256 existingRequestId = pendingRequestId[user];
        if (existingRequestId > 0) {
            DataTypes.UpdateRequest storage existing = updateRequests[existingRequestId];
            if (existing.status == DataTypes.RequestStatus.Pending) {
                // Check if expired
                if (block.timestamp <= existing.requestedAt + REQUEST_EXPIRATION) {
                    return existingRequestId; // Return existing pending request
                }
                // Mark as expired
                existing.status = DataTypes.RequestStatus.Expired;
            }
        }

        requestId = _requestIdCounter++;

        updateRequests[requestId] = DataTypes.UpdateRequest({
            requestId: requestId,
            user: user,
            requestedAt: block.timestamp,
            status: DataTypes.RequestStatus.Pending
        });

        pendingRequestId[user] = requestId;

        emit ScoreUpdateRequested(user, requestId);
    }

    /**
     * @inheritdoc IScoreOracle
     */
    function submitScoreUpdate(
        ScoreUpdate calldata update,
        bytes calldata signature
    ) external onlyOracle nonReentrant {
        // Validate score range
        if (update.score > MAX_SCORE) revert ScoreOutOfRange();

        // Validate nonce
        if (update.nonce != nonces[update.user]) revert InvalidNonce();

        // Validate update frequency
        if (block.timestamp < lastUpdateTime[update.user] + minUpdateInterval) {
            revert UpdateTooFrequent();
        }

        // Verify signature
        bytes32 structHash = keccak256(
            abi.encode(
                SCORE_UPDATE_TYPEHASH,
                update.user,
                update.score,
                update.timestamp,
                update.nonce,
                update.dataHash
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );

        address signer = digest.recover(signature);
        if (!authorizedOracles[signer]) revert InvalidSignature();

        // Get user's token ID
        uint256 tokenId = scoreSBT.getTokenIdByAddress(update.user);
        require(tokenId > 0, "User has no SBT");

        // Update the score
        scoreSBT.updateScore(
            tokenId,
            update.score,
            1, // dataVersion
            update.dataHash
        );

        // Update state
        lastUpdateTime[update.user] = block.timestamp;
        nonces[update.user]++;

        // Update request status if exists
        uint256 requestId = pendingRequestId[update.user];
        if (requestId > 0 && updateRequests[requestId].status == DataTypes.RequestStatus.Pending) {
            updateRequests[requestId].status = DataTypes.RequestStatus.Fulfilled;
        }

        emit ScoreUpdated(
            update.user,
            update.score,
            update.dataHash,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * @notice Submit score update directly (for trusted oracles, no signature)
     * @param user The user to update
     * @param score The new score
     * @param dataHash Hash of the calculation data
     */
    function submitScoreUpdateDirect(
        address user,
        uint256 score,
        bytes32 dataHash
    ) external onlyOracle nonReentrant {
        if (score > MAX_SCORE) revert ScoreOutOfRange();

        if (block.timestamp < lastUpdateTime[user] + minUpdateInterval) {
            revert UpdateTooFrequent();
        }

        uint256 tokenId = scoreSBT.getTokenIdByAddress(user);
        require(tokenId > 0, "User has no SBT");

        scoreSBT.updateScore(tokenId, score, 1, dataHash);

        lastUpdateTime[user] = block.timestamp;
        nonces[user]++;

        uint256 requestId = pendingRequestId[user];
        if (requestId > 0 && updateRequests[requestId].status == DataTypes.RequestStatus.Pending) {
            updateRequests[requestId].status = DataTypes.RequestStatus.Fulfilled;
        }

        emit ScoreUpdated(user, score, dataHash, msg.sender, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                        ORACLE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IScoreOracle
     */
    function addOracle(address oracle) external onlyOwner {
        require(oracle != address(0), "Invalid oracle address");
        require(!authorizedOracles[oracle], "Oracle already authorized");

        authorizedOracles[oracle] = true;
        oracleList.push(oracle);

        emit OracleAdded(oracle);
    }

    /**
     * @inheritdoc IScoreOracle
     */
    function removeOracle(address oracle) external onlyOwner {
        require(authorizedOracles[oracle], "Oracle not authorized");

        authorizedOracles[oracle] = false;

        // Remove from list
        for (uint256 i = 0; i < oracleList.length; i++) {
            if (oracleList[i] == oracle) {
                oracleList[i] = oracleList[oracleList.length - 1];
                oracleList.pop();
                break;
            }
        }

        emit OracleRemoved(oracle);
    }

    /**
     * @inheritdoc IScoreOracle
     */
    function setMinUpdateInterval(uint256 interval) external onlyOwner {
        require(interval >= 1 minutes, "Interval too short");
        require(interval <= 30 days, "Interval too long");

        minUpdateInterval = interval;
    }

    /**
     * @notice Set required consensus for multi-oracle updates
     * @param consensus Number of oracles required to agree
     */
    function setRequiredConsensus(uint256 consensus) external onlyOwner {
        require(consensus > 0, "Consensus must be > 0");
        require(consensus <= oracleList.length, "Consensus exceeds oracle count");

        requiredConsensus = consensus;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IScoreOracle
     */
    function isAuthorizedOracle(address oracle) external view returns (bool) {
        return authorizedOracles[oracle];
    }

    /**
     * @inheritdoc IScoreOracle
     */
    function getMinUpdateInterval() external view returns (uint256) {
        return minUpdateInterval;
    }

    /**
     * @inheritdoc IScoreOracle
     */
    function getLastUpdateTime(address user) external view returns (uint256) {
        return lastUpdateTime[user];
    }

    /**
     * @inheritdoc IScoreOracle
     */
    function getPendingUpdateNonce(address user) external view returns (uint256) {
        return nonces[user];
    }

    /**
     * @notice Get the count of authorized oracles
     * @return count Number of authorized oracles
     */
    function getOracleCount() external view returns (uint256 count) {
        return oracleList.length;
    }

    /**
     * @notice Get all authorized oracles
     * @return oracles Array of oracle addresses
     */
    function getOracles() external view returns (address[] memory oracles) {
        return oracleList;
    }

    /**
     * @notice Check if user can receive an update
     * @param user The user to check
     * @return canUpdate True if update is allowed
     */
    function canUpdate(address user) external view returns (bool canUpdate) {
        return block.timestamp >= lastUpdateTime[user] + minUpdateInterval;
    }

    /**
     * @notice Get request details
     * @param requestId The request ID
     * @return request The update request
     */
    function getRequest(uint256 requestId) external view returns (DataTypes.UpdateRequest memory request) {
        return updateRequests[requestId];
    }
}
