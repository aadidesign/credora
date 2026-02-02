// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ISoulbound
 * @author Credora Team
 * @notice Interface for Soulbound (non-transferable) tokens
 * @dev Extends ERC-721 with transfer restrictions and recovery mechanisms
 */
interface ISoulbound {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when attempting to transfer a soulbound token
    error SoulboundTransferNotAllowed();

    /// @notice Thrown when attempting to approve transfers
    error SoulboundApprovalNotAllowed();

    /// @notice Thrown when recovery is attempted by non-recovery address
    error UnauthorizedRecovery();

    /// @notice Thrown when recovery cooldown has not elapsed
    error RecoveryCooldownActive();

    /// @notice Thrown when address already owns a soulbound token
    error AlreadyHasSoulboundToken();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a recovery address is set
    /// @param tokenId The token being configured
    /// @param recoveryAddress The address authorized for recovery
    event RecoveryAddressSet(uint256 indexed tokenId, address indexed recoveryAddress);

    /// @notice Emitted when a recovery is initiated
    /// @param tokenId The token being recovered
    /// @param from The current owner
    /// @param to The recovery address
    event RecoveryInitiated(uint256 indexed tokenId, address indexed from, address indexed to);

    /// @notice Emitted when a recovery is completed
    /// @param tokenId The token that was recovered
    /// @param newOwner The new owner after recovery
    event RecoveryCompleted(uint256 indexed tokenId, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if a token is soulbound (non-transferable)
     * @param tokenId The token to check
     * @return True if the token is soulbound
     */
    function isSoulbound(uint256 tokenId) external view returns (bool);

    /**
     * @notice Get the recovery address for a token
     * @param tokenId The token to query
     * @return The recovery address, or zero if not set
     */
    function getRecoveryAddress(uint256 tokenId) external view returns (address);

    /**
     * @notice Check if an address already has a soulbound token
     * @param account The address to check
     * @return True if the address owns a soulbound token
     */
    function hasSoulboundToken(address account) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                           WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set a recovery address for emergency token recovery
     * @dev Can only be called by the token owner
     * @param tokenId The token to configure
     * @param recoveryAddress The address authorized to initiate recovery
     */
    function setRecoveryAddress(uint256 tokenId, address recoveryAddress) external;

    /**
     * @notice Initiate the recovery process
     * @dev Can only be called by the designated recovery address
     * @param tokenId The token to recover
     */
    function initiateRecovery(uint256 tokenId) external;

    /**
     * @notice Complete a recovery after the cooldown period
     * @param tokenId The token being recovered
     */
    function completeRecovery(uint256 tokenId) external;

    /**
     * @notice Cancel an ongoing recovery
     * @dev Can only be called by the current token owner
     * @param tokenId The token with pending recovery
     */
    function cancelRecovery(uint256 tokenId) external;

    /**
     * @notice Burn a soulbound token
     * @dev Required for account migration scenarios
     * @param tokenId The token to burn
     */
    function burn(uint256 tokenId) external;
}
