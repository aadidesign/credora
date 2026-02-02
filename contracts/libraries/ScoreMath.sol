// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ScoreMath
 * @author Credora Team
 * @notice Mathematical operations library for credit score calculations
 * @dev Provides safe math operations optimized for score calculations
 */
library ScoreMath {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum possible credit score
    uint256 public constant MAX_SCORE = 1000;

    /// @notice Minimum possible credit score
    uint256 public constant MIN_SCORE = 0;

    /// @notice Precision for fixed-point calculations (18 decimals)
    uint256 public constant PRECISION = 1e18;

    /// @notice Seconds in a day for age calculations
    uint256 public constant SECONDS_PER_DAY = 86400;

    /// @notice Natural log of 10 * PRECISION for log calculations
    uint256 private constant LN_10 = 2302585092994045684;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when score exceeds maximum
    error ScoreOverflow();

    /// @notice Thrown when division by zero is attempted
    error DivisionByZero();

    /// @notice Thrown when weight sum doesn't equal 100
    error InvalidWeightSum();

    /*//////////////////////////////////////////////////////////////
                         CORE SCORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculate square root using Babylonian method
     * @dev Used for wallet age scoring: sqrt(days_active) * 100
     * @param x The number to calculate square root for
     * @return result The square root of x
     */
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) return 0;

        // Initial guess
        result = x;
        uint256 k = (x >> 1) + 1;

        while (k < result) {
            result = k;
            k = (x / k + k) >> 1;
        }
    }

    /**
     * @notice Calculate approximate log base 10
     * @dev Uses integer approximation: floor(log10(x))
     * @param x The number to calculate log10 for
     * @return result The approximate log10 of x
     */
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) return 0;

        result = 0;
        while (x >= 10) {
            x /= 10;
            result++;
        }
    }

    /**
     * @notice Calculate a more precise log10 with decimal precision
     * @dev Returns log10(x) * PRECISION
     * @param x The number to calculate log10 for
     * @return result The log10 of x multiplied by PRECISION
     */
    function log10Precise(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) return 0;
        if (x < 10) return 0;

        // Get integer part
        uint256 intPart = log10(x);

        // Get fractional part using linear interpolation
        uint256 lowerBound = 10 ** intPart;
        uint256 upperBound = 10 ** (intPart + 1);

        // Linear interpolation between powers of 10
        uint256 fraction = ((x - lowerBound) * PRECISION) / (upperBound - lowerBound);

        result = (intPart * PRECISION) + fraction;
    }

    /**
     * @notice Normalize a value to the 0-1000 score range
     * @param value The raw value to normalize
     * @param maxValue The maximum expected raw value
     * @return normalized Score in 0-1000 range
     */
    function normalize(uint256 value, uint256 maxValue) internal pure returns (uint256 normalized) {
        if (maxValue == 0) revert DivisionByZero();
        if (value >= maxValue) return MAX_SCORE;

        normalized = (value * MAX_SCORE) / maxValue;
    }

    /**
     * @notice Calculate weighted average of score factors
     * @param values Array of factor values (each 0-1000)
     * @param weights Array of weights (must sum to 100)
     * @return score The weighted average score
     */
    function weightedAverage(
        uint256[] memory values,
        uint256[] memory weights
    ) internal pure returns (uint256 score) {
        require(values.length == weights.length, "Length mismatch");

        uint256 weightSum = 0;
        uint256 weightedSum = 0;

        for (uint256 i = 0; i < values.length; i++) {
            weightSum += weights[i];
            weightedSum += values[i] * weights[i];
        }

        if (weightSum != 100) revert InvalidWeightSum();

        score = weightedSum / 100;

        // Ensure score is within bounds
        if (score > MAX_SCORE) score = MAX_SCORE;
    }

    /*//////////////////////////////////////////////////////////////
                        FACTOR CALCULATIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculate wallet age factor
     * @dev Score = min(sqrt(days_active) * 10, 1000)
     * @param firstTxTimestamp Unix timestamp of first transaction
     * @param currentTimestamp Current block timestamp
     * @return score Wallet age score (0-1000)
     */
    function calculateWalletAgeScore(
        uint256 firstTxTimestamp,
        uint256 currentTimestamp
    ) internal pure returns (uint256 score) {
        if (firstTxTimestamp == 0 || firstTxTimestamp >= currentTimestamp) {
            return 0;
        }

        uint256 daysActive = (currentTimestamp - firstTxTimestamp) / SECONDS_PER_DAY;

        // sqrt(days) * 10, capped at 1000
        // 10000 days = 100 * 10 = 1000 (max)
        score = sqrt(daysActive) * 10;

        if (score > MAX_SCORE) score = MAX_SCORE;
    }

    /**
     * @notice Calculate transaction volume factor
     * @dev Score = log10(volume_eth) * 100, capped at 1000
     * @param totalVolumeWei Total transaction volume in wei
     * @return score Volume score (0-1000)
     */
    function calculateVolumeScore(uint256 totalVolumeWei) internal pure returns (uint256 score) {
        if (totalVolumeWei == 0) return 0;

        // Convert to ETH (remove 18 decimals)
        uint256 volumeEth = totalVolumeWei / 1e18;

        if (volumeEth == 0) return 0;

        // log10(volume) * 100
        // 10^10 ETH = 10 * 100 = 1000 (max)
        score = log10(volumeEth) * 100;

        if (score > MAX_SCORE) score = MAX_SCORE;
    }

    /**
     * @notice Calculate repayment history factor
     * @dev Score = (repaid_loans / total_loans) * 1000
     * @param repaidLoans Number of successfully repaid loans
     * @param totalLoans Total number of loans taken
     * @return score Repayment score (0-1000)
     */
    function calculateRepaymentScore(
        uint256 repaidLoans,
        uint256 totalLoans
    ) internal pure returns (uint256 score) {
        if (totalLoans == 0) {
            // No loan history - neutral score
            return 500;
        }

        if (repaidLoans > totalLoans) {
            repaidLoans = totalLoans;
        }

        score = (repaidLoans * MAX_SCORE) / totalLoans;
    }

    /**
     * @notice Calculate protocol diversity factor
     * @dev Score = min((unique_protocols / 10) * 1000, 1000)
     * @param uniqueProtocols Number of unique protocols interacted with
     * @return score Diversity score (0-1000)
     */
    function calculateDiversityScore(uint256 uniqueProtocols) internal pure returns (uint256 score) {
        // 10 protocols = max score
        score = (uniqueProtocols * MAX_SCORE) / 10;

        if (score > MAX_SCORE) score = MAX_SCORE;
    }

    /*//////////////////////////////////////////////////////////////
                         UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Clamp a value between min and max
     * @param value The value to clamp
     * @param minVal Minimum allowed value
     * @param maxVal Maximum allowed value
     * @return clamped The clamped value
     */
    function clamp(
        uint256 value,
        uint256 minVal,
        uint256 maxVal
    ) internal pure returns (uint256 clamped) {
        if (value < minVal) return minVal;
        if (value > maxVal) return maxVal;
        return value;
    }

    /**
     * @notice Calculate the absolute difference between two values
     * @param a First value
     * @param b Second value
     * @return diff Absolute difference
     */
    function absDiff(uint256 a, uint256 b) internal pure returns (uint256 diff) {
        return a >= b ? a - b : b - a;
    }

    /**
     * @notice Apply a decay factor based on time elapsed
     * @dev Used for time-weighted scoring
     * @param value Original value
     * @param elapsed Time elapsed in seconds
     * @param halfLife Time in seconds for value to decay to 50%
     * @return decayed The decayed value
     */
    function applyDecay(
        uint256 value,
        uint256 elapsed,
        uint256 halfLife
    ) internal pure returns (uint256 decayed) {
        if (halfLife == 0) return 0;
        if (elapsed == 0) return value;

        // Simple linear decay approximation
        // For production, consider exponential decay
        uint256 decayPeriods = elapsed / halfLife;

        if (decayPeriods >= 10) return 0; // Effectively zero

        // Reduce by 50% for each half-life period
        decayed = value >> decayPeriods;

        // Apply fractional decay for remaining time
        uint256 remainder = elapsed % halfLife;
        decayed = decayed - (decayed * remainder) / (2 * halfLife);
    }
}
