// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IDataProvider
 * @author Credora Team
 * @notice Interface for data sources feeding into score calculations
 * @dev Implement this to create new data providers for the scoring system
 */
interface IDataProvider {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when data is not available for the requested user
    error DataNotAvailable();

    /// @notice Thrown when data source is temporarily unavailable
    error DataSourceOffline();

    /// @notice Thrown when the caller is not authorized
    error UnauthorizedCaller();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when data is updated for a user
    /// @param user The user whose data was updated
    /// @param dataType The type of data updated
    /// @param dataHash Hash of the data for verification
    event DataUpdated(address indexed user, bytes32 indexed dataType, bytes32 dataHash);

    /// @notice Emitted when the data source status changes
    /// @param isOnline Whether the data source is now online
    event DataSourceStatusChanged(bool isOnline);

    /*//////////////////////////////////////////////////////////////
                              STRUCTURES
    //////////////////////////////////////////////////////////////*/

    /// @notice Wallet history data
    struct WalletData {
        uint256 firstTransactionTime;   // Unix timestamp of first transaction
        uint256 totalTransactionCount;  // Total number of transactions
        uint256 totalVolumeWei;         // Total transaction volume in wei
        uint256 lastActiveTime;         // Unix timestamp of last activity
    }

    /// @notice DeFi interaction data
    struct DeFiData {
        uint256 totalLoansCount;        // Total number of loans taken
        uint256 repaidLoansCount;       // Number of successfully repaid loans
        uint256 defaultedLoansCount;    // Number of defaulted loans
        uint256 totalBorrowedWei;       // Total amount borrowed in wei
        uint256 totalRepaidWei;         // Total amount repaid in wei
        uint256 uniqueProtocolsUsed;    // Number of unique protocols interacted with
    }

    /// @notice Aggregated data for scoring
    struct AggregatedData {
        WalletData wallet;
        DeFiData defi;
        uint256 dataTimestamp;          // When this data was aggregated
        bytes32 dataHash;               // Hash for verification
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get wallet history data for a user
     * @param user The user to query
     * @return data The wallet data
     */
    function getWalletData(address user) external view returns (WalletData memory data);

    /**
     * @notice Get DeFi interaction data for a user
     * @param user The user to query
     * @return data The DeFi data
     */
    function getDeFiData(address user) external view returns (DeFiData memory data);

    /**
     * @notice Get aggregated data for scoring
     * @param user The user to query
     * @return data Aggregated data ready for scoring
     */
    function getAggregatedData(address user) external view returns (AggregatedData memory data);

    /**
     * @notice Get the data type identifier this provider supplies
     * @return dataType Unique identifier for the data type
     */
    function getDataType() external view returns (bytes32 dataType);

    /**
     * @notice Check if data is available for a user
     * @param user The user to check
     * @return available True if data exists for this user
     */
    function isDataAvailable(address user) external view returns (bool available);

    /**
     * @notice Get the last update timestamp for a user's data
     * @param user The user to query
     * @return timestamp Unix timestamp of last update
     */
    function getLastUpdateTime(address user) external view returns (uint256 timestamp);

    /**
     * @notice Check if the data source is online and operational
     * @return online True if data source is available
     */
    function isOnline() external view returns (bool online);

    /*//////////////////////////////////////////////////////////////
                           WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update wallet data for a user (called by authorized sources)
     * @param user The user to update
     * @param data The new wallet data
     */
    function updateWalletData(address user, WalletData calldata data) external;

    /**
     * @notice Update DeFi data for a user (called by authorized sources)
     * @param user The user to update
     * @param data The new DeFi data
     */
    function updateDeFiData(address user, DeFiData calldata data) external;
}
