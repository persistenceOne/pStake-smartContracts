// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the IUTokens.
 */
interface IUTokens is IERC20Upgradeable {

    /**
     * @dev Mints `amount` tokens to the caller's address `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function mint(address to, uint256 tokens) external returns (bool);

    /**
     * @dev Burns `amount` tokens to the caller's address `from`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function burn(address from, uint256 tokens) external returns (bool);

    /**
    * @dev Set LiquidStaking smart contract.
    */
    function setLiquidStakingContract(address liquidStakingContract) external;

    /**
     * @dev Set STokens smart contract.
     */
    function setSTokenContract(address stokenContract) external;

    /**
     * @dev Set PegTokens smart contract.
     */
    function setWrapperContract(address wrapperTokensContract) external;

    /**
     * @dev Pause smart contracts
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Pause} event.
     */
    function pause() external returns (bool);

    /**
     * @dev Pause smart contracts
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Unpaused} event.
     */
    function unpause() external returns (bool);
}