// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IDataProvider} from "../interfaces/IDataProvider.sol";

/**
 * @title MockDataProvider
 * @author Credora Team
 * @notice Mock implementation of data provider for testing and development
 * @dev Allows manual setting of wallet and DeFi data for any address
 */
contract MockDataProvider is Ownable, ReentrancyGuard, IDataProvider {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Data type identifier
    bytes32 public constant DATA_TYPE = keccak256("CREDORA_MOCK_DATA");

    /// @notice Whether the provider is online
    bool private _isOnline;

    /// @notice Wallet data storage
    mapping(address => WalletData) private _walletData;

    /// @notice DeFi data storage
    mapping(address => DeFiData) private _defiData;

    /// @notice Last update timestamps
    mapping(address => uint256) private _lastUpdated;

    /// @notice Authorized data updaters
    mapping(address => bool) public authorizedUpdaters;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address initialOwner) Ownable(initialOwner) {
        _isOnline = true;
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAuthorized() {
        require(
            authorizedUpdaters[msg.sender] || msg.sender == owner(),
            "Not authorized"
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        DATA MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IDataProvider
     */
    function updateWalletData(
        address user,
        WalletData calldata data
    ) external override onlyAuthorized {
        _walletData[user] = data;
        _lastUpdated[user] = block.timestamp;

        emit DataUpdated(user, DATA_TYPE, keccak256(abi.encode(data)));
    }

    /**
     * @inheritdoc IDataProvider
     */
    function updateDeFiData(
        address user,
        DeFiData calldata data
    ) external override onlyAuthorized {
        _defiData[user] = data;
        _lastUpdated[user] = block.timestamp;

        emit DataUpdated(user, DATA_TYPE, keccak256(abi.encode(data)));
    }

    /**
     * @notice Batch update data for multiple users
     * @param users Array of user addresses
     * @param walletDataArray Array of wallet data
     * @param defiDataArray Array of DeFi data
     */
    function batchUpdateData(
        address[] calldata users,
        WalletData[] calldata walletDataArray,
        DeFiData[] calldata defiDataArray
    ) external onlyAuthorized {
        require(
            users.length == walletDataArray.length &&
            users.length == defiDataArray.length,
            "Array length mismatch"
        );

        for (uint256 i = 0; i < users.length; i++) {
            _walletData[users[i]] = walletDataArray[i];
            _defiData[users[i]] = defiDataArray[i];
            _lastUpdated[users[i]] = block.timestamp;
        }
    }

    /**
     * @notice Set mock data with convenient parameters
     * @param user User address
     * @param firstTxTime First transaction timestamp
     * @param txCount Transaction count
     * @param volumeWei Volume in wei
     * @param repaidLoans Number of repaid loans
     * @param totalLoans Total loans
     * @param uniqueProtocols Unique protocols count
     */
    function setMockData(
        address user,
        uint256 firstTxTime,
        uint256 txCount,
        uint256 volumeWei,
        uint256 repaidLoans,
        uint256 totalLoans,
        uint256 uniqueProtocols
    ) external onlyAuthorized {
        _walletData[user] = WalletData({
            firstTransactionTime: firstTxTime,
            totalTransactionCount: txCount,
            totalVolumeWei: volumeWei,
            lastActiveTime: block.timestamp
        });

        _defiData[user] = DeFiData({
            totalLoansCount: totalLoans,
            repaidLoansCount: repaidLoans,
            defaultedLoansCount: 0,
            totalBorrowedWei: 0,
            totalRepaidWei: 0,
            uniqueProtocolsUsed: uniqueProtocols
        });

        _lastUpdated[user] = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IDataProvider
     */
    function getWalletData(address user) external view override returns (WalletData memory) {
        if (!_isOnline) revert DataSourceOffline();
        return _walletData[user];
    }

    /**
     * @inheritdoc IDataProvider
     */
    function getDeFiData(address user) external view override returns (DeFiData memory) {
        if (!_isOnline) revert DataSourceOffline();
        return _defiData[user];
    }

    /**
     * @inheritdoc IDataProvider
     */
    function getAggregatedData(address user) external view override returns (AggregatedData memory) {
        if (!_isOnline) revert DataSourceOffline();

        return AggregatedData({
            wallet: _walletData[user],
            defi: _defiData[user],
            dataTimestamp: _lastUpdated[user],
            dataHash: keccak256(abi.encode(_walletData[user], _defiData[user]))
        });
    }

    /**
     * @inheritdoc IDataProvider
     */
    function getDataType() external pure override returns (bytes32) {
        return DATA_TYPE;
    }

    /**
     * @inheritdoc IDataProvider
     */
    function isDataAvailable(address user) external view override returns (bool) {
        return _lastUpdated[user] > 0;
    }

    /**
     * @inheritdoc IDataProvider
     */
    function getLastUpdateTime(address user) external view override returns (uint256) {
        return _lastUpdated[user];
    }

    /**
     * @inheritdoc IDataProvider
     */
    function isOnline() external view override returns (bool) {
        return _isOnline;
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set online status
     * @param online Whether provider is online
     */
    function setOnlineStatus(bool online) external onlyOwner {
        _isOnline = online;
        emit DataSourceStatusChanged(online);
    }

    /**
     * @notice Authorize or deauthorize an updater
     * @param updater Address to authorize
     * @param authorized Whether to authorize
     */
    function setAuthorizedUpdater(address updater, bool authorized) external onlyOwner {
        authorizedUpdaters[updater] = authorized;
    }

    /**
     * @notice Clear data for a user
     * @param user User to clear data for
     */
    function clearData(address user) external onlyAuthorized {
        delete _walletData[user];
        delete _defiData[user];
        delete _lastUpdated[user];
    }
}
