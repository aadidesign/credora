// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ScoreSBT} from "../../contracts/core/ScoreSBT.sol";
import {ISoulbound} from "../../contracts/interfaces/ISoulbound.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";

/**
 * @title ScoreSBTTest
 * @notice Unit tests for ScoreSBT contract
 */
contract ScoreSBTTest is Test {
    ScoreSBT public scoreSBT;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public oracle = address(4);
    address public recoveryAddress = address(5);

    event ScoreMinted(address indexed owner, uint256 indexed tokenId);
    event ScoreUpdated(
        uint256 indexed tokenId,
        uint256 oldScore,
        uint256 newScore,
        uint256 dataVersion,
        address indexed updatedBy
    );
    event RecoveryAddressSet(uint256 indexed tokenId, address indexed recoveryAddress);
    event RecoveryInitiated(uint256 indexed tokenId, address indexed from, address indexed to);
    event RecoveryCompleted(uint256 indexed tokenId, address indexed newOwner);

    function setUp() public {
        vm.startPrank(owner);
        scoreSBT = new ScoreSBT(owner);
        scoreSBT.setAuthorizedUpdater(oracle, true);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            MINTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Mint() public {
        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();

        assertEq(tokenId, 1);
        assertEq(scoreSBT.ownerOf(tokenId), user1);
        assertTrue(scoreSBT.hasSoulboundToken(user1));
        assertEq(scoreSBT.getTokenIdByAddress(user1), tokenId);
    }

    function test_MintForOther() public {
        uint256 tokenId = scoreSBT.mint(user1);

        assertEq(scoreSBT.ownerOf(tokenId), user1);
        assertTrue(scoreSBT.hasSoulboundToken(user1));
    }

    function test_RevertDoubleMint() public {
        vm.prank(user1);
        scoreSBT.mintSelf();

        vm.expectRevert("Already have SBT");
        vm.prank(user1);
        scoreSBT.mintSelf();
    }

    function test_RevertMintToZeroAddress() public {
        vm.expectRevert("Cannot mint to zero address");
        scoreSBT.mint(address(0));
    }

    function test_MintInitializesScore() public {
        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();

        DataTypes.CreditScore memory score = scoreSBT.getScore(tokenId);
        assertEq(score.score, 0);
        assertEq(score.dataVersion, 1);
        assertEq(score.updateCount, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        SOULBOUND TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertTransfer() public {
        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();

        vm.expectRevert(ISoulbound.SoulboundTransferNotAllowed.selector);
        vm.prank(user1);
        scoreSBT.transferFrom(user1, user2, tokenId);
    }

    function test_RevertSafeTransfer() public {
        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();

        vm.expectRevert(ISoulbound.SoulboundTransferNotAllowed.selector);
        vm.prank(user1);
        scoreSBT.safeTransferFrom(user1, user2, tokenId, "");
    }

    function test_RevertApprove() public {
        vm.prank(user1);
        scoreSBT.mintSelf();

        vm.expectRevert(ISoulbound.SoulboundApprovalNotAllowed.selector);
        vm.prank(user1);
        scoreSBT.approve(user2, 1);
    }

    function test_RevertSetApprovalForAll() public {
        vm.prank(user1);
        scoreSBT.mintSelf();

        vm.expectRevert(ISoulbound.SoulboundApprovalNotAllowed.selector);
        vm.prank(user1);
        scoreSBT.setApprovalForAll(user2, true);
    }

    /*//////////////////////////////////////////////////////////////
                        SCORE UPDATE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_UpdateScore() public {
        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();

        // Wait for minimum update interval
        vm.warp(block.timestamp + 1 hours + 1);

        vm.prank(oracle);
        scoreSBT.updateScore(tokenId, 750, 2, bytes32("proof"));

        DataTypes.CreditScore memory score = scoreSBT.getScore(tokenId);
        assertEq(score.score, 750);
        assertEq(score.dataVersion, 2);
        assertEq(score.scoreProof, bytes32("proof"));
        assertEq(score.updateCount, 1);
    }

    function test_GetScoreByAddress() public {
        vm.prank(user1);
        scoreSBT.mintSelf();

        vm.warp(block.timestamp + 1 hours + 1);

        vm.prank(oracle);
        scoreSBT.updateScore(1, 500, 1, bytes32(0));

        DataTypes.CreditScore memory score = scoreSBT.getScoreByAddress(user1);
        assertEq(score.score, 500);
    }

    function test_GetScoreValue() public {
        vm.prank(user1);
        scoreSBT.mintSelf();

        vm.warp(block.timestamp + 1 hours + 1);

        vm.prank(oracle);
        scoreSBT.updateScore(1, 850, 1, bytes32(0));

        uint256 scoreValue = scoreSBT.getScoreValue(user1);
        assertEq(scoreValue, 850);
    }

    function test_RevertUpdateTooFrequent() public {
        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();

        // Try to update immediately (should fail)
        vm.expectRevert("Update too frequent");
        vm.prank(oracle);
        scoreSBT.updateScore(tokenId, 500, 1, bytes32(0));
    }

    function test_RevertUpdateExceedsMaxScore() public {
        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();

        vm.warp(block.timestamp + 1 hours + 1);

        vm.expectRevert("Score exceeds maximum");
        vm.prank(oracle);
        scoreSBT.updateScore(tokenId, 1001, 1, bytes32(0));
    }

    function test_RevertUnauthorizedUpdate() public {
        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();

        vm.warp(block.timestamp + 1 hours + 1);

        vm.expectRevert("Not authorized updater");
        vm.prank(user2);
        scoreSBT.updateScore(tokenId, 500, 1, bytes32(0));
    }

    /*//////////////////////////////////////////////////////////////
                         RECOVERY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetRecoveryAddress() public {
        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();

        vm.prank(user1);
        scoreSBT.setRecoveryAddress(tokenId, recoveryAddress);

        assertEq(scoreSBT.getRecoveryAddress(tokenId), recoveryAddress);
    }

    function test_RecoveryFlow() public {
        // Mint token
        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();

        // Set recovery address
        vm.prank(user1);
        scoreSBT.setRecoveryAddress(tokenId, recoveryAddress);

        // Initiate recovery
        vm.prank(recoveryAddress);
        scoreSBT.initiateRecovery(tokenId);

        DataTypes.RecoveryRequest memory request = scoreSBT.getPendingRecovery(tokenId);
        assertEq(request.initiatedBy, recoveryAddress);
        assertFalse(request.cancelled);

        // Wait cooldown (7 days)
        vm.warp(block.timestamp + 7 days + 1);

        // Complete recovery
        vm.prank(recoveryAddress);
        scoreSBT.completeRecovery(tokenId);

        assertEq(scoreSBT.ownerOf(tokenId), recoveryAddress);
        assertTrue(scoreSBT.hasSoulboundToken(recoveryAddress));
        assertFalse(scoreSBT.hasSoulboundToken(user1));
    }

    function test_CancelRecovery() public {
        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();

        vm.prank(user1);
        scoreSBT.setRecoveryAddress(tokenId, recoveryAddress);

        vm.prank(recoveryAddress);
        scoreSBT.initiateRecovery(tokenId);

        vm.prank(user1);
        scoreSBT.cancelRecovery(tokenId);

        DataTypes.RecoveryRequest memory request = scoreSBT.getPendingRecovery(tokenId);
        assertEq(request.initiatedAt, 0); // Deleted
    }

    /*//////////////////////////////////////////////////////////////
                            BURN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Burn() public {
        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();

        vm.prank(user1);
        scoreSBT.burn(tokenId);

        assertFalse(scoreSBT.hasSoulboundToken(user1));
        assertEq(scoreSBT.getTokenIdByAddress(user1), 0);
    }

    function test_CanMintAfterBurn() public {
        vm.prank(user1);
        uint256 tokenId1 = scoreSBT.mintSelf();

        vm.prank(user1);
        scoreSBT.burn(tokenId1);

        vm.prank(user1);
        uint256 tokenId2 = scoreSBT.mintSelf();

        assertEq(tokenId2, 2);
        assertTrue(scoreSBT.hasSoulboundToken(user1));
    }

    /*//////////////////////////////////////////////////////////////
                         ADMIN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetAuthorizedUpdater() public {
        address newOracle = address(10);

        vm.prank(owner);
        scoreSBT.setAuthorizedUpdater(newOracle, true);

        assertTrue(scoreSBT.authorizedUpdaters(newOracle));
    }

    function test_SetBaseURI() public {
        vm.prank(owner);
        scoreSBT.setBaseURI("https://api.credora.io/score/");
    }

    /*//////////////////////////////////////////////////////////////
                         UTILITY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_TotalMinted() public {
        assertEq(scoreSBT.totalMinted(), 0);

        vm.prank(user1);
        scoreSBT.mintSelf();

        assertEq(scoreSBT.totalMinted(), 1);

        vm.prank(user2);
        scoreSBT.mintSelf();

        assertEq(scoreSBT.totalMinted(), 2);
    }

    function test_IsScoreStale() public {
        vm.prank(user1);
        uint256 tokenId = scoreSBT.mintSelf();

        // Initially not stale (for short maxAge)
        assertFalse(scoreSBT.isScoreStale(tokenId, 1 hours));

        // After time passes, becomes stale
        vm.warp(block.timestamp + 2 hours);
        assertTrue(scoreSBT.isScoreStale(tokenId, 1 hours));
    }
}
