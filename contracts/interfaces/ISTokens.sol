// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the ISTokens.
 */
interface ISTokens is IERC20Upgradeable {

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
     * @dev Sets `reward rate`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function setRewardRate(uint256 rate) external returns (bool);

      /**
     * @dev Calculates rewards `amount` tokens to the caller's address `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {TriggeredCalculateRewards} event.
     */
    function calculateRewards(address to) external returns (bool);

    /**
     * @dev Set UTokens smart contract.
     *
     *
     * Emits a {SetContract} event.
     */
    function setUTokensContract(address utokenContract) external;

    /**
    * @dev Set LiquidStaking smart contract.
    */
    function setLiquidStakingContract(address liquidStakingContract) external;

    /**
     * @dev Emitted when contract addresses are set
     */
    event SetUTokensContract( address indexed _contract );

    /**
     * @dev Emitted when contract addresses are set
     */
    event SetLiquidStakingContract( address indexed _contract );

    /**
     * @dev Emitted when `rewards` tokens are moved to account
     *
     * Note that `value` may be zero.
     */
    event CalculateRewards(address indexed accountAddress, uint256 tokens, uint256 timestamp);

    /**
     * @dev Emitted when `rewards` tokens are moved to account
     *
     * Note that `value` may be zero.
     */
    event TriggeredCalculateRewards(address indexed accountAddress, uint256 tokens, uint256 timestamp);


}