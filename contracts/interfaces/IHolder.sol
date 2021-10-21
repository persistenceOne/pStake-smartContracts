// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

/**
 * @dev Interface of the IHolder.
 */
interface IHolder {
	/**
	 * @dev get SToken reserve supply of the whitelisted contract
	 * argument names commented to suppress warnings
	 */
	function getSTokenSupply(address whitelistedAddress, address sTokenAddress)
		external
		view
		returns (uint256 sTokenSupply);

	/**
	 * @dev transfers token amount
	*/
	function safeTransfer(
		address token,
		address to,
		uint256 value
	) external;

	/**
	 * @dev transfers token amount
	*/
	function safeTransferFrom(
		address token,
		address from,
		address to,
		uint256 value
	) external;
}
