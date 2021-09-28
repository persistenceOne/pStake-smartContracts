// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "../interfaces/IHolderV2.sol";
import "../interfaces/ISTokensV2.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../libraries/TransferHelper.sol";

contract HolderSushiswapStkATOMEth is
	IHolderV2,
	Initializable,
	AccessControlUpgradeable,
	PausableUpgradeable
{
	// constant pertaining to access roles
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

	// safeTransfer & safeTransferFrom will be called by stakeLPCore contract
	address private _stakeLPContract;

	// value divisor to make weight factor a fraction if need be
	uint256 private _valueDivisor;

	// variable pertaining to contract upgrades versioning
	uint256 private _version;

	/**
	 * @dev Constructor for initializing the Holder Uniswap contract.
	 * @param stakeLPContract - address of the StakeLPCore contract.
	 */
	function initialize(
		address pauserAdmin,
		address stakeLPContract,
		uint256 valueDivisor
	) public virtual initializer {
		__AccessControl_init();
		_setupRole(PAUSER_ROLE, pauserAdmin);
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_stakeLPContract = stakeLPContract;
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
		sTokenSupply = ISTokensV2(sTokenAddress).balanceOf(whitelistedAddress);
		return sTokenSupply;
	}

	/*
	 * @dev Set 'contract address', called from constructor
	 * @param liquidStakingContract: liquidStaking contract address
	 *
	 * Emits a {SetLiquidStakingContract} event with '_contract' set to the liquidStaking contract address.
	 *
	 */
	function setStakeLPContract(address stakeLPContract)
		public
		virtual
		override
	{
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "HU2");
		_stakeLPContract = stakeLPContract;
		emit SetStakeLPContract(stakeLPContract);
	}

	function safeTransfer(
		address token,
		address to,
		uint256 value
	) public virtual override {
		require(_msgSender() == _stakeLPContract, "HU3");

		// finally transfer the new LP Tokens to the user address
		TransferHelper.safeTransfer(token, to, value);
	}

	function safeTransferFrom(
		address token,
		address from,
		address to,
		uint256 value
	) public virtual override {
		require(_msgSender() == _stakeLPContract, "HU4");

		// finally transfer the new LP Tokens to the user address
		TransferHelper.safeTransferFrom(token, from, to, value);
	}
}
