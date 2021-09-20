// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

/**
 * @dev Interface of the IStakeLPCore.
 */
interface IStakeLPCoreV5 {
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

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param to: user address
	 * @param liquidityWeightFactor: coming as an argument for further calculations
	 * @param rewardWeightFactor: coming as an argument for further calculations
	 * @param valueDivisor: coming as an argument for further calculations
	 */
	function calculatePendingRewards(
		address holderAddress,
		address lpToken,
		address to
	)
		external
		view
		returns (
			uint256 reward,
			uint256[] memory otherRewardAmounts,
			address[] memory otherRewardTokens,
			uint256[] memory updatedRewardPoolBalances,
			uint256 updatedSupplyLPTimeshare
		);

	/**
	 * @dev Mints `amount` tokens to the caller's address `to`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	// function mint(address to, uint256 tokens) external returns (bool);

	/**
	 * @dev Burns `amount` tokens to the caller's address `from`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	//function burn(address from, uint256 tokens) external returns (bool);

	/**
	 * @dev remove liquidity
	 *
	 * Returns a uint256
	 */
	/* function calculateRewards(address whitelistedAddress, address sTokenAddress)
		external
		returns (
			uint256 reward,
			uint256[] memory otherRewardAmounts,
			address[] memory otherRewardTokens
		); */

	/**
	 * @dev remove liquidity
	 *
	 * Returns a uint256
	 */
	function calculateSyncedRewards(
		address whitelistedAddress,
		address sTokenAddress
	)
		external
		returns (
			uint256 reward,
			uint256 holderReward,
			uint256[] memory otherRewardAmounts,
			address[] memory otherRewardTokens
		);

	/**
	 * @dev adds liquidity
	 *
	 * Returns a uint256
	 */
	function addLiquidity(
		address lpToken,
		address sTokenAddress,
		uint256 amount
	) external returns (bool success);

	/**
	 * @dev remove liquidity
	 *
	 * Returns a uint256
	 */
	function removeLiquidity(
		address lpToken,
		address sTokenAddress,
		uint256 amount
	) external returns (bool success);

	/**
	 * @dev Set UTokens smart contract.
	 *
	 *
	 * Emits a {SetContract} event.
	 */
	function setUTokensContract(address uAddress) external;

	/**
	 * @dev Set UTokens smart contract.
	 *
	 *
	 * Emits a {SetContract} event.
	 */
	function setSTokensContract(address sAddress) external;

	/**
	 * @dev Set UTokens smart contract.
	 *
	 *
	 * Emits a {SetContract} event.
	 */
	function setPSTAKEContract(address sAddress) external;

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
	// function setLiquidStakingContract(address liquidStakingContract) external;

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
	event CalculateRewardsStakeLP(
		address indexed holderAddress,
		address indexed lpToken,
		address indexed to,
		uint256 tokens,
		uint256[] otherRewardAmounts,
		address[] otherRewardTokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when a new whitelisted address is added
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	event TriggeredCalculateRewardsStakeLP(
		address indexed holderAddress,
		address indexed lpToken,
		address uTokenAddress,
		address indexed to,
		uint256 tokens,
		uint256[] otherRewardAmounts,
		address[] otherRewardTokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when a new whitelisted address is added
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	event TriggeredCalculateSyncedRewards(
		address indexed holderAddress,
		address indexed lpToken,
		address uTokenAddress,
		address indexed to,
		uint256 tokens,
		uint256 holderReward,
		uint256[] otherRewardAmounts,
		address[] otherRewardTokens,
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
	event AddLiquidityV2(
		address indexed whitelistedAddress,
		address indexed sTokenAddress,
		address indexed msgSender,
		uint256 tokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event RemoveLiquidityV2(
		address indexed whitelistedAddress,
		address indexed sTokenAddress,
		address indexed msgSender,
		uint256 tokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when a new whitelisted address is added
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	event TriggeredCalculateSyncedRewardsV2(
		address indexed holderAddress,
		address indexed lpToken,
		address uTokenAddress,
		address indexed to,
		uint256 tokens,
		uint256 holderReward,
		uint256[] otherRewardAmounts,
		address[] otherRewardTokens,
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

	function setWhitelistedAddress(
		address whitelistedAddress,
		address[] memory sTokenAddresses,
		address holderContractAddress,
		address lpContractAddress
	) external returns (bool success);

	event SetWhitelistedAddress(
		address whitelistedAddress,
		address[] sTokenAddressesLocal,
		address holderContractAddress,
		address lpContractAddress,
		uint256 timestamp
	);

	function removeWhitelistedAddress(address whitelistedAddress)
		external
		returns (bool success);

	event RemoveWhitelistedAddress(
		address whitelistedAddress,
		address[] sTokenAddressesLocal,
		address holderAddressLocal,
		uint256 timestamp
	);
}
