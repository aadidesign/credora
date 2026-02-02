// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IDataProvider} from "../interfaces/IDataProvider.sol";
import {ScoreMath} from "../libraries/ScoreMath.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title BaseScoringAlgorithm
 * @author Credora Team
 * @notice Abstract base contract for credit scoring algorithms
 * @dev Defines the interface and common functionality for scoring implementations
 */
abstract contract BaseScoringAlgorithm is Ownable {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum possible score
    uint256 public constant MAX_SCORE = 1000;

    /// @notice Minimum possible score
    uint256 public constant MIN_SCORE = 0;

    /// @notice Default weights for scoring factors (must sum to 100)
    uint256 public constant DEFAULT_WALLET_AGE_WEIGHT = 20;
    uint256 public constant DEFAULT_VOLUME_WEIGHT = 25;
    uint256 public constant DEFAULT_REPAYMENT_WEIGHT = 35;
    uint256 public constant DEFAULT_DIVERSITY_WEIGHT = 20;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Data provider for wallet and DeFi data
    IDataProvider public dataProvider;

    /// @notice Weight for wallet age factor (0-100)
    uint256 public walletAgeWeight;

    /// @notice Weight for transaction volume factor (0-100)
    uint256 public volumeWeight;

    /// @notice Weight for repayment history factor (0-100)
    uint256 public repaymentWeight;

    /// @notice Weight for protocol diversity factor (0-100)
    uint256 public diversityWeight;

    /// @notice Algorithm version
    uint256 public algorithmVersion;

    /// @notice Whether the algorithm is paused
    bool public isPaused;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when weights are updated
    event WeightsUpdated(
        uint256 walletAge,
        uint256 volume,
        uint256 repayment,
        uint256 diversity
    );

    /// @notice Emitted when the data provider is changed
    event DataProviderUpdated(address indexed oldProvider, address indexed newProvider);

    /// @notice Emitted when a score is calculated
    event ScoreCalculated(
        address indexed user,
        uint256 totalScore,
        uint256 walletAgeScore,
        uint256 volumeScore,
        uint256 repaymentScore,
        uint256 diversityScore
    );

    /// @notice Emitted when algorithm version changes
    event AlgorithmVersionUpdated(uint256 oldVersion, uint256 newVersion);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when weights don't sum to 100
    error InvalidWeightSum();

    /// @notice Thrown when algorithm is paused
    error AlgorithmPaused();

    /// @notice Thrown when data is unavailable
    error DataUnavailable();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the base scoring algorithm
     * @param _dataProvider Address of the data provider
     * @param initialOwner Initial owner address
     */
    constructor(address _dataProvider, address initialOwner) Ownable(initialOwner) {
        dataProvider = IDataProvider(_dataProvider);

        // Set default weights
        walletAgeWeight = DEFAULT_WALLET_AGE_WEIGHT;
        volumeWeight = DEFAULT_VOLUME_WEIGHT;
        repaymentWeight = DEFAULT_REPAYMENT_WEIGHT;
        diversityWeight = DEFAULT_DIVERSITY_WEIGHT;

        algorithmVersion = 1;
        isPaused = false;
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Ensure algorithm is not paused
    modifier whenNotPaused() {
        if (isPaused) revert AlgorithmPaused();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        ABSTRACT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculate the credit score for a user
     * @dev Must be implemented by derived contracts
     * @param user The address to calculate score for
     * @return output The calculated score output
     */
    function calculateScore(address user) external virtual returns (DataTypes.ScoreOutput memory output);

    /**
     * @notice Calculate wallet age score component
     * @param user The address to calculate for
     * @return score The wallet age score (0-1000)
     */
    function calculateWalletAgeScore(address user) public virtual returns (uint256 score);

    /**
     * @notice Calculate volume score component
     * @param user The address to calculate for
     * @return score The volume score (0-1000)
     */
    function calculateVolumeScore(address user) public virtual returns (uint256 score);

    /**
     * @notice Calculate repayment score component
     * @param user The address to calculate for
     * @return score The repayment score (0-1000)
     */
    function calculateRepaymentScore(address user) public virtual returns (uint256 score);

    /**
     * @notice Calculate diversity score component
     * @param user The address to calculate for
     * @return score The diversity score (0-1000)
     */
    function calculateDiversityScore(address user) public virtual returns (uint256 score);

    /*//////////////////////////////////////////////////////////////
                        WEIGHT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update scoring weights
     * @param _walletAge New wallet age weight
     * @param _volume New volume weight
     * @param _repayment New repayment weight
     * @param _diversity New diversity weight
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
        emit AlgorithmVersionUpdated(algorithmVersion - 1, algorithmVersion);
    }

    /**
     * @notice Update the data provider
     * @param newProvider Address of new data provider
     */
    function updateDataProvider(address newProvider) external onlyOwner {
        require(newProvider != address(0), "Invalid provider");

        address oldProvider = address(dataProvider);
        dataProvider = IDataProvider(newProvider);

        emit DataProviderUpdated(oldProvider, newProvider);
    }

    /**
     * @notice Pause or unpause the algorithm
     * @param paused Whether to pause
     */
    function setPaused(bool paused) external onlyOwner {
        isPaused = paused;
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get current weights
     * @return walletAge Wallet age weight
     * @return volume Volume weight
     * @return repayment Repayment weight
     * @return diversity Diversity weight
     */
    function getWeights() external view returns (
        uint256 walletAge,
        uint256 volume,
        uint256 repayment,
        uint256 diversity
    ) {
        return (walletAgeWeight, volumeWeight, repaymentWeight, diversityWeight);
    }

    /**
     * @notice Calculate weighted total from individual scores
     * @param walletAgeScore Wallet age component score
     * @param volumeScore Volume component score
     * @param repaymentScore Repayment component score
     * @param diversityScore Diversity component score
     * @return total The weighted total score
     */
    function calculateWeightedTotal(
        uint256 walletAgeScore,
        uint256 volumeScore,
        uint256 repaymentScore,
        uint256 diversityScore
    ) public view returns (uint256 total) {
        total = (
            (walletAgeScore * walletAgeWeight) +
            (volumeScore * volumeWeight) +
            (repaymentScore * repaymentWeight) +
            (diversityScore * diversityWeight)
        ) / 100;

        if (total > MAX_SCORE) total = MAX_SCORE;
    }
}
