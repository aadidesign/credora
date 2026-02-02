// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {ISoulbound} from "../interfaces/ISoulbound.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title ScoreSBT
 * @author Credora Team
 * @notice Soulbound Token (SBT) for credit scores - non-transferable ERC721
 * @dev Implements ERC721 with transfer restrictions and credit score storage
 *
 * Key Features:
 * - One token per address (enforced)
 * - Non-transferable (soulbound)
 * - Emergency recovery mechanism
 * - Score history tracking
 * - Permissioned score visibility
 */
contract ScoreSBT is ERC721Enumerable, Ownable, ReentrancyGuard, ISoulbound {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Recovery cooldown period (7 days)
    uint256 public constant RECOVERY_COOLDOWN = 7 days;

    /// @notice Maximum score value
    uint256 public constant MAX_SCORE = 1000;

    /// @notice Minimum update interval (1 hour)
    uint256 public constant MIN_UPDATE_INTERVAL = 1 hours;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Token ID counter
    uint256 private _tokenIdCounter;

    /// @notice Mapping from token ID to credit score data
    mapping(uint256 => DataTypes.CreditScore) private _scores;

    /// @notice Mapping from token ID to recovery address
    mapping(uint256 => address) private _recoveryAddresses;

    /// @notice Mapping from token ID to pending recovery request
    mapping(uint256 => DataTypes.RecoveryRequest) private _pendingRecoveries;

    /// @notice Mapping from address to their token ID (for quick lookup)
    mapping(address => uint256) private _addressToTokenId;

    /// @notice Mapping from address to whether they own an SBT
    mapping(address => bool) private _hasSBT;

    /// @notice Mapping of authorized score updaters (oracles)
    mapping(address => bool) public authorizedUpdaters;

    /// @notice Base URI for token metadata
    string private _baseTokenURI;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a score is minted
    event ScoreMinted(address indexed owner, uint256 indexed tokenId);

    /// @notice Emitted when a score is updated
    event ScoreUpdated(
        uint256 indexed tokenId,
        uint256 oldScore,
        uint256 newScore,
        uint256 dataVersion,
        address indexed updatedBy
    );

    /// @notice Emitted when an updater is authorized or deauthorized
    event UpdaterAuthorizationChanged(address indexed updater, bool authorized);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the ScoreSBT contract
     * @param initialOwner The initial owner of the contract
     */
    constructor(address initialOwner) ERC721("Credora Credit Score", "CRED") Ownable(initialOwner) {
        _tokenIdCounter = 1; // Start from 1 to avoid confusion with default value
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Restrict to authorized updaters only
    modifier onlyAuthorizedUpdater() {
        require(authorizedUpdaters[msg.sender] || msg.sender == owner(), "Not authorized updater");
        _;
    }

    /// @notice Restrict to token owner
    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            MINTING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint a new credit score SBT
     * @dev One SBT per address enforced
     * @param to The address to mint to
     * @return tokenId The minted token ID
     */
    function mint(address to) external nonReentrant returns (uint256 tokenId) {
        require(to != address(0), "Cannot mint to zero address");
        require(!_hasSBT[to], "Address already has SBT");

        tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);

        _hasSBT[to] = true;
        _addressToTokenId[to] = tokenId;

        // Initialize with default score
        _scores[tokenId] = DataTypes.CreditScore({
            score: 0,
            lastUpdated: block.timestamp,
            dataVersion: 1,
            scoreProof: bytes32(0),
            updateCount: 0
        });

        emit ScoreMinted(to, tokenId);
    }

    /**
     * @notice Mint SBT for yourself
     * @return tokenId The minted token ID
     */
    function mintSelf() external returns (uint256 tokenId) {
        require(!_hasSBT[msg.sender], "Already have SBT");
        return this.mint(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                           SCORE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update a user's credit score
     * @param tokenId The token to update
     * @param newScore The new score value (0-1000)
     * @param dataVersion Version of scoring algorithm used
     * @param scoreProof Proof hash for verification
     */
    function updateScore(
        uint256 tokenId,
        uint256 newScore,
        uint256 dataVersion,
        bytes32 scoreProof
    ) external onlyAuthorizedUpdater nonReentrant {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        require(newScore <= MAX_SCORE, "Score exceeds maximum");

        DataTypes.CreditScore storage score = _scores[tokenId];

        require(
            block.timestamp >= score.lastUpdated + MIN_UPDATE_INTERVAL,
            "Update too frequent"
        );

        uint256 oldScore = score.score;

        score.score = newScore;
        score.lastUpdated = block.timestamp;
        score.dataVersion = dataVersion;
        score.scoreProof = scoreProof;
        score.updateCount++;

        emit ScoreUpdated(tokenId, oldScore, newScore, dataVersion, msg.sender);
    }

    /**
     * @notice Get a user's credit score
     * @param tokenId The token to query
     * @return score The credit score data
     */
    function getScore(uint256 tokenId) external view returns (DataTypes.CreditScore memory score) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return _scores[tokenId];
    }

    /**
     * @notice Get score by address
     * @param user The address to query
     * @return score The credit score data
     */
    function getScoreByAddress(address user) external view returns (DataTypes.CreditScore memory score) {
        require(_hasSBT[user], "User has no SBT");
        return _scores[_addressToTokenId[user]];
    }

    /**
     * @notice Get just the score value for a user
     * @param user The address to query
     * @return scoreValue The score value (0-1000)
     */
    function getScoreValue(address user) external view returns (uint256 scoreValue) {
        require(_hasSBT[user], "User has no SBT");
        return _scores[_addressToTokenId[user]].score;
    }

    /**
     * @notice Get token ID for an address
     * @param user The address to query
     * @return tokenId The token ID, or 0 if none
     */
    function getTokenIdByAddress(address user) external view returns (uint256 tokenId) {
        return _addressToTokenId[user];
    }

    /*//////////////////////////////////////////////////////////////
                        SOULBOUND OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ISoulbound
     */
    function isSoulbound(uint256 tokenId) external view override returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @inheritdoc ISoulbound
     */
    function hasSoulboundToken(address account) external view override returns (bool) {
        return _hasSBT[account];
    }

    /**
     * @notice Override transfer to prevent transfers (soulbound)
     */
    function transferFrom(address, address, uint256) public pure override(ERC721, IERC721) {
        revert SoulboundTransferNotAllowed();
    }

    /**
     * @notice Override safeTransferFrom to prevent transfers
     */
    function safeTransferFrom(address, address, uint256, bytes memory) public pure override(ERC721, IERC721) {
        revert SoulboundTransferNotAllowed();
    }

    /**
     * @notice Override approve to prevent approvals
     */
    function approve(address, uint256) public pure override(ERC721, IERC721) {
        revert SoulboundApprovalNotAllowed();
    }

    /**
     * @notice Override setApprovalForAll to prevent approvals
     */
    function setApprovalForAll(address, bool) public pure override(ERC721, IERC721) {
        revert SoulboundApprovalNotAllowed();
    }

    /*//////////////////////////////////////////////////////////////
                           RECOVERY SYSTEM
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ISoulbound
     */
    function getRecoveryAddress(uint256 tokenId) external view override returns (address) {
        return _recoveryAddresses[tokenId];
    }

    /**
     * @inheritdoc ISoulbound
     */
    function setRecoveryAddress(uint256 tokenId, address recoveryAddress) external override onlyTokenOwner(tokenId) {
        require(recoveryAddress != address(0), "Invalid recovery address");
        require(recoveryAddress != msg.sender, "Cannot set self as recovery");
        require(!_hasSBT[recoveryAddress], "Recovery address has SBT");

        _recoveryAddresses[tokenId] = recoveryAddress;
        emit RecoveryAddressSet(tokenId, recoveryAddress);
    }

    /**
     * @inheritdoc ISoulbound
     */
    function initiateRecovery(uint256 tokenId) external override {
        require(_recoveryAddresses[tokenId] == msg.sender, "Not recovery address");
        require(_pendingRecoveries[tokenId].initiatedAt == 0, "Recovery already pending");

        address currentOwner = ownerOf(tokenId);

        _pendingRecoveries[tokenId] = DataTypes.RecoveryRequest({
            initiatedBy: msg.sender,
            initiatedAt: block.timestamp,
            completableAt: block.timestamp + RECOVERY_COOLDOWN,
            cancelled: false
        });

        emit RecoveryInitiated(tokenId, currentOwner, msg.sender);
    }

    /**
     * @inheritdoc ISoulbound
     */
    function completeRecovery(uint256 tokenId) external override nonReentrant {
        DataTypes.RecoveryRequest storage request = _pendingRecoveries[tokenId];

        require(request.initiatedAt > 0, "No pending recovery");
        require(!request.cancelled, "Recovery was cancelled");
        require(block.timestamp >= request.completableAt, "Cooldown not elapsed");
        require(request.initiatedBy == msg.sender, "Not recovery initiator");

        address currentOwner = ownerOf(tokenId);
        address newOwner = msg.sender;

        // Update mappings
        _hasSBT[currentOwner] = false;
        delete _addressToTokenId[currentOwner];

        _hasSBT[newOwner] = true;
        _addressToTokenId[newOwner] = tokenId;

        // Perform the transfer (bypassing soulbound restriction for recovery)
        _transfer(currentOwner, newOwner, tokenId);

        // Clear recovery state
        delete _pendingRecoveries[tokenId];
        delete _recoveryAddresses[tokenId];

        emit RecoveryCompleted(tokenId, newOwner);
    }

    /**
     * @inheritdoc ISoulbound
     */
    function cancelRecovery(uint256 tokenId) external override onlyTokenOwner(tokenId) {
        require(_pendingRecoveries[tokenId].initiatedAt > 0, "No pending recovery");

        _pendingRecoveries[tokenId].cancelled = true;
        delete _pendingRecoveries[tokenId];
    }

    /**
     * @inheritdoc ISoulbound
     */
    function burn(uint256 tokenId) external override onlyTokenOwner(tokenId) nonReentrant {
        address owner = ownerOf(tokenId);

        _hasSBT[owner] = false;
        delete _addressToTokenId[owner];
        delete _scores[tokenId];
        delete _recoveryAddresses[tokenId];
        delete _pendingRecoveries[tokenId];

        _burn(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Authorize or deauthorize a score updater
     * @param updater The address to authorize
     * @param authorized Whether to authorize or deauthorize
     */
    function setAuthorizedUpdater(address updater, bool authorized) external onlyOwner {
        authorizedUpdaters[updater] = authorized;
        emit UpdaterAuthorizationChanged(updater, authorized);
    }

    /**
     * @notice Set the base URI for token metadata
     * @param baseURI The new base URI
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get pending recovery request for a token
     * @param tokenId The token to query
     * @return request The pending recovery request
     */
    function getPendingRecovery(uint256 tokenId) external view returns (DataTypes.RecoveryRequest memory request) {
        return _pendingRecoveries[tokenId];
    }

    /**
     * @notice Check if a score is stale
     * @param tokenId The token to check
     * @param maxAge Maximum acceptable age in seconds
     * @return stale True if score is older than maxAge
     */
    function isScoreStale(uint256 tokenId, uint256 maxAge) external view returns (bool stale) {
        DataTypes.CreditScore memory score = _scores[tokenId];
        return block.timestamp > score.lastUpdated + maxAge;
    }

    /**
     * @notice Get total number of SBTs minted
     * @return count Total SBTs minted
     */
    function totalMinted() external view returns (uint256 count) {
        return _tokenIdCounter - 1;
    }

    /**
     * @dev Base URI for computing tokenURI
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Check if contract supports an interface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
