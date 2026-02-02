// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SimpleScoring} from "../../contracts/scoring/SimpleScoring.sol";
import {MockDataProvider} from "../../contracts/core/MockDataProvider.sol";
import {IDataProvider} from "../../contracts/interfaces/IDataProvider.sol";
import {ScoreMath} from "../../contracts/libraries/ScoreMath.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";

/**
 * @title ScoringAlgorithmTest
 * @notice Unit tests for scoring algorithm and math library
 */
contract ScoringAlgorithmTest is Test {
    SimpleScoring public scoring;
    MockDataProvider public dataProvider;

    address public owner = address(1);
    address public user1 = address(2);

    function setUp() public {
        vm.startPrank(owner);
        dataProvider = new MockDataProvider(owner);
        scoring = new SimpleScoring(address(dataProvider), owner);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        SCORE MATH TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Sqrt() public pure {
        assertEq(ScoreMath.sqrt(0), 0);
        assertEq(ScoreMath.sqrt(1), 1);
        assertEq(ScoreMath.sqrt(4), 2);
        assertEq(ScoreMath.sqrt(9), 3);
        assertEq(ScoreMath.sqrt(16), 4);
        assertEq(ScoreMath.sqrt(100), 10);
        assertEq(ScoreMath.sqrt(10000), 100);
    }

    function test_Log10() public pure {
        assertEq(ScoreMath.log10(0), 0);
        assertEq(ScoreMath.log10(1), 0);
        assertEq(ScoreMath.log10(9), 0);
        assertEq(ScoreMath.log10(10), 1);
        assertEq(ScoreMath.log10(100), 2);
        assertEq(ScoreMath.log10(1000), 3);
        assertEq(ScoreMath.log10(999), 2);
    }

    function test_CalculateWalletAgeScore() public {
        // 0 days = 0 score
        assertEq(ScoreMath.calculateWalletAgeScore(block.timestamp, block.timestamp), 0);

        // 100 days = sqrt(100) * 10 = 100
        uint256 firstTx = block.timestamp - (100 days);
        assertEq(ScoreMath.calculateWalletAgeScore(firstTx, block.timestamp), 100);

        // 10000 days = sqrt(10000) * 10 = 1000 (max)
        firstTx = block.timestamp - (10000 days);
        assertEq(ScoreMath.calculateWalletAgeScore(firstTx, block.timestamp), 1000);

        // More than 10000 days should cap at 1000
        firstTx = block.timestamp - (20000 days);
        uint256 score = ScoreMath.calculateWalletAgeScore(firstTx, block.timestamp);
        assertEq(score, 1000);
    }

    function test_CalculateVolumeScore() public pure {
        // 0 ETH = 0 score
        assertEq(ScoreMath.calculateVolumeScore(0), 0);

        // 1 ETH = log10(1) * 100 = 0
        assertEq(ScoreMath.calculateVolumeScore(1 ether), 0);

        // 10 ETH = log10(10) * 100 = 100
        assertEq(ScoreMath.calculateVolumeScore(10 ether), 100);

        // 100 ETH = log10(100) * 100 = 200
        assertEq(ScoreMath.calculateVolumeScore(100 ether), 200);

        // 1000 ETH = log10(1000) * 100 = 300
        assertEq(ScoreMath.calculateVolumeScore(1000 ether), 300);
    }

    function test_CalculateRepaymentScore() public pure {
        // No loans = neutral 500
        assertEq(ScoreMath.calculateRepaymentScore(0, 0), 500);

        // All repaid = 1000
        assertEq(ScoreMath.calculateRepaymentScore(10, 10), 1000);

        // Half repaid = 500
        assertEq(ScoreMath.calculateRepaymentScore(5, 10), 500);

        // 80% repaid = 800
        assertEq(ScoreMath.calculateRepaymentScore(8, 10), 800);
    }

    function test_CalculateDiversityScore() public pure {
        // 0 protocols = 0
        assertEq(ScoreMath.calculateDiversityScore(0), 0);

        // 5 protocols = 500
        assertEq(ScoreMath.calculateDiversityScore(5), 500);

        // 10 protocols = 1000 (max)
        assertEq(ScoreMath.calculateDiversityScore(10), 1000);

        // More than 10 caps at 1000
        assertEq(ScoreMath.calculateDiversityScore(15), 1000);
    }

    /*//////////////////////////////////////////////////////////////
                     SIMPLE SCORING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SimulateScore() public view {
        // Perfect user: 4 years, 10000 ETH, all repaid, 10 protocols
        uint256 score = scoring.simulateScore(
            1460,   // 4 years in days
            10000,  // 10000 ETH volume
            100,    // 100 repaid
            100,    // 100 total
            10      // 10 protocols
        );

        // walletAge: sqrt(1460)*10 ≈ 382 (capped factors may vary)
        // volume: log10(10000)*100 = 400
        // repayment: 1000
        // diversity: 1000
        // Weighted: (382*20 + 400*25 + 1000*35 + 1000*20) / 100
        //         = (7640 + 10000 + 35000 + 20000) / 100 = 726
        assertGt(score, 700);
        assertLe(score, 1000);
    }

    function test_SimulateScoreNewUser() public view {
        // New user: 30 days, 1 ETH, no loans, 1 protocol
        uint256 score = scoring.simulateScore(
            30,     // 30 days
            1,      // 1 ETH
            0,      // no repaid
            0,      // no loans (neutral)
            1       // 1 protocol
        );

        // Should be low but non-zero
        assertGt(score, 0);
        assertLt(score, 300);
    }

    function test_CalculateScoreWithData() public view {
        IDataProvider.WalletData memory walletData = IDataProvider.WalletData({
            firstTransactionTime: block.timestamp - 365 days,
            totalTransactionCount: 100,
            totalVolumeWei: 100 ether,
            lastActiveTime: block.timestamp
        });

        IDataProvider.DeFiData memory defiData = IDataProvider.DeFiData({
            totalLoansCount: 10,
            repaidLoansCount: 9,
            defaultedLoansCount: 0,
            totalBorrowedWei: 50 ether,
            totalRepaidWei: 45 ether,
            uniqueProtocolsUsed: 5
        });

        DataTypes.ScoreOutput memory output = scoring.calculateScoreWithData(walletData, defiData);

        assertGt(output.totalScore, 0);
        assertLe(output.totalScore, 1000);
        assertGt(output.walletAgeScore, 0);
        assertGt(output.repaymentScore, 0);
        assertGt(output.diversityScore, 0);
    }

    function test_CalculateScoreFromProvider() public {
        // Set mock data
        vm.prank(owner);
        dataProvider.setMockData(
            user1,
            block.timestamp - 180 days, // 6 months old
            50,                          // 50 transactions
            50 ether,                    // 50 ETH volume
            5,                           // 5 repaid loans
            6,                           // 6 total loans
            4                            // 4 protocols
        );

        DataTypes.ScoreOutput memory output = scoring.calculateScore(user1);

        assertGt(output.totalScore, 0);
        assertLe(output.totalScore, 1000);
    }

    /*//////////////////////////////////////////////////////////////
                         WEIGHT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetWeights() public view {
        (uint256 walletAge, uint256 volume, uint256 repayment, uint256 diversity) = scoring.getWeights();

        assertEq(walletAge, 20);
        assertEq(volume, 25);
        assertEq(repayment, 35);
        assertEq(diversity, 20);
        assertEq(walletAge + volume + repayment + diversity, 100);
    }

    function test_UpdateWeights() public {
        vm.prank(owner);
        scoring.updateWeights(25, 25, 25, 25);

        (uint256 walletAge, uint256 volume, uint256 repayment, uint256 diversity) = scoring.getWeights();
        assertEq(walletAge, 25);
        assertEq(volume, 25);
        assertEq(repayment, 25);
        assertEq(diversity, 25);
    }

    function test_RevertInvalidWeightSum() public {
        vm.expectRevert();
        vm.prank(owner);
        scoring.updateWeights(30, 30, 30, 30); // Sum = 120
    }

    /*//////////////////////////////////////////////////////////////
                        PAUSE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_PauseAlgorithm() public {
        vm.prank(owner);
        dataProvider.setMockData(user1, block.timestamp - 30 days, 10, 10 ether, 1, 1, 1);

        vm.prank(owner);
        scoring.setPaused(true);

        vm.expectRevert();
        scoring.calculateScore(user1);
    }

    function test_UnpauseAlgorithm() public {
        vm.prank(owner);
        dataProvider.setMockData(user1, block.timestamp - 30 days, 10, 10 ether, 1, 1, 1);

        vm.startPrank(owner);
        scoring.setPaused(true);
        scoring.setPaused(false);
        vm.stopPrank();

        // Should work now
        DataTypes.ScoreOutput memory output = scoring.calculateScore(user1);
        assertGt(output.totalScore, 0);
    }
}
