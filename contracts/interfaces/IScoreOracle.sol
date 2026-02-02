// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IScoreOracle
 * @author Credora Team
 * @notice Interface for the score oracle system
 */
interface IScoreOracle {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidSignature();
    error OracleNotAuthorized();
    error UpdateTooFrequent();
    error ScoreOutOfRange();
    error InvalidNonce();
    error RequestExpired();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OracleAdded(address indexed oracle);
    event OracleRemoved(address indexed oracle);
    event ScoreUpdateRequested(address indexed user, uint256 requestId);
    event ScoreUpdated(
        address indexed user,
        uint256 score,
        bytes32 calculationHash,
        address indexed oracle,
        uint256 timestamp
    );

    /*//////////////////////////////////////////////////////////////
                              STRUCTURES
    //////////////////////////////////////////////////////////////*/

    struct ScoreUpdate {
        address user;
        uint256 score;
        uint256 timestamp;
        uint256 nonce;
        bytes32 dataHash;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function isAuthorizedOracle(address oracle) external view returns (bool);
    function getMinUpdateInterval() external view returns (uint256);
    function getLastUpdateTime(address user) external view returns (uint256);
    function getPendingUpdateNonce(address user) external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                           WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function requestScoreUpdate(address user) external returns (uint256 requestId);
    function submitScoreUpdate(ScoreUpdate calldata update, bytes calldata signature) external;
    function addOracle(address oracle) external;
    function removeOracle(address oracle) external;
    function setMinUpdateInterval(uint256 interval) external;
}
