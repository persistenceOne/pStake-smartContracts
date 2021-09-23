// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

/**
 * @dev Interface of the IStakeLPCore.
 */
interface IStakeLPCoreV3 {
	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function addRewards(
		address holderContractAddress,
		address rewardTokenContractAddress,
		address rewardSender,
		uint256 rewardAmount
	) external returns (bool success);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function setRewardEmission(
		address holderContractAddress,
		address rewardTokenContractAddress,
		uint256 rewardTokenEmission
	) external returns (bool success);

	/**
	 * @dev adds liquidity
	 *
	 * Returns a uint256
	 */
	function addLiquidity(address holderAddress, uint256 amount)
		external
		returns (bool success);

	/**
	 * @dev remove liquidity
	 *
	 * Returns a uint256
	 */
	function removeLiquidity(address holderAddress, uint256 amount)
		external
		returns (bool success);

	/**
	 * @dev Set UTokens smart contract.
	 *
	 *
	 * Emits a {SetContract} event.
	 */

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param holderAddress: holder contract address
	 */
	function isHolderContractWhitelisted(address holderAddress)
		external
		view
		returns (bool result);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function setHolderAddressesForRewards(
		address[] memory holderContractAddresses,
		address[] memory rewardTokenContractAddresses
	) external returns (bool success);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function removeHolderAddressesForRewards(
		address[] memory holderContractAddresses
	) external returns (bool success);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function removeTokenContractsForRewards(
		address[] memory holderContractAddresses,
		address[] memory rewardTokenContractAddresses
	) external returns (bool success);

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
	 * @dev Set LiquidStaking smart contract.
	 */
	function setWhitelistedEmissionContract(address whitelistedEmission)
		external;

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
			address[] memory uTokenAddresses,
			address lpTokenAddress,
			uint256 updatedSupplyLPTimeshare
		);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function calculateSyncedRewards(address holderAddress)
		external
		returns (
			uint256[] memory RewardAmounts,
			address[] memory RewardTokens,
			address[] memory uTokenAddresses,
			address lpTokenAddress
		);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event CalculateRewardsAndLiquidity(
		address holderAddress,
		address lpToken,
		uint256 amount,
		address to,
		uint256 liquidity,
		uint256 reward
	);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetUTokensContract(address indexed _contract);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetSTokensContract(address indexed _contract);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetPSTAKEContract(address indexed _contract);

	/**
	 * @dev Emitted when a new whitelisted address is added
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	event TriggeredCalculateSyncedRewardsV2(
		address holderAddress,
		address lpTokenAddress,
		address[] uTokenAddresses,
		address accountAddress,
		uint256[] RewardAmounts,
		address[] RewardTokens,
		uint256 holderReward,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event AddLiquidity(address lpToken, uint256 tokens, uint256 timestamp);

	/**
	 * @dev Emitted
	 */
	event RemoveLiquidity(address lpToken, uint256 tokens, uint256 timestamp);

	/**
	 * @dev Emitted
	 */
	event SetHolderAddressForRewards(
		address holderContractAddress,
		address[] rewardTokenContractAddress,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event RemoveHolderAddressForRewards(
		address holderContractAddress,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event SetHolderAddressesForRewards(
		address[] holderContractAddresses,
		address[] rewardTokenContractAddress,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event RemoveHolderAddressesForRewards(
		address[] holderContractAddresses,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event RemoveTokenContractForRewards(
		address holderContractAddress,
		address[] rewardTokenContractAddress,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event RemoveTokenContractsForRewards(
		address[] holderContractAddresses,
		address[] rewardTokenContractAddress,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event AddRewards(
		address holderContractAddress,
		address rewardTokenContractAddress,
		address rewardSender,
		uint256 tokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event SetRewardEmission(
		address holderContractAddress,
		address rewardTokenContractAddress,
		uint256 rewardTokenEmission,
		uint256 valueDivisor,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event AddLiquidity(
		address indexed whitelistedAddress,
		address indexed sTokenAddress,
		address indexed accountAddress,
		uint256 tokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event RemoveLiquidity(
		address indexed whitelistedAddress,
		address indexed sTokenAddress,
		address indexed accountAddress,
		uint256 tokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event AddRewardsV2(
		address holderContractAddress,
		address rewardTokenContractAddress,
		address rewardSender,
		uint256 tokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetWhitelistedEmissionContract(address indexed _contract);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event CalculateRewardsStakeLP(
		address holderAddress,
		address lpToken,
		address accountAddress,
		uint256[] RewardAmounts,
		address[] RewardTokens,
		address[] uTokenAddresses,
		uint256 timestamp
	);

	event AddLiquidityV3(
		address holderAddress,
		address accountAddress,
		uint256 tokens,
		uint256 timestamp
	);

	event RemoveLiquidityV3(
		address holderAddress,
		address accountAddress,
		uint256 tokens,
		uint256 timestamp
	);

	event TriggeredCalculateSyncedRewards(
		address holderAddress,
		address accountAddress,
		uint256[] RewardAmounts,
		address[] RewardTokens,
		address[] uTokenAddresses,
		uint256 holderReward,
		uint256 timestamp
	);

	event TriggeredCalculateSyncedRewardsV3(
		address holderAddress,
		address accountAddress,
		uint256[] RewardAmounts,
		address[] RewardTokens,
		address[] uTokenAddresses,
		uint256 holderReward,
		uint256 timestamp
	);
}
