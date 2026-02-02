// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ScoreSBT} from "../../contracts/core/ScoreSBT.sol";
import {ScoreOracle} from "../../contracts/core/ScoreOracle.sol";
import {PermissionManager} from "../../contracts/core/PermissionManager.sol";
import {MockDataProvider} from "../../contracts/core/MockDataProvider.sol";
import {SimpleScoring} from "../../contracts/scoring/SimpleScoring.sol";
import {IPermissionManager} from "../../contracts/interfaces/IPermissionManager.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";

/**
 * @title FullFlowTest
 * @notice Integration tests for the complete Credora flow
 */
contract FullFlowTest is Test {
    ScoreSBT public scoreSBT;
    ScoreOracle public scoreOracle;
    PermissionManager public permissionManager;
    MockDataProvider public dataProvider;
    SimpleScoring public scoring;

    address public owner = address(1);
    address public oracle = address(2);
    address public user1 = address(3);
    address public lendingProtocol = address(4);

    uint256 public oraclePrivateKey = 0x1234;

    function setUp() public {
        oracle = vm.addr(oraclePrivateKey);

        vm.startPrank(owner);

        // Deploy all contracts
        scoreSBT = new ScoreSBT(owner);
        dataProvider = new MockDataProvider(owner);

        address[] memory oracles = new address[](1);
        oracles[0] = oracle;
        scoreOracle = new ScoreOracle(address(scoreSBT), owner, oracles);

        permissionManager = new PermissionManager(address(scoreSBT), owner);
        scoring = new SimpleScoring(address(dataProvider), owner);

        // Configure permissions
        scoreSBT.setAuthorizedUpdater(address(scoreOracle), true);
        permissionManager.setAuthorizedConsumer(lendingProtocol, true);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                         FULL FLOW TESTS
    //////////////////////////////////////////////////////////////*/

    function test_FullUserJourney() public {
        // === Step 1: User mints SBT ===
        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();
        assertEq(tokenId, 1);
        assertTrue(scoreSBT.hasSoulboundToken(user1));

        // === Step 2: Setup mock data ===
        vm.prank(owner);
        dataProvider.setMockData(
            user1,
            block.timestamp - 365 days,  // 1 year old wallet
            100,                          // 100 transactions
            100 ether,                    // 100 ETH volume
            8,                            // 8 repaid loans
            10,                           // 10 total loans
            5                             // 5 protocols used
        );

        // === Step 3: Calculate score off-chain (simulated) ===
        DataTypes.ScoreOutput memory scoreOutput = scoring.calculateScore(user1);
        assertGt(scoreOutput.totalScore, 0);
        console.log("Calculated score:", scoreOutput.totalScore);

        // === Step 4: Oracle submits score update ===
        vm.warp(block.timestamp + 2 hours); // Wait for update interval

        vm.prank(oracle);
        scoreOracle.submitScoreUpdateDirect(
            user1,
            scoreOutput.totalScore,
            keccak256(abi.encode(scoreOutput))
        );

        // Verify score was updated
        DataTypes.CreditScore memory storedScore = scoreSBT.getScoreByAddress(user1);
        assertEq(storedScore.score, scoreOutput.totalScore);

        // === Step 5: User grants permission to lending protocol ===
        vm.prank(user1);
        bytes32 permissionId = permissionManager.grantAccess(
            lendingProtocol,
            30 days,
            1000
        );
        assertTrue(permissionId != bytes32(0));

        // === Step 6: Lending protocol consumes permission and gets score ===
        assertTrue(permissionManager.hasValidPermission(user1, lendingProtocol));

        vm.prank(lendingProtocol);
        bool consumeSuccess = permissionManager.consumeAccess(user1, lendingProtocol);
        assertTrue(consumeSuccess);

        // Protocol can now read the score
        uint256 userScore = scoreSBT.getScoreValue(user1);
        assertGt(userScore, 0);
        console.log("Protocol accessed score:", userScore);

        // === Step 7: User revokes access ===
        vm.prank(user1);
        permissionManager.revokeAccess(lendingProtocol);

        assertFalse(permissionManager.hasValidPermission(user1, lendingProtocol));
    }

    function test_MultipleUsersAndProtocols() public {
        address user2 = address(5);
        address user3 = address(6);
        address protocol2 = address(7);

        vm.prank(owner);
        permissionManager.setAuthorizedConsumer(protocol2, true);

        // Multiple users mint SBTs
        vm.prank(user1);
        scoreSBT.mintSelf();

        vm.prank(user2);
        scoreSBT.mintSelf();

        vm.prank(user3);
        scoreSBT.mintSelf();

        // Set different data for each user
        vm.startPrank(owner);
        dataProvider.setMockData(user1, block.timestamp - 730 days, 200, 500 ether, 20, 20, 10);
        dataProvider.setMockData(user2, block.timestamp - 180 days, 50, 10 ether, 3, 5, 3);
        dataProvider.setMockData(user3, block.timestamp - 30 days, 10, 1 ether, 0, 0, 1);
        vm.stopPrank();

        // Users grant different permissions
        vm.prank(user1);
        permissionManager.grantAccess(lendingProtocol, 365 days, 10000);

        vm.prank(user2);
        permissionManager.grantAccess(lendingProtocol, 30 days, 100);

        vm.prank(user2);
        permissionManager.grantAccess(protocol2, 7 days, 10);

        vm.prank(user3);
        permissionManager.grantAccess(protocol2, 1 days, 5);

        // Verify permissions
        assertTrue(permissionManager.hasValidPermission(user1, lendingProtocol));
        assertTrue(permissionManager.hasValidPermission(user2, lendingProtocol));
        assertTrue(permissionManager.hasValidPermission(user2, protocol2));
        assertTrue(permissionManager.hasValidPermission(user3, protocol2));

        assertFalse(permissionManager.hasValidPermission(user1, protocol2));
        assertFalse(permissionManager.hasValidPermission(user3, lendingProtocol));
    }

    function test_ScoreUpdateAndRefresh() public {
        vm.prank(user1);
        scoreSBT.mintSelf();

        vm.prank(owner);
        dataProvider.setMockData(user1, block.timestamp - 100 days, 30, 20 ether, 5, 6, 3);

        // First score update
        vm.warp(block.timestamp + 2 hours);
        vm.prank(oracle);
        scoreOracle.submitScoreUpdateDirect(user1, 500, bytes32("hash1"));

        assertEq(scoreSBT.getScoreValue(user1), 500);

        // User improves their on-chain behavior
        vm.prank(owner);
        dataProvider.setMockData(user1, block.timestamp - 200 days, 100, 100 ether, 15, 15, 8);

        // Wait and update again
        vm.warp(block.timestamp + 2 hours);
        vm.prank(oracle);
        scoreOracle.submitScoreUpdateDirect(user1, 750, bytes32("hash2"));

        assertEq(scoreSBT.getScoreValue(user1), 750);

        // Verify update count
        DataTypes.CreditScore memory score = scoreSBT.getScoreByAddress(user1);
        assertEq(score.updateCount, 2);
    }

    function test_PermissionQuotaEnforcement() public {
        vm.prank(user1);
        scoreSBT.mintSelf();

        vm.prank(user1);
        permissionManager.grantAccess(lendingProtocol, 30 days, 3);

        // Use all quota
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(lendingProtocol);
            assertTrue(permissionManager.consumeAccess(user1, lendingProtocol));
        }

        // Next attempt should fail
        vm.prank(lendingProtocol);
        assertFalse(permissionManager.consumeAccess(user1, lendingProtocol));

        // But permission still exists (just exhausted)
        IPermissionManager.AccessPermission memory perm = permissionManager.getPermission(user1, lendingProtocol);
        assertTrue(perm.isActive);
        assertEq(perm.usedRequests, 3);
    }

    function test_PermissionExpiration() public {
        vm.prank(user1);
        scoreSBT.mintSelf();

        vm.prank(user1);
        permissionManager.grantAccess(lendingProtocol, 1 hours, 100);

        assertTrue(permissionManager.hasValidPermission(user1, lendingProtocol));

        // Time travel past expiration
        vm.warp(block.timestamp + 2 hours);

        assertFalse(permissionManager.hasValidPermission(user1, lendingProtocol));

        // Consume should fail
        vm.prank(lendingProtocol);
        assertFalse(permissionManager.consumeAccess(user1, lendingProtocol));
    }

    function test_RecoveryPreservesScore() public {
        address recoveryAddr = address(10);

        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();

        // Update score
        vm.warp(block.timestamp + 2 hours);
        vm.prank(oracle);
        scoreOracle.submitScoreUpdateDirect(user1, 800, bytes32("proof"));

        // Setup recovery
        vm.prank(user1);
        scoreSBT.setRecoveryAddress(tokenId, recoveryAddr);

        vm.prank(recoveryAddr);
        scoreSBT.initiateRecovery(tokenId);

        vm.warp(block.timestamp + 7 days + 1);

        vm.prank(recoveryAddr);
        scoreSBT.completeRecovery(tokenId);

        // Verify recovery succeeded and score preserved
        assertEq(scoreSBT.ownerOf(tokenId), recoveryAddr);
        assertEq(scoreSBT.getScoreValue(recoveryAddr), 800);
    }
}
