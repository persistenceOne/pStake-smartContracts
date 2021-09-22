// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/ISTokensV4.sol";
import "./interfaces/IWhitelistedEmissionV2.sol";

contract WhitelistedEmissionV6 is
	IWhitelistedEmissionV2,
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
	// holder address for a particular whitelisted contract
	mapping(address => address) public _whitelistedAddressHolder;
	// lp token address for a particular holder address
	mapping(address => address) public _holderLPToken;

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

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param holderAddress: contract address
	 */
	function getHolderData(address holderAddress)
		public
		view
		virtual
		override
		returns (
			address[] memory whitelistedAddresses,
			address[] memory sTokenAddresses,
			address[] memory uTokenAddresses,
			address lpTokenAddress
		)
	{
		whitelistedAddresses = _holderWhitelists[holderAddress];
		// for each whitelisted address, find the array of sTokenAddresses
		uint256 j;
		uint256 k;
		uint256 m;
		bool isMatchingIndex;
		address uTokenAddress;
		address[] memory sTokenAddressesLocal;

		lpTokenAddress = _holderLPToken[holderAddress];

		for (j = 0; j < _holderWhitelists[holderAddress].length; j = j.add(1)) {
			// get the sToken arrays of each whitelisted address
			sTokenAddressesLocal = _whitelistedSTokenAddresses[holderAddress][
				_holderWhitelists[holderAddress][j]
			];

			if (j == 0) {
				sTokenAddresses = _whitelistedSTokenAddresses[holderAddress][
					_holderWhitelists[holderAddress][j]
				];
				for (
					k = 0;
					k <
					_whitelistedSTokenAddresses[holderAddress][
						_holderWhitelists[holderAddress][j]
					].length;
					k = k.add(1)
				) {
					uTokenAddresses[k] = ISTokensV4(
						_whitelistedSTokenAddresses[holderAddress][
							_holderWhitelists[holderAddress][j]
						][k]
					).getUTokenAddress();
				}
				continue;
			}

			// add each element of sTokenAddressesLocal to sTokenAddress, making sure there are no duplicates
			for (
				k = 0;
				k <
				_whitelistedSTokenAddresses[holderAddress][
					_holderWhitelists[holderAddress][j]
				].length;
				k = k.add(1)
			) {
				isMatchingIndex = false;
				for (m = 0; m < sTokenAddresses.length; m = m.add(1)) {
					if (sTokenAddresses[m] == sTokenAddressesLocal[k]) {
						isMatchingIndex = true;
						break;
					}
				}
				// if a match is found, do nothing, else add the element
				if (!isMatchingIndex) {
					sTokenAddresses[
						sTokenAddresses.length
					] = sTokenAddressesLocal[k];
					uTokenAddress = ISTokensV4(sTokenAddressesLocal[k])
						.getUTokenAddress();
					uTokenAddresses[uTokenAddresses.length] = uTokenAddress;
				}
			}
		}
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

		// ADD TO _holderWhitelists AND _whitelistedSTokenAddresses AND _whitelistedAddressHolder AND _holderLPToken
		_whitelistedAddressHolder[whitelistedAddress] = holderContractAddress;
		_holderLPToken[holderContractAddress] = lpContractAddress;

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

		// emit event
		emit SetWhitelistedAddress(
			whitelistedAddress,
			_whitelistedSTokenAddresses[holderContractAddress][
				whitelistedAddress
			],
			holderContractAddress,
			lpContractAddress,
			block.timestamp
		);

		// ADD TO STOKENADDRESSES
		// check if sTokenAddress already exists
		/* address[] storage sTokenAddressesLocal = _whitelistedSTokenAddresses[
			holderContractAddress
		][whitelistedAddress]; */
		if (
			_whitelistedSTokenAddresses[holderContractAddress][
				whitelistedAddress
			].length == 0
		) {
			// check if all the sTokenAddresses provided are non zero
			for (uint256 i = 0; i < sTokenAddresses.length; i = i.add(1)) {
				require(sTokenAddresses[i] != address(0), "LP39");
				_whitelistedSTokenAddresses[holderContractAddress][
					whitelistedAddress
				].push(sTokenAddresses[i]);
			}
		}

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

		// REMOVE WHITELISTING FROM _holderWhitelists AND _whitelistedSTokenAddresses AND _whitelistedAddressHolder AND _holderLPToken

		// get the holder address from _whitelistedAddressHolder
		address holderAddressLocal = _whitelistedAddressHolder[
			whitelistedAddress
		];

		// emit event
		emit RemoveWhitelistedAddress(
			whitelistedAddress,
			_whitelistedSTokenAddresses[holderAddressLocal][whitelistedAddress],
			_whitelistedAddressHolder[whitelistedAddress],
			block.timestamp
		);

		// get the array of sTokenAddresses
		/* address[] memory sTokenAddressesLocal = _whitelistedSTokenAddresses[
			holderAddressLocal
		][whitelistedAddress]; */

		// for each SToken, call the remove whitelist function of that SToken
		uint256 j;
		for (
			j = 0;
			j <
			_whitelistedSTokenAddresses[holderAddressLocal][whitelistedAddress]
				.length;
			j = j.add(1)
		) {
			ISTokensV4(
				_whitelistedSTokenAddresses[holderAddressLocal][
					whitelistedAddress
				][j]
			).removeWhitelistedAddress(whitelistedAddress);
		}

		delete _whitelistedAddressHolder[whitelistedAddress];
		delete _whitelistedSTokenAddresses[holderAddressLocal][
			whitelistedAddress
		];

		/* address[] storage whitelistedAddressesLocal = _holderWhitelists[
			holderAddressLocal
		]; */

		// check if the whitelisted address exists is the _holderWhitelists array

		bool whitelistedAddressExists;
		for (
			j = 0;
			j < _holderWhitelists[holderAddressLocal].length;
			j = j.add(1)
		) {
			if (
				_holderWhitelists[holderAddressLocal][j] == whitelistedAddress
			) {
				whitelistedAddressExists = true;
				break;
			}
		}

		// if whitelisted contract exists in the_holderWhitelists array then
		// remove the whitelisted address from the array of _holderWhitelists
		if (whitelistedAddressExists) {
			if (j == _holderWhitelists[holderAddressLocal].length.sub(1)) {
				_holderWhitelists[holderAddressLocal].pop();
			} else {
				_holderWhitelists[holderAddressLocal][j] = _holderWhitelists[
					holderAddressLocal
				][_holderWhitelists[holderAddressLocal].length.sub(1)];
				_holderWhitelists[holderAddressLocal].pop();
			}
			// if all the whitelisted addresses have been removed, then delete the lpToken associated with the holder address
			if (_holderWhitelists[holderAddressLocal].length == 0) {
				delete _holderLPToken[holderAddressLocal];
			}
		}

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
