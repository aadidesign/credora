// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IDataProvider} from "../interfaces/IDataProvider.sol";
import {ScoreMath} from "../libraries/ScoreMath.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title AdvancedScoring
 * @author Credora Team
 * @notice Advanced upgradeable scoring algorithm with additional factors
 * @dev Extends basic scoring with:
 *      - Time-weighted transaction analysis
 *      - DeFi-specific behavior patterns
 *      - Sybil resistance patterns
 *      - Configurable factor multipliers
 */
contract AdvancedScoring is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using ScoreMath for uint256;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MAX_SCORE = 1000;
    uint256 public constant PRECISION = 1e18;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Data provider contract
    IDataProvider public dataProvider;

    /// @notice Algorithm version
    uint256 public algorithmVersion;

    /// @notice Whether algorithm is paused
    bool public isPaused;

    /// @notice Base weights (must sum to 100)
    uint256 public walletAgeWeight;
    uint256 public volumeWeight;
    uint256 public repaymentWeight;
    uint256 public diversityWeight;

    /// @notice Bonus multipliers
    uint256 public longevityBonus;      // Bonus for >3 years
    uint256 public loyaltyBonus;        // Bonus for consistent activity
    uint256 public whaleDiscount;       // Penalty for whale-like patterns

    /// @notice Minimum thresholds for scoring
    uint256 public minWalletAgeDays;
    uint256 public minTransactionCount;

    /// @notice Gap for future upgrades
    uint256[50] private __gap;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ScoreCalculated(
        address indexed user,
        uint256 totalScore,
        uint256 baseScore,
        int256 adjustment,
        uint256 version
    );

    event WeightsUpdated(
        uint256 walletAge,
        uint256 volume,
        uint256 repayment,
        uint256 diversity
    );

    event BonusesUpdated(
        uint256 longevity,
        uint256 loyalty,
        uint256 whaleDiscount
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error AlgorithmPaused();
    error InvalidWeightSum();
    error InsufficientHistory();

    /*//////////////////////////////////////////////////////////////
                             INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the advanced scoring contract
     * @param _dataProvider Address of data provider
     * @param _owner Initial owner
     */
    function initialize(
        address _dataProvider,
        address _owner
    ) external initializer {
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();

        dataProvider = IDataProvider(_dataProvider);
        algorithmVersion = 1;
        isPaused = false;

        // Default weights
        walletAgeWeight = 20;
        volumeWeight = 25;
        repaymentWeight = 35;
        diversityWeight = 20;

        // Default bonuses
        longevityBonus = 50;    // +50 for 3+ years
        loyaltyBonus = 30;      // +30 for consistent activity
        whaleDiscount = 100;    // -100 for whale patterns

        // Default minimums
        minWalletAgeDays = 30;
        minTransactionCount = 10;
    }

    /*//////////////////////////////////////////////////////////////
                        SCORING IMPLEMENTATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculate advanced credit score
     * @param user Address to calculate score for
     * @return output The calculated score output
     */
    function calculateScore(
        address user
    ) external returns (DataTypes.ScoreOutput memory output) {
        if (isPaused) revert AlgorithmPaused();

        // Get user data
        IDataProvider.WalletData memory walletData = dataProvider.getWalletData(user);
        IDataProvider.DeFiData memory defiData = dataProvider.getDeFiData(user);

        // Check minimum requirements
        uint256 walletAgeDays = 0;
        if (walletData.firstTransactionTime > 0 && block.timestamp > walletData.firstTransactionTime) {
            walletAgeDays = (block.timestamp - walletData.firstTransactionTime) / 1 days;
        }

        if (walletAgeDays < minWalletAgeDays || walletData.totalTransactionCount < minTransactionCount) {
            revert InsufficientHistory();
        }

        // Calculate base scores
        uint256 walletAgeScore = _calculateWalletAgeScore(walletData);
        uint256 volumeScore = _calculateVolumeScore(walletData);
        uint256 repaymentScore = _calculateRepaymentScore(defiData);
        uint256 diversityScore = _calculateDiversityScore(defiData);

        // Calculate weighted base score
        uint256 baseScore = (
            (walletAgeScore * walletAgeWeight) +
            (volumeScore * volumeWeight) +
            (repaymentScore * repaymentWeight) +
            (diversityScore * diversityWeight)
        ) / 100;

        // Apply adjustments
        int256 adjustment = _calculateAdjustment(walletData, defiData, walletAgeDays);

        // Calculate final score
        uint256 finalScore;
        if (adjustment >= 0) {
            finalScore = baseScore + uint256(adjustment);
        } else {
            uint256 absAdjustment = uint256(-adjustment);
            finalScore = baseScore > absAdjustment ? baseScore - absAdjustment : 0;
        }

        // Clamp to max
        if (finalScore > MAX_SCORE) finalScore = MAX_SCORE;

        output = DataTypes.ScoreOutput({
            totalScore: finalScore,
            walletAgeScore: walletAgeScore,
            volumeScore: volumeScore,
            repaymentScore: repaymentScore,
            diversityScore: diversityScore,
            calculatedAt: block.timestamp
        });

        emit ScoreCalculated(user, finalScore, baseScore, adjustment, algorithmVersion);
    }

    /*//////////////////////////////////////////////////////////////
                      INTERNAL CALCULATIONS
    //////////////////////////////////////////////////////////////*/

    function _calculateWalletAgeScore(
        IDataProvider.WalletData memory data
    ) internal view returns (uint256) {
        return ScoreMath.calculateWalletAgeScore(
            data.firstTransactionTime,
            block.timestamp
        );
    }

    function _calculateVolumeScore(
        IDataProvider.WalletData memory data
    ) internal pure returns (uint256) {
        return ScoreMath.calculateVolumeScore(data.totalVolumeWei);
    }

    function _calculateRepaymentScore(
        IDataProvider.DeFiData memory data
    ) internal pure returns (uint256) {
        return ScoreMath.calculateRepaymentScore(
            data.repaidLoansCount,
            data.totalLoansCount
        );
    }

    function _calculateDiversityScore(
        IDataProvider.DeFiData memory data
    ) internal pure returns (uint256) {
        return ScoreMath.calculateDiversityScore(data.uniqueProtocolsUsed);
    }

    /**
     * @notice Calculate score adjustments based on advanced patterns
     * @param walletData User's wallet data
     * @param defiData User's DeFi data
     * @param walletAgeDays Age of wallet in days
     * @return adjustment Score adjustment (can be negative)
     */
    function _calculateAdjustment(
        IDataProvider.WalletData memory walletData,
        IDataProvider.DeFiData memory defiData,
        uint256 walletAgeDays
    ) internal view returns (int256 adjustment) {
        adjustment = 0;

        // Longevity bonus: +bonus for 3+ years
        if (walletAgeDays >= 1095) {
            adjustment += int256(longevityBonus);
        }

        // Loyalty bonus: Consistent activity (active in last 30 days)
        if (walletData.lastActiveTime > 0) {
            uint256 daysSinceActive = (block.timestamp - walletData.lastActiveTime) / 1 days;
            if (daysSinceActive <= 30) {
                adjustment += int256(loyaltyBonus);
            }
        }

        // Whale pattern detection (high volume, low tx count)
        if (walletData.totalTransactionCount > 0) {
            uint256 avgTxSize = walletData.totalVolumeWei / walletData.totalTransactionCount;
            // If average tx is >100 ETH with few transactions, apply discount
            if (avgTxSize > 100 ether && walletData.totalTransactionCount < 50) {
                adjustment -= int256(whaleDiscount);
            }
        }

        // Default penalty (no loans but not new user)
        if (defiData.defaultedLoansCount > 0) {
            // Heavy penalty for defaults
            uint256 defaultPenalty = (defiData.defaultedLoansCount * 100);
            if (defaultPenalty > 500) defaultPenalty = 500; // Cap at 500
            adjustment -= int256(defaultPenalty);
        }
    }

    /*//////////////////////////////////////////////////////////////
                         ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update scoring weights
     */
    function updateWeights(
        uint256 _walletAge,
        uint256 _volume,
        uint256 _repayment,
        uint256 _diversity
    ) external onlyOwner {
        if (_walletAge + _volume + _repayment + _diversity != 100) {
            revert InvalidWeightSum();
        }

        walletAgeWeight = _walletAge;
        volumeWeight = _volume;
        repaymentWeight = _repayment;
        diversityWeight = _diversity;
        algorithmVersion++;

        emit WeightsUpdated(_walletAge, _volume, _repayment, _diversity);
    }

    /**
     * @notice Update bonus values
     */
    function updateBonuses(
        uint256 _longevity,
        uint256 _loyalty,
        uint256 _whaleDiscount
    ) external onlyOwner {
        longevityBonus = _longevity;
        loyaltyBonus = _loyalty;
        whaleDiscount = _whaleDiscount;

        emit BonusesUpdated(_longevity, _loyalty, _whaleDiscount);
    }

    /**
     * @notice Update minimum thresholds
     */
    function updateMinimums(
        uint256 _minAgeDays,
        uint256 _minTxCount
    ) external onlyOwner {
        minWalletAgeDays = _minAgeDays;
        minTransactionCount = _minTxCount;
    }

    /**
     * @notice Update data provider
     */
    function updateDataProvider(address _provider) external onlyOwner {
        require(_provider != address(0), "Invalid provider");
        dataProvider = IDataProvider(_provider);
    }

    /**
     * @notice Pause/unpause algorithm
     */
    function setPaused(bool _paused) external onlyOwner {
        isPaused = _paused;
    }

    /*//////////////////////////////////////////////////////////////
                            UUPS UPGRADE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Authorize upgrade (owner only)
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Get current implementation version
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}
