// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ScoreSBT} from "../contracts/core/ScoreSBT.sol";
import {ScoreOracle} from "../contracts/core/ScoreOracle.sol";
import {PermissionManager} from "../contracts/core/PermissionManager.sol";
import {MockDataProvider} from "../contracts/core/MockDataProvider.sol";
import {SimpleScoring} from "../contracts/scoring/SimpleScoring.sol";
import {AdvancedScoring} from "../contracts/scoring/AdvancedScoring.sol";
import {ScoreProxy} from "../contracts/upgradeability/ScoreProxy.sol";

/**
 * @title Deploy
 * @author Credora Team
 * @notice Deployment script for all Credora contracts
 */
contract Deploy is Script {
    // Deployed contract addresses
    ScoreSBT public scoreSBT;
    ScoreOracle public scoreOracle;
    PermissionManager public permissionManager;
    MockDataProvider public dataProvider;
    SimpleScoring public simpleScoring;
    AdvancedScoring public advancedScoringImpl;
    ScoreProxy public advancedScoringProxy;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Credora contracts...");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy ScoreSBT
        scoreSBT = new ScoreSBT(deployer);
        console.log("ScoreSBT deployed at:", address(scoreSBT));

        // 2. Deploy MockDataProvider
        dataProvider = new MockDataProvider(deployer);
        console.log("MockDataProvider deployed at:", address(dataProvider));

        // 3. Deploy ScoreOracle
        address[] memory initialOracles = new address[](1);
        initialOracles[0] = deployer; // Deployer is initial oracle

        scoreOracle = new ScoreOracle(
            address(scoreSBT),
            deployer,
            initialOracles
        );
        console.log("ScoreOracle deployed at:", address(scoreOracle));

        // 4. Deploy PermissionManager
        permissionManager = new PermissionManager(
            address(scoreSBT),
            deployer
        );
        console.log("PermissionManager deployed at:", address(permissionManager));

        // 5. Deploy SimpleScoring
        simpleScoring = new SimpleScoring(
            address(dataProvider),
            deployer
        );
        console.log("SimpleScoring deployed at:", address(simpleScoring));

        // 6. Deploy AdvancedScoring (upgradeable)
        advancedScoringImpl = new AdvancedScoring();
        console.log("AdvancedScoring implementation deployed at:", address(advancedScoringImpl));

        // Deploy proxy
        bytes memory initData = abi.encodeWithSelector(
            AdvancedScoring.initialize.selector,
            address(dataProvider),
            deployer
        );

        advancedScoringProxy = new ScoreProxy(
            address(advancedScoringImpl),
            initData
        );
        console.log("AdvancedScoring proxy deployed at:", address(advancedScoringProxy));

        // 7. Configure permissions
        // Authorize ScoreOracle to update scores
        scoreSBT.setAuthorizedUpdater(address(scoreOracle), true);
        console.log("ScoreOracle authorized as updater");

        // Authorize PermissionManager as consumer
        permissionManager.setAuthorizedConsumer(address(scoreOracle), true);
        console.log("ScoreOracle authorized as consumer");

        vm.stopBroadcast();

        // Log summary
        console.log("\n=== Deployment Summary ===");
        console.log("ScoreSBT:", address(scoreSBT));
        console.log("ScoreOracle:", address(scoreOracle));
        console.log("PermissionManager:", address(permissionManager));
        console.log("MockDataProvider:", address(dataProvider));
        console.log("SimpleScoring:", address(simpleScoring));
        console.log("AdvancedScoring (proxy):", address(advancedScoringProxy));
        console.log("========================\n");
    }
}

/**
 * @title DeployLocal
 * @notice Simplified deployment for local Anvil testing
 */
contract DeployLocal is Script {
    function run() external {
        // Use default Anvil private key
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy core contracts
        ScoreSBT scoreSBT = new ScoreSBT(deployer);
        MockDataProvider dataProvider = new MockDataProvider(deployer);

        address[] memory oracles = new address[](1);
        oracles[0] = deployer;

        ScoreOracle scoreOracle = new ScoreOracle(
            address(scoreSBT),
            deployer,
            oracles
        );

        PermissionManager permissionManager = new PermissionManager(
            address(scoreSBT),
            deployer
        );

        SimpleScoring simpleScoring = new SimpleScoring(
            address(dataProvider),
            deployer
        );

        // Configure
        scoreSBT.setAuthorizedUpdater(address(scoreOracle), true);

        vm.stopBroadcast();

        console.log("=== Local Deployment ===");
        console.log("ScoreSBT:", address(scoreSBT));
        console.log("DataProvider:", address(dataProvider));
        console.log("ScoreOracle:", address(scoreOracle));
        console.log("PermissionManager:", address(permissionManager));
        console.log("SimpleScoring:", address(simpleScoring));
    }
}
