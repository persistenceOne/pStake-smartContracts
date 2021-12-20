/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

pragma solidity >=0.7.0;

/**
 * @dev Interface of the IHolder.
 */
interface IHolderV2 {
	/**
	 * @dev get SToken reserve supply of the whitelisted contract
	 * argument names commented to suppress warnings
	 */
	function getSTokenSupply(address whitelistedAddress, address sTokenAddress)
		external
		view
		returns (uint256 sTokenSupply);

	/**
	 * @dev Set UTokens smart contract.
	 *
	 * Emits a {SetContract} event.
	 */
	function safeTransfer(
		address token,
		address to,
		uint256 value
	) external;

	/**
	 * @dev Set UTokens smart contract.
	 *
	 * Emits a {SetContract} event.
	 */
	function safeTransferFrom(
		address token,
		address from,
		address to,
		uint256 value
	) external;
}
