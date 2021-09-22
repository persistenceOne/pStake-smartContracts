// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

interface IWhitelistedEmissionV2 {
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

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param holderAddress: contract address
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
}
