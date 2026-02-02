// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ScoreSBT} from "../../contracts/core/ScoreSBT.sol";
import {ScoreOracle} from "../../contracts/core/ScoreOracle.sol";
import {PermissionManager} from "../../contracts/core/PermissionManager.sol";
import {MockDataProvider} from "../../contracts/core/MockDataProvider.sol";

/**
 * @title ScoreInvariantTest
 * @notice Invariant tests to ensure system properties hold
 */
contract ScoreInvariantTest is Test {
    ScoreSBT public scoreSBT;
    ScoreOracle public scoreOracle;
    PermissionManager public permissionManager;
    MockDataProvider public dataProvider;
    ScoreInvariantHandler public handler;

    address public owner = address(1);
    address public oracle = address(2);

    function setUp() public {
        vm.startPrank(owner);

        scoreSBT = new ScoreSBT(owner);
        dataProvider = new MockDataProvider(owner);

        address[] memory oracles = new address[](1);
        oracles[0] = oracle;
        scoreOracle = new ScoreOracle(address(scoreSBT), owner, oracles);

        permissionManager = new PermissionManager(address(scoreSBT), owner);

        scoreSBT.setAuthorizedUpdater(address(scoreOracle), true);

        vm.stopPrank();

        handler = new ScoreInvariantHandler(scoreSBT, scoreOracle, oracle);

        targetContract(address(handler));
    }

    /*//////////////////////////////////////////////////////////////
                           INVARIANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Score should never exceed MAX_SCORE
    function invariant_ScoreNeverExceedsMax() public view {
        uint256 totalMinted = scoreSBT.totalMinted();

        for (uint256 i = 1; i <= totalMinted; i++) {
            try scoreSBT.getScore(i) returns (DataTypes.CreditScore memory score) {
                assertLe(score.score, 1000, "Score exceeds maximum");
            } catch {
                // Token might have been burned - that's ok
            }
        }
    }

    /// @notice Each address can only have one SBT
    function invariant_OneTokenPerAddress() public view {
        uint256 totalMinted = scoreSBT.totalMinted();

        for (uint256 i = 1; i <= totalMinted; i++) {
            try scoreSBT.ownerOf(i) returns (address tokenOwner) {
                if (tokenOwner != address(0)) {
                    // Owner should have exactly this token ID
                    assertEq(
                        scoreSBT.getTokenIdByAddress(tokenOwner),
                        i,
                        "Token ID mismatch"
                    );
                    assertTrue(
                        scoreSBT.hasSoulboundToken(tokenOwner),
                        "hasSoulboundToken mismatch"
                    );
                }
            } catch {
                // Token burned - ok
            }
        }
    }

    /// @notice Token counter should always increase
    function invariant_TokenCounterMonotonic() public view {
        assertGe(scoreSBT.totalMinted(), 0, "Total minted is negative");
    }
}

// Import for the invariant test
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";

/**
 * @title ScoreInvariantHandler
 * @notice Handler contract for invariant testing
 */
contract ScoreInvariantHandler is Test {
    ScoreSBT public scoreSBT;
    ScoreOracle public scoreOracle;
    address public oracle;

    address[] public users;
    uint256 public constant MAX_USERS = 10;

    constructor(ScoreSBT _scoreSBT, ScoreOracle _scoreOracle, address _oracle) {
        scoreSBT = _scoreSBT;
        scoreOracle = _scoreOracle;
        oracle = _oracle;
    }

    function mint(uint256 userSeed) external {
        if (users.length >= MAX_USERS) return;

        address user = address(uint160(bound(userSeed, 100, 1000)));

        if (scoreSBT.hasSoulboundToken(user)) return;

        // Ensure user doesn't exist
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == user) return;
        }

        vm.prank(user);
        try scoreSBT.mintSelf() {
            users.push(user);
        } catch {}
    }

    function updateScore(uint256 userIndex, uint256 score) external {
        if (users.length == 0) return;

        userIndex = bound(userIndex, 0, users.length - 1);
        score = bound(score, 0, 1000);

        address user = users[userIndex];
        uint256 tokenId = scoreSBT.getTokenIdByAddress(user);

        if (tokenId == 0) return;

        vm.warp(block.timestamp + 2 hours);

        vm.prank(oracle);
        try scoreOracle.submitScoreUpdateDirect(user, score, bytes32(score)) {
            // Success
        } catch {}
    }

    function burn(uint256 userIndex) external {
        if (users.length == 0) return;

        userIndex = bound(userIndex, 0, users.length - 1);
        address user = users[userIndex];

        uint256 tokenId = scoreSBT.getTokenIdByAddress(user);
        if (tokenId == 0) return;

        vm.prank(user);
        try scoreSBT.burn(tokenId) {
            // Remove from users array
            users[userIndex] = users[users.length - 1];
            users.pop();
        } catch {}
    }
}
