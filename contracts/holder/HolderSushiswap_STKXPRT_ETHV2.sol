/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IHolder.sol";
import "../interfaces/ISTokensXPRT.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract HolderSushiswap_STKXPRT_ETHV2 is
	IHolder,
	Initializable,
	AccessControlUpgradeable,
	PausableUpgradeable
{
	using SafeERC20Upgradeable for IERC20Upgradeable;

	// constant pertaining to access roles
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

	// constant pertaining to access roles
	bytes32 public constant ACCOUNTANT_ROLE = keccak256("ACCOUNTANT_ROLE");

	// value divisor to make weight factor a fraction if need be
	uint256 public _valueDivisor;

	// variable pertaining to contract upgrades versioning
	uint256 public _version;

	/**
	 * @dev Constructor for initializing the Holder Sushiswap contract.
	 * @param pauserAdmin - address of the pauser admin.
	 * @param accountantAdmin - address of the accountant admin.
	 * @param valueDivisor - valueDivisor set to 10^9.
	 */
	function initialize(
		address pauserAdmin,
		address accountantAdmin,
		uint256 valueDivisor
	) public virtual initializer {
		__AccessControl_init();
		_setupRole(PAUSER_ROLE, pauserAdmin);
		_setupRole(ACCOUNTANT_ROLE, accountantAdmin);
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_valueDivisor = valueDivisor;
		_version = 1;
	}

	/**
	 * @dev get SToken reserve supply of the whitelisted contract
	 * argument names commented to suppress warnings
	 */
	function getSTokenSupply(address whitelistedAddress, address sTokenAddress)
		public
		view
		virtual
		override
		returns (uint256 sTokenSupply)
	{
		sTokenSupply = ISTokensXPRT(sTokenAddress).balanceOf(
			whitelistedAddress
		);
		return sTokenSupply;
	}

	/*
	 * @dev transfers token amount
	 * @param token: address
	 * @param to: account address
	 * @param value: amount
	 */
	function safeTransfer(
		address token,
		address to,
		uint256 value
	) public virtual override {
		require(hasRole(ACCOUNTANT_ROLE, _msgSender()), "HU3");
		// finally transfer the new LP Tokens to the user address
		IERC20Upgradeable(address(token)).safeTransfer(to, value);
	}

	/*
	 * @dev transfers token amount
	 * @param token: address
	 * @param from: account address
	 * @param to: account address
	 * @param value: amount
	 */
	function safeTransferFrom(
		address token,
		address from,
		address to,
		uint256 value
	) public virtual override {
		require(hasRole(ACCOUNTANT_ROLE, _msgSender()), "HU4");
		// finally transfer the new LP Tokens to the user address
		IERC20Upgradeable(address(token)).safeTransferFrom(from, to, value);
	}
}
