/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the ISTokens.
 */
interface ISTokensXPRT is IERC20Upgradeable {
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
	 * @dev checks if given contract address is whitelisted
	 *
	 */
	function isContractWhitelisted(address whitelistedAddress)
		external view
		returns (bool result);

	/**
	 * @dev Emitted when a new whitelisted address is removed
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	function getWhitelistData(address whitelistedAddress)
		external view
		returns (
			address holderAddress,
			address lpAddress,
			address uTokenAddress,
			uint256 lastHolderRewardTimestamp
		);

	/**
	 * @dev Sets `reward rate`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	function setRewardRate(uint256 rewardRate) external returns (bool success);

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
		returns (
			uint256 rewards,
			address holderAddress,
			address lpTokenAddress
		);

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
	 * @dev Emitted when contract addresses are set
	 */
	event SetUTokensContract(address indexed _contract);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetLiquidStakingContract(address indexed _contract);

	/**
	 * @dev Emitted when a new whitelisted address is added
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	event SetWhitelistedAddress(
		address indexed whitelistedAddress,
		address indexed holderContractAddress,
		address indexed lpContractAddress,
		uint256 timestamp
	);

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param to: account address
	 */
	function calculatePendingHolderRewards(address to)
		external
		view
		returns (
			uint256 pendingRewards,
			address holderAddress,
			address lpAddress
		);

	/**
	 * @dev get uToken smart contract address
	 */
	function getUTokenAddress() external view returns (address uTokenAddress);

	/**
	 * @dev set's the whitelsited address
	  * @param whitelistedAddress: whitelisted address
	  * @param holderContractAddress: holder contract address
	  * @param lpContractAddress: lp contract address
	 *
	 * Emits a {TriggeredCalculateRewards} event.
	 */
	function setWhitelistedAddress(
		address whitelistedAddress,
		address holderContractAddress,
		address lpContractAddress
	) external returns (bool success);

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
	 * @dev Emitted when `rewards` tokens are moved to account
	 *
	 * Note that `value` may be zero.
	 */
	event TriggeredCalculateHolderRewards(
		address indexed accountAddress,
		address indexed sTokenAddress,
		uint256 indexed tokens,
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

	/*
	 * @dev remove 'whitelisted address', performed by admin only
	 * @param whitelistedAddress: contract address of the whitelisted party
	 * @param holderContractAddress: holder contract address of the corresponding whitelistedAddress
	 *
	 * Emits a {RemoveWhitelistedAddress} event
	 *
	 */
	function removeWhitelistedAddress(address whitelistedAddress)
		external
		returns (bool success);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	function setWhitelistedPTokenEmissionContract(
		address whitelistedPTokenEmissionContract
	) external;

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
	 * @dev Emitted when `rewards` tokens are moved to holder account
	 *
	 * Note that `value` may be zero.
	 */
	event CalculateHolderRewards(
		address indexed accountAddress,
		address indexed sTokenAddress,
		uint256 indexed tokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when reward rate is set
	 */
	event SetRewardRate(uint256 indexed rewardRate);

	/**
	 * @dev Emitted when a new whitelisted address is removed
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	event RemoveWhitelistedAddress(
		address indexed whitelistedAddress,
		address indexed holderContractAddress,
		address indexed lpContractAddress,
		uint256 lastHolderRewardTimestamp,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetWhitelistedPTokenEmissionContract(address indexed _contract);
}
