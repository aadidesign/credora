// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title ScoreProxy
 * @author Credora Team
 * @notice UUPS-compatible proxy for upgradeable scoring contracts
 * @dev Simple wrapper around ERC1967Proxy for clarity
 */
contract ScoreProxy is ERC1967Proxy {
    /**
     * @notice Initialize the proxy with implementation and init data
     * @param _logic Address of the implementation contract
     * @param _data Initialization calldata
     */
    constructor(
        address _logic,
        bytes memory _data
    ) ERC1967Proxy(_logic, _data) {}
}
