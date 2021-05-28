// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the IUTokens.
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
    * @dev Returns the staked block of the user's address.
    */
    function getStakedBlock(address to) external view returns (uint256);

    /**
    * @dev Returns the reward rate set by the admin.
    */
    function getRewardRate() external view returns (uint256);

    /**
     * @dev Returns the pending reward owned by `account`..
     */
    function calculatePendingRewards(address to) external view returns (uint256);

    /**
     * @dev Calculates rewards `amount` tokens to the caller's address `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {TriggeredCalculateRewards} event.
     */
    function calculateRewards(address to) external returns (bool);

    /**
    * @dev Set LiquidStaking smart contract.
    */
    function setLiquidStakingContract(address liquidStakingContract) external;

    /**
     * @dev Set UTokens smart contract.
     *
     *
     * Emits a {SetContract} event.
     */
    function setUTokensContract(address utokenContract) external;

    /**
     * @dev Pause smart contracts
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {pause} event.
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

    /**
     * @dev Emitted when contract addresses are set
     */
    event SetContract( address indexed _contract );

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