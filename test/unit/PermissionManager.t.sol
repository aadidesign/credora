// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {PermissionManager} from "../../contracts/core/PermissionManager.sol";
import {ScoreSBT} from "../../contracts/core/ScoreSBT.sol";
import {IPermissionManager} from "../../contracts/interfaces/IPermissionManager.sol";

/**
 * @title PermissionManagerTest
 * @notice Unit tests for PermissionManager contract
 */
contract PermissionManagerTest is Test {
    PermissionManager public permissionManager;
    ScoreSBT public scoreSBT;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public protocol1 = address(4);
    address public protocol2 = address(5);

    function setUp() public {
        vm.startPrank(owner);
        scoreSBT = new ScoreSBT(owner);
        permissionManager = new PermissionManager(address(scoreSBT), owner);
        permissionManager.setAuthorizedConsumer(protocol1, true);
        vm.stopPrank();

        // User1 mints an SBT
        vm.prank(user1);
        scoreSBT.mintSelf();
    }

    /*//////////////////////////////////////////////////////////////
                         GRANT ACCESS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GrantAccess() public {
        vm.prank(user1);
        bytes32 permissionId = permissionManager.grantAccess(
            protocol1,
            1 days,
            100
        );

        assertTrue(permissionId != bytes32(0));
        assertTrue(permissionManager.hasValidPermission(user1, protocol1));

        IPermissionManager.AccessPermission memory perm = permissionManager.getPermission(user1, protocol1);
        assertEq(perm.protocol, protocol1);
        assertEq(perm.maxRequests, 100);
        assertTrue(perm.isActive);
    }

    function test_GrantAccessMinDuration() public {
        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 1 hours, 10);

        assertTrue(permissionManager.hasValidPermission(user1, protocol1));
    }

    function test_GrantAccessMaxDuration() public {
        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 365 days, 1000);

        assertTrue(permissionManager.hasValidPermission(user1, protocol1));
    }

    function test_RevertNoSBT() public {
        vm.expectRevert("No credit score SBT");
        vm.prank(user2); // user2 has no SBT
        permissionManager.grantAccess(protocol1, 1 days, 100);
    }

    function test_RevertInvalidDuration() public {
        // Too short
        vm.expectRevert(IPermissionManager.InvalidDuration.selector);
        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 30 minutes, 100);

        // Too long
        vm.expectRevert(IPermissionManager.InvalidDuration.selector);
        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 400 days, 100);
    }

    function test_RevertZeroMaxRequests() public {
        vm.expectRevert(IPermissionManager.InvalidDuration.selector);
        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 1 days, 0);
    }

    function test_RevertInvalidProtocol() public {
        vm.expectRevert(IPermissionManager.InvalidProtocol.selector);
        vm.prank(user1);
        permissionManager.grantAccess(address(0), 1 days, 100);
    }

    /*//////////////////////////////////////////////////////////////
                        REVOKE ACCESS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevokeAccess() public {
        vm.startPrank(user1);
        permissionManager.grantAccess(protocol1, 1 days, 100);
        assertTrue(permissionManager.hasValidPermission(user1, protocol1));

        permissionManager.revokeAccess(protocol1);
        assertFalse(permissionManager.hasValidPermission(user1, protocol1));
        vm.stopPrank();
    }

    function test_RevertRevokeNonexistent() public {
        vm.expectRevert(IPermissionManager.PermissionNotFound.selector);
        vm.prank(user1);
        permissionManager.revokeAccess(protocol1);
    }

    /*//////////////////////////////////////////////////////////////
                       CONSUME ACCESS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ConsumeAccess() public {
        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 1 days, 10);

        vm.prank(protocol1);
        bool valid = permissionManager.consumeAccess(user1, protocol1);

        assertTrue(valid);
        assertEq(permissionManager.getRemainingQuota(user1, protocol1), 9);
    }

    function test_ConsumeAccessAuthorizedConsumer() public {
        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 1 days, 10);

        // protocol1 is authorized consumer, can consume
        vm.prank(protocol1);
        bool valid = permissionManager.consumeAccess(user1, protocol1);
        assertTrue(valid);
    }

    function test_ConsumeAccessQuotaExhaustion() public {
        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 1 days, 3);

        // Consume all quota
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(protocol1);
            assertTrue(permissionManager.consumeAccess(user1, protocol1));
        }

        // Next consume should fail
        vm.prank(protocol1);
        assertFalse(permissionManager.consumeAccess(user1, protocol1));
    }

    function test_ConsumeAccessExpired() public {
        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 1 hours, 100);

        // Fast forward past expiration
        vm.warp(block.timestamp + 2 hours);

        vm.prank(protocol1);
        bool valid = permissionManager.consumeAccess(user1, protocol1);
        assertFalse(valid);
    }

    function test_ConsumeAccessUnauthorized() public {
        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 1 days, 10);

        // user2 is not authorized consumer
        vm.expectRevert("Unauthorized consumer");
        vm.prank(user2);
        permissionManager.consumeAccess(user1, protocol1);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetRemainingQuota() public {
        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 1 days, 50);

        assertEq(permissionManager.getRemainingQuota(user1, protocol1), 50);

        vm.prank(protocol1);
        permissionManager.consumeAccess(user1, protocol1);

        assertEq(permissionManager.getRemainingQuota(user1, protocol1), 49);
    }

    function test_GetRemainingTime() public {
        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 1 days, 50);

        uint256 remaining = permissionManager.getRemainingTime(user1, protocol1);
        assertGt(remaining, 0);
        assertLe(remaining, 1 days);
    }

    function test_GetAllPermissions() public {
        vm.startPrank(user1);
        permissionManager.grantAccess(protocol1, 1 days, 10);
        permissionManager.grantAccess(protocol2, 2 days, 20);
        vm.stopPrank();

        IPermissionManager.AccessPermission[] memory perms = permissionManager.getAllPermissions(user1);
        assertEq(perms.length, 2);
    }

    function test_GetPermissionCount() public {
        vm.startPrank(user1);
        permissionManager.grantAccess(protocol1, 1 days, 10);

        assertEq(permissionManager.getPermissionCount(user1), 1);

        permissionManager.grantAccess(protocol2, 1 days, 10);

        assertEq(permissionManager.getPermissionCount(user1), 2);
        vm.stopPrank();
    }

    function test_HasValidPermission() public {
        assertFalse(permissionManager.hasValidPermission(user1, protocol1));

        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 1 days, 10);

        assertTrue(permissionManager.hasValidPermission(user1, protocol1));
    }

    /*//////////////////////////////////////////////////////////////
                          WHITELIST TESTS
    //////////////////////////////////////////////////////////////*/

    function test_EnableWhitelist() public {
        vm.prank(owner);
        permissionManager.setWhitelistEnabled(true);

        assertTrue(permissionManager.whitelistEnabled());
    }

    function test_WhitelistProtocol() public {
        vm.startPrank(owner);
        permissionManager.setWhitelistEnabled(true);
        permissionManager.setProtocolWhitelist(protocol1, true);
        vm.stopPrank();

        assertTrue(permissionManager.whitelistedProtocols(protocol1));

        // Can grant access to whitelisted protocol
        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 1 days, 10);
    }

    function test_RevertNonWhitelistedProtocol() public {
        vm.prank(owner);
        permissionManager.setWhitelistEnabled(true);

        vm.expectRevert(IPermissionManager.InvalidProtocol.selector);
        vm.prank(user1);
        permissionManager.grantAccess(protocol1, 1 days, 10);
    }

    function test_BatchWhitelist() public {
        address[] memory protocols = new address[](2);
        protocols[0] = protocol1;
        protocols[1] = protocol2;

        vm.prank(owner);
        permissionManager.batchSetProtocolWhitelist(protocols, true);

        assertTrue(permissionManager.whitelistedProtocols(protocol1));
        assertTrue(permissionManager.whitelistedProtocols(protocol2));
    }
}
