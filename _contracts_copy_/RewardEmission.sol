// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IHolderV2.sol";
import "./interfaces/ISTokensV3.sol";
import "./interfaces/IRewardEmission.sol";

contract RewardEmission is
	IRewardEmission,
	PausableUpgradeable,
	AccessControlUpgradeable
{
	using SafeMathUpgradeable for uint256;
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

	// constants defining access control ROLES
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

	// variables pertaining to holder logic for whitelisted addresses & StakeLP
	// deposit contract address for STokens in a DeFi product
	EnumerableSetUpgradeable.AddressSet private _whitelistedAddresses;
	// Holder contract address for this whitelisted contract. Many can point to one Holder contract
	mapping(address => address) public _holderContractAddress;
	// LP Token contract address which might be different from whitelisted contract, for a whitelisted contract
	mapping(address => address) public _lpContractAddress;
	// array of stkToken contract addresses associated with a whitelisted contract, for scenarios
	// where both the pair of tokens happen to be stkTokens
	mapping(address => address[]) public _stkContractAddresses;
	// last timestamp when the holder reward calculation was performed for updating reward pool,
	// for a whitelisted contract
	mapping(address => uint256) public _lastHolderRewardTimestamp;
	// list of whitelisted addresses for a particular holder contract
	mapping(address => address[]) _holderWhitelists;
	// variable pertaining to contract upgrades versioning
	uint256 public _version;

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
	 * @param whitelistedAddress: whitelisted contract address
	 * @param sTokenAddress: stkToken contract address
	 */
	function isContractWhitelisted(
		address whitelistedAddress,
		address sTokenAddress
	) public view virtual override returns (bool result) {
		result = _whitelistedAddresses.contains(whitelistedAddress);
		address[] memory stkContractAddresses = _stkContractAddresses[
			whitelistedAddress
		];
		uint256 stkContractAddressesLength = stkContractAddresses.length;
		bool result2;
		for (uint256 i = 0; i < stkContractAddressesLength; i = i.add(1)) {
			if (stkContractAddresses[i] == sTokenAddress) {
				result2 = true;
				break;
			}
		}
		result = result && result2;
		return result;
	}

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param whitelistedAddress: contract address
	 */
	function getwhitelistedData(address whitelistedAddress)
		public
		view
		virtual
		override
		returns (
			address holderAddress,
			address lpAddress,
			address[] memory stkContractAddresses,
			address[] memory pContractAddresses,
			uint256 lastHolderRewardTimestamp
		)
	{
		// Get the time in number of blocks
		holderAddress = _holderContractAddress[whitelistedAddress];
		lpAddress = _lpContractAddress[whitelistedAddress];
		stkContractAddresses = _stkContractAddresses[whitelistedAddress];
		lastHolderRewardTimestamp = _lastHolderRewardTimestamp[
			whitelistedAddress
		];
		// allocate pContractAddresses from the corresponding stkContractAddresses
		pContractAddresses = new address[](stkContractAddresses.length);
		for (uint256 j = 0; j < stkContractAddresses.length; j = j.add(1)) {
			pContractAddresses[j] = ISTokensV3(stkContractAddresses[j])
				.getUTokenAddress();
		}
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
			address[] memory holderWhitelists,
			address lpContractAddress,
			address[] memory stkContractAddresses,
			address[] memory pContractAddresses
		)
	{
		holderWhitelists = _holderWhitelists[holderAddress];
		uint256 holderWhitelistsLength = holderWhitelists.length;
		// if there are no whitelisted addresses associated with the holder contract then return
		if (holderWhitelistsLength == 0) {
			return (
				holderWhitelists,
				lpContractAddress,
				stkContractAddresses,
				pContractAddresses
			);
		}
		address whitelistedContract;
		uint256 index;
		uint256 size;
		for (uint256 i = 0; i < holderWhitelistsLength; i = i.add(1)) {
			whitelistedContract = holderWhitelists[i];
			if (_lpContractAddress[whitelistedContract] != address(0)) {
				// allocate the lpContract address, which is supposed to be the same for all whitelisted addresses
				// associated with the holder contract
				lpContractAddress = _lpContractAddress[whitelistedContract];
			}
			// get the list of all stkToken addresses from the various whitelisted addresses
			// associated with the holder contract. some whitelisted addresses may have less while
			// other may have more stkToken addresses
			if (_stkContractAddresses[whitelistedContract].length > size) {
				index = i;
				size = _stkContractAddresses[whitelistedContract].length;
			}
		}

		stkContractAddresses = new address[](size);
		whitelistedContract = holderWhitelists[index];

		// allocate stkContractAddresses and then  pContractAddresses from the corresponding stkContractAddresses
		pContractAddresses = new address[](stkContractAddresses.length);

		for (uint256 j = 0; j < stkContractAddresses.length; j = j.add(1)) {
			stkContractAddresses[j] = _stkContractAddresses[
				whitelistedContract
			][j];
			pContractAddresses[j] = ISTokensV3(stkContractAddresses[j])
				.getUTokenAddress();
		}
	}

	/*
	 * @dev set reward rate called by admin
	 * @param rewardRate: reward rate
	 * Requirements:
	 * - `rate` cannot be less than or equal to zero.
	 */
	function setLastHolderRewardTimestamp(
		address whitelistedAddress,
		uint256 rewardTimestamp
	) public virtual override returns (bool success) {
		// check if msgSender is an STokenContract address which is part of whitelistedAddress
		bool isSTokenValid = isContractWhitelisted(
			whitelistedAddress,
			_msgSender()
		);
		require(isSTokenValid, "RE1");
		_lastHolderRewardTimestamp[whitelistedAddress] = rewardTimestamp;
		emit SetLastHolderRewardTimestamp(whitelistedAddress, rewardTimestamp);
		success = true;
	}

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param whitelistedAddress: whitelisted contract address
	 * @param sTokenAddress: stkToken contract address
	 */
	function getPendingHolderRewardsData(
		address whitelistedAddress,
		address sTokenAddress
	)
		public
		view
		virtual
		override
		returns (
			uint256 sTokenSupply,
			uint256 lastHolderRewardTimestamp,
			address holderAddress,
			address lpAddress
		)
	{
		// holderContract and lpContract (lp token contract) need to be validated together because
		// it might not be practical to setup holder to collect reward pool but not StakeLP to distribute reward
		// since the reward distribution calculation starts the minute reward pool is created
		bool isToContractWhitelisted = isContractWhitelisted(
			whitelistedAddress,
			sTokenAddress
		);
		if (!isToContractWhitelisted) {
			return (
				sTokenSupply,
				lastHolderRewardTimestamp,
				holderAddress,
				lpAddress
			);
		}

		(
			address holderAddressLocal,
			address lpAddressLocal,
			address[] memory stkContractAddresses,
			,
			uint256 lastHolderRewardTimestampLocal
		) = getwhitelistedData(whitelistedAddress);

		bool isSTokenContractValid = false;
		// check if the stkContractAddress matches the one returned by array
		for (uint256 i = 0; i < stkContractAddresses.length; i = i.add(1)) {
			if (stkContractAddresses[i] == sTokenAddress) {
				isSTokenContractValid = true;
				break;
			}
		}

		// check require conditions for null values
		if (
			isSTokenContractValid &&
			holderAddress != address(0) &&
			lpAddress != address(0)
		) {
			sTokenSupply = IHolderV2(holderAddress).getSTokenSupply(
				whitelistedAddress
			);
			holderAddress = holderAddressLocal;
			lpAddress = lpAddressLocal;
			lastHolderRewardTimestamp = lastHolderRewardTimestampLocal;
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
		require(
			whitelistedAddress != address(0) && sTokenAddresses.length != 0,
			"RE9"
		);

		// add the whitelistedAddress if it isn't already available
		if (!_whitelistedAddresses.contains(whitelistedAddress))
			_whitelistedAddresses.add(whitelistedAddress);

		// add the holder and lp contract addresses corresponding to the whitelistedAddress
		_holderContractAddress[whitelistedAddress] = holderContractAddress;
		_lpContractAddress[whitelistedAddress] = lpContractAddress;

		// ADD TO, OR REMOVE FROM _holderWhitelists
		// check if whitelistedAddress already exists in _holderWhitelists
		bool whitelistedAddressExists;
		uint256 j;
		uint256 holderWhitelistsLength = _holderWhitelists[
			holderContractAddress
		].length;
		for (j = 0; j < holderWhitelistsLength; j = j.add(1)) {
			if (
				_holderWhitelists[holderContractAddress][j] ==
				whitelistedAddress
			) {
				whitelistedAddressExists = true;
				break;
			}
		}

		// if holderAddress is address(0), then remove the whitelistedAddress from the array
		// else add the whitelistedAddress to the array
		if (holderContractAddress == address(0) && whitelistedAddressExists) {
			// remove whitelistedAddress from the _holderWhitelists
			(address holderAddressLocal, , , , ) = getwhitelistedData(
				whitelistedAddress
			);
			// if the index of whitelistedAddress is the last one then just pop array
			if (j == holderWhitelistsLength.sub(1)) {
				_holderWhitelists[holderAddressLocal].pop();
			} else {
				// else replace the value in the index location with the value in the last index then pop array
				_holderWhitelists[holderAddressLocal][j] = _holderWhitelists[
					holderAddressLocal
				][holderWhitelistsLength.sub(1)];
				_holderWhitelists[holderAddressLocal].pop();
			}
		}

		// if sTokenAddress doesnt already exist then include it in the array
		if (holderContractAddress != address(0) && !whitelistedAddressExists) {
			// add the whitelistedAddress to the _holderWhitelists array
			_holderWhitelists[holderContractAddress].push(whitelistedAddress);
		}

		// ADD TO _stkContractAddresses
		// check if sTokenAddress already exists
		if (_stkContractAddresses[whitelistedAddress].length == 0) {
			// check if all the sTokenAddresses provided are non zero
			for (uint256 i = 0; i < sTokenAddresses.length; i = i.add(1)) {
				require(sTokenAddresses[i] != address(0), "RE10");
				_stkContractAddresses[whitelistedAddress].push(
					sTokenAddresses[i]
				);
			}
		}

		emit SetWhitelistedAddress(
			whitelistedAddress,
			sTokenAddresses,
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
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ST10");
		require(whitelistedAddress != address(0), "ST11");
		// remove whitelistedAddress from the list
		_whitelistedAddresses.remove(whitelistedAddress);
		address _holderContractAddressLocal = _holderContractAddress[
			whitelistedAddress
		];
		address _lpContractAddressLocal = _lpContractAddress[
			whitelistedAddress
		];
		address[] memory stkContractAddresses = _stkContractAddresses[
			whitelistedAddress
		];

		// delete holder contract values
		delete _holderContractAddress[whitelistedAddress];
		delete _lpContractAddress[whitelistedAddress];
		delete _stkContractAddresses[whitelistedAddress];

		// remove whitelisted address from _holderWhitelists
		bool whitelistedAddressExists;
		uint256 j;
		uint256 holderWhitelistsLength = _holderWhitelists[
			_holderContractAddressLocal
		].length;
		for (j = 0; j < holderWhitelistsLength; j = j.add(1)) {
			if (
				_holderWhitelists[_holderContractAddressLocal][j] ==
				whitelistedAddress
			) {
				whitelistedAddressExists = true;
				break;
			}
		}

		// if holderAddress is address(0), then remove the whitelistedAddress from the array
		// else add the whitelistedAddress to the array
		if (whitelistedAddressExists) {
			// if the index of whitelistedAddress is the last one then just pop array
			if (j == holderWhitelistsLength.sub(1)) {
				_holderWhitelists[_holderContractAddressLocal].pop();
			} else {
				// else replace the value in the index location with the value in the last index then pop array
				_holderWhitelists[_holderContractAddressLocal][
					j
				] = _holderWhitelists[_holderContractAddressLocal][
					holderWhitelistsLength.sub(1)
				];
				_holderWhitelists[_holderContractAddressLocal].pop();
			}
		}

		// emit event and return
		emit RemoveWhitelistedAddress(
			whitelistedAddress,
			stkContractAddresses,
			_holderContractAddressLocal,
			_lpContractAddressLocal,
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
