/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

pragma solidity >=0.7.0;

/**
 * @dev Interface of the IStakeLPCore.
 */
interface IStakeLPV2 {
	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function calculatePendingRewards(
		address holderAddress,
		address accountAddress
	)
		external
		view
		returns (
			uint256[] memory rewardAmounts,
			address[] memory rewardTokens,
			address[] memory sTokenAddresses,
			// address[] memory uTokenAddresses,
			address lpTokenAddress,
			uint256 updatedSupplyLPTimeshare,
			uint256 newSupplyLPTimeShare
		);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function calculateSyncedRewards(address holderAddress)
		external
		returns (
			uint256[] memory RewardAmounts,
			address[] memory RewardTokens,
			address[] memory sTokenAddresses,
			address lpTokenAddress
		);

	/**
	 * @dev adds liquidity
	 *
	 * Returns a uint256
	 */
	function addLiquidity(address holderAddress, uint256 amount) external;

	/**
	 * @dev remove liquidity
	 *
	 * Returns a uint256
	 */
	function removeLiquidity(address holderAddress, uint256 amount) external;

	/**
	 * @dev Set LiquidStaking smart contract.
	 */
	function setWhitelistedPTokenEmissionContract(
		address whitelistedPTokenEmissionContract
	) external;

	/**
	 * @dev Set LiquidStaking smart contract.
	 */
	function setWhitelistedRewardEmissionContract(
		address whitelistedRewardEmissionContract
	) external;

	/**
	 * @dev Triggers stopped state.
	 *
	 * Requirements:
	 *
	 * - The contract must not be paused.
	 */
	function pause() external;

	/**
	 * @dev Returns to normal state.
	 *
	 * Requirements:
	 *
	 * - The contract must be paused.
	 */
	function unpause() external;

	event AddLiquidity(
		address holderAddress,
		address accountAddress,
		uint256 tokens,
		uint256 timestamp
	);

	event RemoveLiquidity(
		address holderAddress,
		address accountAddress,
		uint256 tokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event CalculateRewardsStakeLP(
		address holderAddress,
		address lpToken,
		address accountAddress,
		uint256[] RewardAmounts,
		address[] RewardTokens,
		address[] sTokenAddresses,
		uint256 timestamp
	);

	event TriggeredCalculateSyncedRewards(
		address holderAddress,
		address accountAddress,
		uint256[] RewardAmounts,
		address[] RewardTokens,
		address[] sTokenAddresses,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetWhitelistedPTokenEmissionContract(address indexed _contract);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetWhitelistedRewardEmissionContract(address indexed _contract);
}
