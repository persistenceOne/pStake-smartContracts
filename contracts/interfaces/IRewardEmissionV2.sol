// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

interface IRewardEmissionV2 {
	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param whitelistedAddress: whitelisted contract address
	 * @param sTokenAddress: stkToken contract address
	 */
	function isContractWhitelisted(
		address whitelistedAddress,
		address sTokenAddress
	) external view returns (bool result);

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param whitelistedAddress: contract address
	 */
	function getwhitelistedData(address whitelistedAddress)
		external
		view
		returns (
			address holderAddress,
			address lpAddress,
			address[] memory stkContractAddresses,
			address[] memory pContractAddresses,
			uint256 lastHolderRewardTimestamp
		);

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param holderAddress: contract address
	 */
	function getHolderData(address holderAddress)
		external
		view
		returns (
			address[] memory holderWhitelists,
			address lpContractAddress,
			address[] memory stkContractAddresses,
			address[] memory pContractAddresses
		);

	/*
	 * @dev set reward rate called by admin
	 * @param rewardRate: reward rate
	 * Requirements:
	 * - `rate` cannot be less than or equal to zero.
	 */
	function setLastHolderRewardTimestamp(
		address whitelistedAddress,
		uint256 rewardTimestamp
	) external returns (bool success);

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param whitelistedAddress: whitelisted contract address
	 * @param sTokenAddress: stkToken contract address
	 */
	function getPendingHolderRewardsData(
		address whitelistedAddress,
		address sTokenAddress
	)
		external
		view
		returns (
			uint256 sTokenSupply,
			uint256 lastHolderRewardTimestamp,
			address holderAddress,
			address lpAddress
		);

	/*
	 * @dev Set 'whitelisted address', performed by admin only
	 * @param whitelistedAddress: contract address of the whitelisted party
	 *
	 * Emits a {setWhitelistedAddress} event
	 *
	 */
	function setWhitelistedAddress(
		address whitelistedAddress,
		address[] memory sTokenAddresses,
		address holderContractAddress,
		address lpContractAddress
	) external returns (bool success);

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
	 * @dev Returns to normal state.
	 *
	 * Requirements:
	 *
	 * - The contract must be paused.
	 */
	event SetLastHolderRewardTimestamp(
		address indexed whitelistedAddress,
		uint256 rewardTimestamp
	);

	/**
	 * @dev Returns to normal state.
	 *
	 * Requirements:
	 *
	 * - The contract must be paused.
	 */
	event SetWhitelistedAddress(
		address whitelistedAddress,
		address[] sTokenAddressses,
		address holderContractAddress,
		address lpContractAddress,
		uint256 timestamp
	);

	/**
	 * @dev Returns to normal state.
	 *
	 * Requirements:
	 *
	 * - The contract must be paused.
	 */
	event RemoveWhitelistedAddress(
		address whitelistedAddress,
		address[] stkContractAddresses,
		address holderContractAddressLocal,
		address lpContractAddressLocal,
		uint256 lastHolderRewardTimestamp,
		uint256 timestamp
	);
}
