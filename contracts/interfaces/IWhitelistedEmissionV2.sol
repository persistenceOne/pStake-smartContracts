// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

interface IWhitelistedEmissionV2 {
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
	 * @param whitelistedAddress: contract address
	 */
	function getWhitelistedSTokens(address whitelistedAddress)
		external
		view
		returns (address[] memory sTokenAddresses);

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
}
