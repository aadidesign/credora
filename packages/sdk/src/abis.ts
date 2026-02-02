/**
 * @title Contract ABIs
 * @description ABI definitions for Credora contracts
 */

export const SCORE_SBT_ABI = [
    // View functions
    "function hasSoulboundToken(address account) view returns (bool)",
    "function getScore(uint256 tokenId) view returns (tuple(uint256 score, uint256 lastUpdated, uint256 dataVersion, bytes32 scoreProof, uint256 updateCount))",
    "function getScoreByAddress(address user) view returns (tuple(uint256 score, uint256 lastUpdated, uint256 dataVersion, bytes32 scoreProof, uint256 updateCount))",
    "function getScoreValue(address user) view returns (uint256)",
    "function getTokenIdByAddress(address user) view returns (uint256)",
    "function isScoreStale(uint256 tokenId, uint256 maxAge) view returns (bool)",
    "function ownerOf(uint256 tokenId) view returns (address)",
    "function totalMinted() view returns (uint256)",
    "function getRecoveryAddress(uint256 tokenId) view returns (address)",
    "function getPendingRecovery(uint256 tokenId) view returns (tuple(address initiatedBy, uint256 initiatedAt, uint256 completableAt, bool cancelled))",

    // Write functions
    "function mint(address to) returns (uint256)",
    "function mintSelf() returns (uint256)",
    "function burn(uint256 tokenId)",
    "function setRecoveryAddress(uint256 tokenId, address recoveryAddress)",
    "function initiateRecovery(uint256 tokenId)",
    "function completeRecovery(uint256 tokenId)",
    "function cancelRecovery(uint256 tokenId)",

    // Events
    "event ScoreMinted(address indexed owner, uint256 indexed tokenId)",
    "event ScoreUpdated(uint256 indexed tokenId, uint256 oldScore, uint256 newScore, uint256 dataVersion, address indexed updatedBy)",
    "event RecoveryAddressSet(uint256 indexed tokenId, address indexed recoveryAddress)",
    "event RecoveryInitiated(uint256 indexed tokenId, address indexed from, address indexed to)",
    "event RecoveryCompleted(uint256 indexed tokenId, address indexed newOwner)",
];

export const PERMISSION_MANAGER_ABI = [
    // View functions
    "function getPermission(address user, address protocol) view returns (tuple(address protocol, uint256 grantedAt, uint256 expiresAt, uint256 maxRequests, uint256 usedRequests, bool isActive, bytes32 permissionHash))",
    "function hasValidPermission(address user, address protocol) view returns (bool)",
    "function getRemainingQuota(address user, address protocol) view returns (uint256)",
    "function getPermissionHash(address user, address protocol) view returns (bytes32)",
    "function getAllPermissions(address user) view returns (tuple(address protocol, uint256 grantedAt, uint256 expiresAt, uint256 maxRequests, uint256 usedRequests, bool isActive, bytes32 permissionHash)[])",
    "function getPermissionCount(address user) view returns (uint256)",
    "function getRemainingTime(address user, address protocol) view returns (uint256)",

    // Write functions
    "function grantAccess(address protocol, uint256 duration, uint256 maxRequests) returns (bytes32)",
    "function revokeAccess(address protocol)",
    "function consumeAccess(address user, address protocol) returns (bool)",

    // Events
    "event AccessGranted(address indexed user, address indexed protocol, uint256 expiresAt, uint256 maxRequests, bytes32 indexed requestId)",
    "event AccessRevoked(address indexed user, address indexed protocol, bytes32 indexed requestId)",
    "event AccessUsed(address indexed user, address indexed protocol, uint256 remainingRequests)",
];

export const SCORE_ORACLE_ABI = [
    // View functions
    "function isAuthorizedOracle(address oracle) view returns (bool)",
    "function getMinUpdateInterval() view returns (uint256)",
    "function getLastUpdateTime(address user) view returns (uint256)",
    "function getPendingUpdateNonce(address user) view returns (uint256)",
    "function getOracleCount() view returns (uint256)",
    "function canUpdate(address user) view returns (bool)",

    // Write functions
    "function requestScoreUpdate(address user) returns (uint256)",
    "function submitScoreUpdateDirect(address user, uint256 score, bytes32 dataHash)",

    // Events
    "event ScoreUpdateRequested(address indexed user, uint256 requestId)",
    "event ScoreUpdated(address indexed user, uint256 score, bytes32 calculationHash, address indexed oracle, uint256 timestamp)",
    "event OracleAdded(address indexed oracle)",
    "event OracleRemoved(address indexed oracle)",
];

export const SIMPLE_SCORING_ABI = [
    "function calculateScore(address user) returns (tuple(uint256 totalScore, uint256 walletAgeScore, uint256 volumeScore, uint256 repaymentScore, uint256 diversityScore, uint256 calculatedAt))",
    "function simulateScore(uint256 daysActive, uint256 volumeEth, uint256 repaidLoans, uint256 totalLoans, uint256 uniqueProtocols) view returns (uint256)",
    "function getWeights() view returns (uint256 walletAge, uint256 volume, uint256 repayment, uint256 diversity)",
];
