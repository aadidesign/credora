// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseScoringAlgorithm} from "./BaseScoringAlgorithm.sol";
import {IDataProvider} from "../interfaces/IDataProvider.sol";
import {ScoreMath} from "../libraries/ScoreMath.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title SimpleScoring
 * @author Credora Team
 * @notice Basic implementation of the credit scoring algorithm
 * @dev Implements MVP scoring based on:
 *      - Wallet Age (20%): sqrt(days_active) * 10
 *      - Transaction Volume (25%): log10(total_eth) * 100
 *      - Repayment History (35%): (repaid / total) * 1000
 *      - Protocol Diversity (20%): (unique_protocols / 10) * 1000
 */
contract SimpleScoring is BaseScoringAlgorithm {
    using ScoreMath for uint256;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize SimpleScoring contract
     * @param _dataProvider Address of the data provider
     * @param initialOwner Initial owner address
     */
    constructor(
        address _dataProvider,
        address initialOwner
    ) BaseScoringAlgorithm(_dataProvider, initialOwner) {}

    /*//////////////////////////////////////////////////////////////
                        SCORING IMPLEMENTATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc BaseScoringAlgorithm
     */
    function calculateScore(
        address user
    ) external override whenNotPaused returns (DataTypes.ScoreOutput memory output) {
        // Calculate individual scores
        uint256 walletAgeScore = calculateWalletAgeScore(user);
        uint256 volumeScore = calculateVolumeScore(user);
        uint256 repaymentScore = calculateRepaymentScore(user);
        uint256 diversityScore = calculateDiversityScore(user);

        // Calculate weighted total
        uint256 totalScore = calculateWeightedTotal(
            walletAgeScore,
            volumeScore,
            repaymentScore,
            diversityScore
        );

        output = DataTypes.ScoreOutput({
            totalScore: totalScore,
            walletAgeScore: walletAgeScore,
            volumeScore: volumeScore,
            repaymentScore: repaymentScore,
            diversityScore: diversityScore,
            calculatedAt: block.timestamp
        });

        emit ScoreCalculated(
            user,
            totalScore,
            walletAgeScore,
            volumeScore,
            repaymentScore,
            diversityScore
        );
    }

    /**
     * @inheritdoc BaseScoringAlgorithm
     */
    function calculateWalletAgeScore(address user) public view override returns (uint256 score) {
        IDataProvider.WalletData memory data = dataProvider.getWalletData(user);

        if (data.firstTransactionTime == 0) {
            return 0;
        }

        score = ScoreMath.calculateWalletAgeScore(
            data.firstTransactionTime,
            block.timestamp
        );
    }

    /**
     * @inheritdoc BaseScoringAlgorithm
     */
    function calculateVolumeScore(address user) public view override returns (uint256 score) {
        IDataProvider.WalletData memory data = dataProvider.getWalletData(user);

        score = ScoreMath.calculateVolumeScore(data.totalVolumeWei);
    }

    /**
     * @inheritdoc BaseScoringAlgorithm
     */
    function calculateRepaymentScore(address user) public view override returns (uint256 score) {
        IDataProvider.DeFiData memory data = dataProvider.getDeFiData(user);

        score = ScoreMath.calculateRepaymentScore(
            data.repaidLoansCount,
            data.totalLoansCount
        );
    }

    /**
     * @inheritdoc BaseScoringAlgorithm
     */
    function calculateDiversityScore(address user) public view override returns (uint256 score) {
        IDataProvider.DeFiData memory data = dataProvider.getDeFiData(user);

        score = ScoreMath.calculateDiversityScore(data.uniqueProtocolsUsed);
    }

    /*//////////////////////////////////////////////////////////////
                        UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculate score with custom data (for testing/simulation)
     * @param walletData Custom wallet data
     * @param defiData Custom DeFi data
     * @return output The calculated score
     */
    function calculateScoreWithData(
        IDataProvider.WalletData memory walletData,
        IDataProvider.DeFiData memory defiData
    ) external view returns (DataTypes.ScoreOutput memory output) {
        uint256 walletAgeScore = ScoreMath.calculateWalletAgeScore(
            walletData.firstTransactionTime,
            block.timestamp
        );

        uint256 volumeScore = ScoreMath.calculateVolumeScore(walletData.totalVolumeWei);

        uint256 repaymentScore = ScoreMath.calculateRepaymentScore(
            defiData.repaidLoansCount,
            defiData.totalLoansCount
        );

        uint256 diversityScore = ScoreMath.calculateDiversityScore(defiData.uniqueProtocolsUsed);

        uint256 totalScore = calculateWeightedTotal(
            walletAgeScore,
            volumeScore,
            repaymentScore,
            diversityScore
        );

        output = DataTypes.ScoreOutput({
            totalScore: totalScore,
            walletAgeScore: walletAgeScore,
            volumeScore: volumeScore,
            repaymentScore: repaymentScore,
            diversityScore: diversityScore,
            calculatedAt: block.timestamp
        });
    }

    /**
     * @notice Simulate score for given inputs (pure calculation)
     * @param daysActive Days since first transaction
     * @param volumeEth Total volume in ETH
     * @param repaidLoans Number of repaid loans
     * @param totalLoans Total loans
     * @param uniqueProtocols Number of unique protocols
     * @return totalScore The simulated score
     */
    function simulateScore(
        uint256 daysActive,
        uint256 volumeEth,
        uint256 repaidLoans,
        uint256 totalLoans,
        uint256 uniqueProtocols
    ) external view returns (uint256 totalScore) {
        // Calculate wallet age score
        uint256 walletAgeScore = ScoreMath.sqrt(daysActive) * 10;
        if (walletAgeScore > MAX_SCORE) walletAgeScore = MAX_SCORE;

        // Calculate volume score
        uint256 volumeScore = 0;
        if (volumeEth > 0) {
            volumeScore = ScoreMath.log10(volumeEth) * 100;
            if (volumeScore > MAX_SCORE) volumeScore = MAX_SCORE;
        }

        // Calculate repayment score
        uint256 repaymentScore = ScoreMath.calculateRepaymentScore(repaidLoans, totalLoans);

        // Calculate diversity score
        uint256 diversityScore = ScoreMath.calculateDiversityScore(uniqueProtocols);

        totalScore = calculateWeightedTotal(
            walletAgeScore,
            volumeScore,
            repaymentScore,
            diversityScore
        );
    }
}
