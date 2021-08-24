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
	function getSTokenSupply(address to)
		external
		view
		returns (uint256 sTokenSupply);

	/**
	 * @dev Set UTokens smart contract.
	 *
	 * Emits a {SetSTokensContract} event.
	 */
	function setSTokensContract(address utokenContract) external;

	/**
	 * @dev Set UTokens smart contract.
	 *
	 * Emits a {SetSTokensContract} event.
	 */
	function setStakeLPContract(address stakeLPContract) external;

	/**
	 * @dev Set UTokens smart contract.
	 *
	 * Emits a {SetSTokensContract} event.
	 */
	function safeTransfer(
		address token,
		address to,
		uint256 value
	) external;

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetSTokensContract(address indexed _contract);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetStakeLPContract(address indexed _contract);
}
