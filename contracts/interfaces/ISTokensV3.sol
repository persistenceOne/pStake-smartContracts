// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the ISTokens.
 */
interface ISTokensV3 is IERC20Upgradeable {
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
	function setRewardRate(uint256 rewardRate) external returns (bool success);

	/**
	 * @dev get reward rate and value divisor
	 */
	function getRewardRate()
		external
		view
		returns (
			uint256[] memory rewardRate,
			uint256[] memory lastMovingRewardTimestamp,
			uint256 valueDivisor
		);

	/**
	 * @dev calculates the reward that is pending to be received.
	 *
	 * Returns pending reward.
	 */
	function calculatePendingRewards(address to)
		external
		view
		returns (uint256 pendingRewards);

	/**
	 * @dev Calculates rewards `amount` tokens to the caller's address `to`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {TriggeredCalculateRewards} event.
	 */
	function calculateRewards(address to) external returns (uint256 rewards);

	/**
	 * @dev Calculates rewards `amount` tokens to the caller's address `to`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {TriggeredCalculateRewards} event.
	 */
	function calculateHolderRewards(address to)
		external
		returns (uint256 rewards);

	/**
	 * @dev Set UTokens smart contract.
	 *
	 * Emits a {SetContract} event.
	 */
	function setUTokensContract(address uTokenContract) external;

	/**
	 * @dev Set LiquidStaking smart contract.
	 */
	function setLiquidStakingContract(address liquidStakingContract) external;

	/**
	 * @dev Triggers stopped state.
	 *
	 * Requirements:
	 *
	 * - The contract must not be paused.
	 */
	function pause() external returns (bool success);

	/**
	 * @dev Returns to normal state.
	 *
	 * Requirements:
	 *
	 * - The contract must be paused.
	 */
	function unpause() external returns (bool success);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetUTokensContract(address indexed _contract);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetLiquidStakingContract(address indexed _contract);

	/**
	 * @dev Emitted when `rewards` tokens are moved to account
	 *
	 * Note that `value` may be zero.
	 */
	event CalculateRewards(
		address indexed accountAddress,
		uint256 tokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when `rewards` tokens are moved to holder account
	 *
	 * Note that `value` may be zero.
	 */
	event CalculateHolderRewards(
		address indexed accountAddress,
		uint256 tokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when `rewards` tokens are moved to account
	 *
	 * Note that `value` may be zero.
	 */
	event TriggeredCalculateRewards(
		address indexed accountAddress,
		uint256 tokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetRewardRate(uint256 indexed rewardRate);

	/**
	 * @dev Emitted when `rewards` tokens are moved to account
	 *
	 * Note that `value` may be zero.
	 */
	event TriggeredCalculateHolderRewards(
		address indexed accountAddress,
		uint256 tokens,
		uint256 timestamp
	);

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param to: account address
	 */
	function calculatePendingHolderRewards(address to)
		external
		returns (
			uint256 pendingRewards,
			address holderAddress,
			address lpAddress
		);

	/*
	 * @dev Set 'contract address', called from constructor
	 * @param uTokenContract: utoken contract address
	 *
	 * Emits a {SetUTokensContract} event with '_contract' set to the utoken contract address.
	 *
	 */
	function setRewardEmissionContract(address rewardEmissionContract) external;

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetRewardEmissionContract(address indexed _contract);

	/**
	 * @dev get reward rate and value divisor
	 */
	function getUTokenAddress() external view returns (address uTokenAddress);
}
