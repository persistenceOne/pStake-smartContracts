// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

/**
 * @dev Interface of the IStakeLPCore.
 */
interface IStakeLPCore {
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
	 * @dev adds liquidity
	 *
	 * Returns a uint256
	 */
	function addLiquidity(address lpToken, uint256 amount)
		external
		returns (bool success);

	/**
	 * @dev remove liquidity
	 *
	 * Returns a uint256
	 */
	function removeLiquidity(address lpToken, uint256 amount)
		external
		returns (bool success);

	/**
	 * @dev remove liquidity
	 *
	 * Returns a uint256
	 */
	function calculateRewards(address whitelistedAddress)
		external
		returns (
			uint256 reward,
			uint256[] memory otherRewardAmounts,
			address[] memory otherRewardTokens
		);

	/**
	 * @dev remove liquidity
	 *
	 * Returns a uint256
	 */
	function calculateSyncedRewards(address whitelistedAddress)
		external
		returns (
			uint256 reward,
			uint256 holderReward,
			uint256[] memory otherRewardAmounts,
			address[] memory otherRewardTokens
		);

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
	 * @dev Set LiquidStaking smart contract.
	 */
	// function setLiquidStakingContract(address liquidStakingContract) external;

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
	event CalculateRewards(
		address indexed holderAddress,
		address indexed lpToken,
		address indexed to,
		uint256 reward,
		uint256[] otherRewardAmounts,
		address[] otherRewardTokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when a new whitelisted address is added
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	event TriggeredCalculateRewards(
		address indexed holderAddress,
		address indexed lpToken,
		address indexed to,
		uint256 reward,
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
		address indexed to,
		uint256 reward,
		uint256 holderReward,
		uint256[] otherRewardAmounts,
		address[] otherRewardTokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event AddLiquidity(address lpToken, uint256 amount, uint256 timestamp);

	/**
	 * @dev Emitted
	 */
	event RemoveLiquidity(address lpToken, uint256 amount, uint256 timestamp);

	/**
	 * @dev Emitted
	 */
	event SetHolderAddressForRewards(
		address holderContractAddress,
		address[] rewardTokenContractAddress,
		uint256[] rewardTokenEmissions,
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
		uint256[] rewardTokenEmissions,
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
}
