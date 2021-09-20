// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/ISTokensV4.sol";
import "./interfaces/IWhitelistedEmission.sol";

contract WhitelistedEmission is
	IWhitelistedEmission,
	PausableUpgradeable,
	AccessControlUpgradeable
{
	using SafeMathUpgradeable for uint256;
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

	// constants defining access control ROLES
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
	// variable pertaining to contract upgrades versioning
	uint256 public _version;

	// list of whitelisted addresses for a particular holder contract
	mapping(address => address[]) public _holderWhitelists;
	// list of SToken addresses for a particular holder contract, for a particular whitelisted address
	mapping(address => mapping(address => address[]))
		public _whitelistedSTokenAddresses;
	// holder addresses for a particular whitelisted contract
	mapping(address => address) public _whitelistedAddressHolder;

	/**
	 * @dev Constructor for initializing the SToken contract.
	 * @param pauserAddress - address of the pauser admin.
	 */
	function initialize(address pauserAddress) public virtual initializer {
		__AccessControl_init();
		__Pausable_init();
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(PAUSER_ROLE, pauserAddress);
		_version = 1;
	}

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
	) public virtual override returns (bool success) {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "RE8");
		// lpTokenERC20ContractAddress or sTokenReserveContractAddress can be address(0) but not whitelistedAddress
		// have set holderContract also as non-zero, can allow lpContractAddress to be zero for control
		require(
			whitelistedAddress != address(0) &&
				holderContractAddress != address(0) &&
				sTokenAddresses.length != 0,
			"LP38"
		);

		// SET WHITELISTING IN STOKEN CONTRACTS
		uint256 j;
		// for each sTokenAddress, set the whiteliste data
		for (j = 0; j < sTokenAddresses.length; j = j.add(1)) {
			ISTokensV4(sTokenAddresses[j]).setWhitelistedAddress(
				whitelistedAddress,
				holderContractAddress,
				lpContractAddress
			);
		}

		// --------------------------------------------------
		// ADD TO _holderWhitelists AND _whitelistedSTokenAddresses AND _whitelistedAddressHolder
		_whitelistedAddressHolder[whitelistedAddress] = holderContractAddress;

		bool whitelistedAddressExists;
		for (
			j = 0;
			j < _holderWhitelists[holderContractAddress].length;
			j = j.add(1)
		) {
			if (
				_holderWhitelists[holderContractAddress][j] ==
				whitelistedAddress
			) {
				whitelistedAddressExists = true;
				break;
			}
		}

		// if whitelisted contract doesnt already exist then include it in the array
		if (!whitelistedAddressExists) {
			// add the whitelistedAddress to the _holderWhitelists array
			_holderWhitelists[holderContractAddress].push(whitelistedAddress);
		}

		// --------------------------------------------------

		// ADD TO STOKENADDRESSES
		// check if sTokenAddress already exists
		address[] storage sTokenAddressesLocal = _whitelistedSTokenAddresses[
			holderContractAddress
		][whitelistedAddress];
		if (sTokenAddressesLocal.length == 0) {
			// check if all the sTokenAddresses provided are non zero
			for (uint256 i = 0; i < sTokenAddresses.length; i = i.add(1)) {
				require(sTokenAddresses[i] != address(0), "LP39");
				sTokenAddressesLocal.push(sTokenAddresses[i]);
			}
		}

		emit SetWhitelistedAddress(
			whitelistedAddress,
			sTokenAddressesLocal,
			holderContractAddress,
			lpContractAddress,
			block.timestamp
		);
		success = true;
		return success;
	}

	/*
	 * @dev remove 'whitelisted address', performed by admin only
	 * @param whitelistedAddress: contract address of the whitelisted party
	 * @param holderContractAddress: holder contract address of the corresponding whitelistedAddress
	 *
	 * Emits a {RemoveWhitelistedAddress} event
	 *
	 */
	function removeWhitelistedAddress(address whitelistedAddress)
		public
		virtual
		override
		returns (bool success)
	{
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP40");
		require(whitelistedAddress != address(0), "LP41");

		// REMOVE WHITELISTING IN STOKEN CONTRACTS
		// get the array of sTokenAddresses
		address holderAddressLocal = _whitelistedAddressHolder[
			whitelistedAddress
		];
		// get the array of sTokenAddresses
		address[] memory sTokenAddressesLocal = _whitelistedSTokenAddresses[
			holderAddressLocal
		][whitelistedAddress];
		uint256 j;
		for (j = 0; j < sTokenAddressesLocal.length; j = j.add(1)) {
			ISTokensV4(sTokenAddressesLocal[j]).removeWhitelistedAddress(
				whitelistedAddress
			);
		}

		// REMOVE WHITELISTING FROM _holderWhitelists AND _whitelistedSTokenAddresses AND _whitelistedAddressHolder
		delete _whitelistedAddressHolder[whitelistedAddress];
		delete _whitelistedSTokenAddresses[holderAddressLocal][
			whitelistedAddress
		];

		address[] storage whitelistedAddressesLocal = _holderWhitelists[
			holderAddressLocal
		];
		bool whitelistedAddressExists;
		for (j = 0; j < whitelistedAddressesLocal.length; j = j.add(1)) {
			if (whitelistedAddressesLocal[j] == whitelistedAddress) {
				whitelistedAddressExists = true;
				break;
			}
		}

		// if whitelisted contract doesnt already exist then include it in the array
		if (whitelistedAddressExists) {
			// add the whitelistedAddress to the _holderWhitelists array
			if (j == whitelistedAddressesLocal.length.sub(1)) {
				whitelistedAddressesLocal.pop();
			} else {
				whitelistedAddressesLocal[j] = whitelistedAddressesLocal[
					whitelistedAddressesLocal.length.sub(1)
				];
				whitelistedAddressesLocal.pop();
			}
		}

		// emit event and return
		emit RemoveWhitelistedAddress(
			whitelistedAddress,
			sTokenAddressesLocal,
			holderAddressLocal,
			block.timestamp
		);
		success = true;
		return success;
	}

	/**
	 * @dev Triggers stopped state.
	 *
	 * Requirements:
	 *
	 * - The contract must not be paused.
	 */
	function pause() public virtual override returns (bool success) {
		require(hasRole(PAUSER_ROLE, _msgSender()), "ST14");
		_pause();
		return true;
	}

	/**
	 * @dev Returns to normal state.
	 *
	 * Requirements:
	 *
	 * - The contract must be paused.
	 */
	function unpause() public virtual override returns (bool success) {
		require(hasRole(PAUSER_ROLE, _msgSender()), "ST15");
		_unpause();
		return true;
	}
}
