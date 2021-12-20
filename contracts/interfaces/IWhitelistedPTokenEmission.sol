/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

pragma solidity >=0.7.0;

interface IWhitelistedPTokenEmission {
	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 */
	function getHolderData(address holderAddress)
		external
		view
		returns (
			address[] memory whitelistedAddresses,
			address[] memory sTokenAddresses,
			address[] memory uTokenAddresses,
			address lpTokenAddress
		);

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 */
	function areContractsWhitelisted(
		address sTokenAddress,
		address[] memory whitelistedAddresses
	) external view returns (bool[] memory areWhitelisted);

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 */
	function calculateAllHolderRewards(address holderAddress)
		external
		returns (
			uint256[] memory holderRewards,
			address[] memory sTokenAddresses,
			address[] memory uTokenAddresses,
			address lpTokenAddress
		);

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 */
	function calculateAllPendingHolderRewards(address holderAddress)
		external
		view
		returns (
			uint256[] memory holderRewards,
			address[] memory sTokenAddresses,
			address[] memory uTokenAddresses,
			address lpTokenAddress
		);

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 */
	function setWhitelistedAddress(
		address whitelistedAddress,
		address[] memory sTokenAddresses,
		address holderContractAddress,
		address lpContractAddress
	) external returns (bool success);

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
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

	event SetWhitelistedAddress(
		address indexed whitelistedAddress,
		address[] sTokenAddressesLocal,
		address indexed holderContractAddress,
		address indexed lpContractAddress,
		uint256 timestamp
	);

	event RemoveWhitelistedAddress(
		address indexed whitelistedAddress,
		address[] sTokenAddressesLocal,
		address indexed holderAddressLocal,
		uint256 indexed timestamp
	);

	event CalculateAllHolderRewards(
		address holderAddress,
		uint256[] holderRewards,
		uint256 timestamp
	);
}
