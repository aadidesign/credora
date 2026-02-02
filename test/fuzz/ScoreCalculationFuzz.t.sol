// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SimpleScoring} from "../../contracts/scoring/SimpleScoring.sol";
import {MockDataProvider} from "../../contracts/core/MockDataProvider.sol";
import {ScoreMath} from "../../contracts/libraries/ScoreMath.sol";

/**
 * @title ScoreCalculationFuzzTest
 * @notice Fuzz tests for score calculation to ensure bounds and invariants
 */
contract ScoreCalculationFuzzTest is Test {
    SimpleScoring public scoring;
    MockDataProvider public dataProvider;

    address public owner = address(1);

    function setUp() public {
        vm.startPrank(owner);
        dataProvider = new MockDataProvider(owner);
        scoring = new SimpleScoring(address(dataProvider), owner);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                         SCORE BOUND TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_ScoreNeverExceedsMax(
        uint256 daysActive,
        uint256 volumeEth,
        uint256 repaidLoans,
        uint256 totalLoans,
        uint256 uniqueProtocols
    ) public view {
        // Bound inputs to reasonable ranges
        daysActive = bound(daysActive, 0, 100000);
        volumeEth = bound(volumeEth, 0, 1e18); // Up to 1 quintillion ETH
        totalLoans = bound(totalLoans, 0, 10000);
        repaidLoans = bound(repaidLoans, 0, totalLoans);
        uniqueProtocols = bound(uniqueProtocols, 0, 1000);

        uint256 score = scoring.simulateScore(
            daysActive,
            volumeEth,
            repaidLoans,
            totalLoans,
            uniqueProtocols
        );

        assertLe(score, 1000, "Score exceeds maximum");
    }

    function testFuzz_ScoreNeverNegative(
        uint256 daysActive,
        uint256 volumeEth,
        uint256 repaidLoans,
        uint256 totalLoans,
        uint256 uniqueProtocols
    ) public view {
        daysActive = bound(daysActive, 0, 100000);
        volumeEth = bound(volumeEth, 0, 1e18);
        totalLoans = bound(totalLoans, 0, 10000);
        repaidLoans = bound(repaidLoans, 0, totalLoans);
        uniqueProtocols = bound(uniqueProtocols, 0, 1000);

        uint256 score = scoring.simulateScore(
            daysActive,
            volumeEth,
            repaidLoans,
            totalLoans,
            uniqueProtocols
        );

        // In Solidity, uint256 can't be negative, but we verify it's a valid value
        assertGe(score, 0, "Score is invalid");
    }

    /*//////////////////////////////////////////////////////////////
                       MATH FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_SqrtNeverOverflows(uint256 x) public pure {
        // sqrt should never overflow for any uint256 input
        uint256 result = ScoreMath.sqrt(x);

        // Result squared should be <= x
        if (result > 0) {
            assertLe(result * result, x, "sqrt result too large");
        }
    }

    function testFuzz_SqrtAccuracy(uint256 x) public pure {
        x = bound(x, 0, type(uint128).max); // Prevent overflow in verification

        uint256 result = ScoreMath.sqrt(x);

        // result^2 <= x < (result+1)^2
        assertLe(result * result, x, "sqrt too large");
        if (result < type(uint128).max) {
            assertGt((result + 1) * (result + 1), x, "sqrt too small");
        }
    }

    function testFuzz_Log10NeverOverflows(uint256 x) public pure {
        // log10 should never overflow
        uint256 result = ScoreMath.log10(x);

        // For any uint256, log10 should be at most 77 (roughly)
        assertLe(result, 78, "log10 result unreasonably large");
    }

    function testFuzz_WalletAgeScoreBounded(uint256 firstTx, uint256 currentTime) public pure {
        // Ensure valid timestamp relationship
        vm.assume(firstTx <= currentTime);
        vm.assume(firstTx > 0);
        vm.assume(currentTime < type(uint256).max - 1);

        uint256 score = ScoreMath.calculateWalletAgeScore(firstTx, currentTime);

        assertLe(score, 1000, "Wallet age score exceeds max");
    }

    function testFuzz_VolumeScoreBounded(uint256 volumeWei) public pure {
        uint256 score = ScoreMath.calculateVolumeScore(volumeWei);

        assertLe(score, 1000, "Volume score exceeds max");
    }

    function testFuzz_RepaymentScoreBounded(uint256 repaid, uint256 total) public pure {
        vm.assume(repaid <= total);

        uint256 score = ScoreMath.calculateRepaymentScore(repaid, total);

        assertLe(score, 1000, "Repayment score exceeds max");
    }

    function testFuzz_DiversityScoreBounded(uint256 protocols) public pure {
        uint256 score = ScoreMath.calculateDiversityScore(protocols);

        assertLe(score, 1000, "Diversity score exceeds max");
    }

    /*//////////////////////////////////////////////////////////////
                      MONOTONICITY TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_WalletAgeMonotonic(uint256 days1, uint256 days2) public {
        days1 = bound(days1, 1, 10000);
        days2 = bound(days2, days1, 10000);

        uint256 currentTime = block.timestamp;
        uint256 firstTx1 = currentTime - (days1 * 1 days);
        uint256 firstTx2 = currentTime - (days2 * 1 days);

        uint256 score1 = ScoreMath.calculateWalletAgeScore(firstTx1, currentTime);
        uint256 score2 = ScoreMath.calculateWalletAgeScore(firstTx2, currentTime);

        // Older wallet should have higher or equal score
        assertGe(score2, score1, "Wallet age not monotonic");
    }

    function testFuzz_VolumeMonotonic(uint256 volume1, uint256 volume2) public pure {
        volume1 = bound(volume1, 1 ether, 1000000 ether);
        volume2 = bound(volume2, volume1, 1000000 ether);

        uint256 score1 = ScoreMath.calculateVolumeScore(volume1);
        uint256 score2 = ScoreMath.calculateVolumeScore(volume2);

        assertGe(score2, score1, "Volume not monotonic");
    }

    function testFuzz_RepaymentMonotonic(uint256 repaid1, uint256 repaid2, uint256 total) public pure {
        total = bound(total, 1, 1000);
        repaid1 = bound(repaid1, 0, total);
        repaid2 = bound(repaid2, repaid1, total);

        uint256 score1 = ScoreMath.calculateRepaymentScore(repaid1, total);
        uint256 score2 = ScoreMath.calculateRepaymentScore(repaid2, total);

        assertGe(score2, score1, "Repayment not monotonic");
    }

    function testFuzz_DiversityMonotonic(uint256 protocols1, uint256 protocols2) public pure {
        protocols1 = bound(protocols1, 0, 20);
        protocols2 = bound(protocols2, protocols1, 20);

        uint256 score1 = ScoreMath.calculateDiversityScore(protocols1);
        uint256 score2 = ScoreMath.calculateDiversityScore(protocols2);

        assertGe(score2, score1, "Diversity not monotonic");
    }

    /*//////////////////////////////////////////////////////////////
                        WEIGHTED AVERAGE TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_WeightedAverageValid(
        uint256 walletScore,
        uint256 volumeScore,
        uint256 repaymentScore,
        uint256 diversityScore
    ) public view {
        walletScore = bound(walletScore, 0, 1000);
        volumeScore = bound(volumeScore, 0, 1000);
        repaymentScore = bound(repaymentScore, 0, 1000);
        diversityScore = bound(diversityScore, 0, 1000);

        uint256 result = scoring.calculateWeightedTotal(
            walletScore,
            volumeScore,
            repaymentScore,
            diversityScore
        );

        assertLe(result, 1000, "Weighted total exceeds max");

        // Should be between min and max of inputs
        uint256 minScore = walletScore;
        if (volumeScore < minScore) minScore = volumeScore;
        if (repaymentScore < minScore) minScore = repaymentScore;
        if (diversityScore < minScore) minScore = diversityScore;

        uint256 maxScore = walletScore;
        if (volumeScore > maxScore) maxScore = volumeScore;
        if (repaymentScore > maxScore) repaymentScore = maxScore;
        if (diversityScore > maxScore) maxScore = diversityScore;

        assertGe(result, minScore, "Weighted average below minimum input");
        assertLe(result, maxScore, "Weighted average above maximum input");
    }
}
