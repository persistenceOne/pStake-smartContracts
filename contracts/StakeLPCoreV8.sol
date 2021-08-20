// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./interfaces/ISTokens.sol";
import "./interfaces/IUTokens.sol";
import "./interfaces/IPSTAKE.sol";
import "./interfaces/IHolder.sol";
import "./interfaces/IStakeLPCore.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/FullMath.sol";

contract StakeLPCoreV8 is
	IStakeLPCore,
	PausableUpgradeable,
	AccessControlUpgradeable
{
	using SafeMathUpgradeable for uint256;
	using FullMath for uint256;
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

	// constant pertaining to access roles
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

	// variables pertaining to calculation LP TimeShare
	// balance of user for an LP Token
	mapping(address => mapping(address => uint256)) public _lpBalance;
	// supply for an LP Token
	mapping(address => uint256) public _lpSupply;
	// last updated total LPTimeShare
	mapping(address => uint256) public _lastLPTimeShare;
	// last recorded timestamp when total LPTimeShare was updated
	mapping(address => uint256) public _lastLPTimeShareTimestamp;
	// last recorded timestamp when user's LPTimeShare was updated
	mapping(address => mapping(address => uint256))
		public _lastLiquidityTimestamp;

	//Private instances of contracts to handle Utokens and Stokens
	IUTokens public _uTokens;
	ISTokens public _sTokens;
	IPSTAKE public _pstakeTokens;

	// variable pertaining to contract upgrades versioning
	uint256 private _version;

	// variables pertaining to maintaining reward tokens and amounts to be disbursed
	// List of Holder Contract Addresses
	EnumerableSetUpgradeable.AddressSet private _holderContractList;
	// list of reward tokens enabled, for a specific holder contract
	mapping(address => address[]) public _rewardTokenList;
	// index of reward token address in the _rewardTokenList array, for a specific holder contract
	mapping(address => mapping(address => uint256))
		public _rewardTokenListIndex;
	// valueDivisor to store fractional values for various reward attributes like _rewardTokenEmission
	uint256 public _valueDivisor;
	// emission (per second) of reward token into the 'reward pool', for a specific holder contract
	mapping(address => mapping(address => uint256)) public _rewardTokenEmission;
	// last updated reward pool balance, for a specific reward token, for a specific holder contract
	mapping(address => mapping(address => uint256))
		public _lastRewardPoolBalance;
	// last recorded timestamp when the reward pool balance was updated,
	// for a specific reward token, for a specific holder contract
	mapping(address => mapping(address => uint256))
		public _lastRewardPoolBalanceTimestamp;

	/**
	 * @dev Constructor for initializing the LiquidStaking contract.
	 * @param uAddress - address of the UToken contract.
	 * @param sAddress - address of the SToken contract.
	 * @param pStakeAddress - address of the pStake contract address.

	 */
	function initialize(
		address uAddress,
		address sAddress,
		address pStakeAddress,
		address pauserAddress,
		uint256 valueDivisor
	) public virtual initializer {
		__AccessControl_init();
		__Pausable_init();
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(PAUSER_ROLE, pauserAddress);
		setUTokensContract(uAddress);
		setSTokensContract(sAddress);
		setPSTAKEContract(pStakeAddress);
		_valueDivisor = valueDivisor;
	}

	function upgradeToV8() public {
		require(_version < 8, "LP5");
		_version = 8;
		_valueDivisor = 1e18;
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param to: user address
	 * @param liquidityWeightFactor: coming as an argument for further calculations
	 * @param rewardWeightFactor: coming as an argument for further calculations
	 * @param valueDivisor: coming as an argument for further calculations
	 */
	function calculatePendingRewards(
		address holderAddress,
		address lpToken,
		address to
	)
		public
		view
		returns (
			uint256 reward,
			uint256[] memory otherRewardAmounts,
			address[] memory otherRewardTokens,
			uint256[] memory updatedRewardPoolBalances,
			uint256 updatedSupplyLPTimeshare
		)
	{
		// calculate the LPTimeShare of the user's LP Token
		uint256 _userLPTimeShare = (
			(_lpBalance[lpToken][to]).mul(
				block.timestamp.sub(_lastLiquidityTimestamp[lpToken][to])
			)
		);

		// calculate the LPTimeShare of the sum of supply of all LP Tokens
		uint256 _newSupplyLPTimeShare = (
			(_lpSupply[lpToken]).mul(
				block.timestamp.sub(_lastLPTimeShareTimestamp[lpToken])
			)
		);
		uint256 _totalSupplyLPTimeShare = _lastLPTimeShare[lpToken].add(
			_newSupplyLPTimeShare
		);
		// calculate the remaining LPTimeShare of the total supply after the tokens for the user has been dispatched
		updatedSupplyLPTimeshare = _totalSupplyLPTimeShare.sub(
			_userLPTimeShare
		);

		// calculate the rewardPool and reward
		if (_totalSupplyLPTimeShare > 0) {
			// calculate users new reward tokens. reward pool will be total balance of Holder Contract
			uint256 _rewardPool = _uTokens.balanceOf(holderAddress);
			reward = _rewardPool.mulDiv(
				_userLPTimeShare,
				_totalSupplyLPTimeShare
			);
		}

		(
			otherRewardAmounts,
			otherRewardTokens,
			updatedRewardPoolBalances
		) = _calculateOtherPendingRewards(
			holderAddress,
			_userLPTimeShare,
			_totalSupplyLPTimeShare
		);
	}

	function _calculateOtherPendingRewards(
		address holderAddress,
		uint256 _userLPTimeShare,
		uint256 _totalSupplyLPTimeShare
	)
		internal
		view
		returns (
			uint256[] memory otherRewardAmounts,
			address[] memory otherRewardTokens,
			uint256[] memory updatedRewardPoolBalances
		)
	{
		if (_totalSupplyLPTimeShare > 0) {
			uint256 _rewardTokenListLength = _rewardTokenList[holderAddress]
				.length;
			otherRewardAmounts = new uint256[](_rewardTokenListLength);
			otherRewardTokens = new address[](_rewardTokenListLength);
			updatedRewardPoolBalances = new uint256[](_rewardTokenListLength);

			uint256 _rewardEmissionLocal;
			uint256 _rewardPoolReserve;
			uint256 _updatedRewardPool;
			uint256 _rewardEmissionInterval;

			for (uint256 i = 0; i < _rewardTokenListLength; i = i.add(1)) {
				otherRewardTokens[i] = _rewardTokenList[holderAddress][i];
				_rewardEmissionLocal = _rewardTokenEmission[holderAddress][
					otherRewardTokens[i]
				];
				_rewardEmissionInterval = block.timestamp.sub(
					_lastRewardPoolBalanceTimestamp[holderAddress][
						otherRewardTokens[i]
					]
				);
				// calculate the updated reward pool to be considered for user's reward share calculation
				_updatedRewardPool = (
					_rewardEmissionLocal.mul(_rewardEmissionInterval)
				).add(
						_lastRewardPoolBalance[holderAddress][
							otherRewardTokens[i]
						]
					);

				_rewardPoolReserve = ERC20Upgradeable(otherRewardTokens[i])
					.balanceOf(holderAddress);

				_updatedRewardPool = _updatedRewardPool > _rewardPoolReserve
					? _rewardPoolReserve
					: _updatedRewardPool;

				if (_updatedRewardPool > 0) {
					// calculate user's reward for that particular reward token
					otherRewardAmounts[i] = _updatedRewardPool.mulDiv(
						_userLPTimeShare,
						_totalSupplyLPTimeShare
					);
				}

				// calculated updated reward pool balance after subtracting user's reward
				updatedRewardPoolBalances[i] = _updatedRewardPool.sub(
					otherRewardAmounts[i]
				);
			}
		}
	}

	/*
	 * @dev calculate reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param to: user address
	 * @param liquidityWeightFactor: coming as an argument for further calculations
	 * @param rewardWeightFactor: coming as an argument for further calculations
	 * @param valueDivisor: coming as an argument for further calculations
	 */
	function _calculateRewards(
		address holderAddress,
		address lpToken,
		address to
	)
		internal
		returns (
			uint256 reward,
			uint256[] memory otherRewardAmounts,
			address[] memory otherRewardTokens
		)
	{
		uint256[] memory updatedRewardPoolBalances;
		uint256 updatedSupplyLPTimeshare;

		(
			reward,
			otherRewardAmounts,
			otherRewardTokens,
			updatedRewardPoolBalances,
			updatedSupplyLPTimeshare
		) = calculatePendingRewards(holderAddress, lpToken, to);

		// update last timestamps and LPTimeShares as per Checks-Effects-Interactions pattern
		_lastLiquidityTimestamp[lpToken][to] = block.timestamp;
		_lastLPTimeShareTimestamp[lpToken] = block.timestamp;
		_lastLPTimeShare[lpToken] = updatedSupplyLPTimeshare;

		// DISBURSE THE REWARD TOKENS TO USER (transfer)
		if (reward > 0)
			IHolder(holderAddress).safeTransfer(address(_uTokens), to, reward);

		// DISBURSE THE OTHER REWARD TOKENS TO USER (transfer)
		uint256 i;
		uint256 otherRewardTokensLength = otherRewardTokens.length;
		for (i = 0; i < otherRewardTokensLength; i = i.add(1)) {
			// dispatch the rewards for that specific token
			if (otherRewardAmounts[i] > 0) {
				IHolder(holderAddress).safeTransfer(
					otherRewardTokens[i],
					to,
					otherRewardAmounts[i]
				);
			}
			//  update the reward pool balance and last timestamp
			//  corresonding to that particular reward token
			_lastRewardPoolBalance[holderAddress][
				otherRewardTokens[i]
			] = updatedRewardPoolBalances[i];
			_lastRewardPoolBalanceTimestamp[holderAddress][
				otherRewardTokens[i]
			] = block.timestamp;
		}

		emit CalculateRewards(
			holderAddress,
			lpToken,
			to,
			reward,
			otherRewardAmounts,
			otherRewardTokens,
			block.timestamp
		);

		return (reward, otherRewardAmounts, otherRewardTokens);
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function calculateRewards(address whitelistedAddress)
		public
		override
		whenNotPaused
		returns (
			uint256 reward,
			uint256[] memory otherRewardAmounts,
			address[] memory otherRewardTokens
		)
	{
		// check for validity of arguments
		require(whitelistedAddress != address(0), "LP2");

		// check if lpToken contract of DeFi product address is whitelisted and has valid holder contract
		(address _holderAddress, address _lpToken, ) = _sTokens.getHolderData(
			whitelistedAddress
		);

		// (bool _isContractWhitelisted, address _holderAddress) = _sTokens.isContractWhitelisted(_lpToken);
		require(_lpToken != address(0) && _holderAddress != address(0), "LP1");

		// calculate liquidity and reward tokens and disburse to user
		(reward, otherRewardAmounts, otherRewardTokens) = _calculateRewards(
			_holderAddress,
			_lpToken,
			_msgSender()
		);

		emit TriggeredCalculateRewards(
			_holderAddress,
			_lpToken,
			_msgSender(),
			reward,
			otherRewardAmounts,
			otherRewardTokens,
			block.timestamp
		);

		return (reward, otherRewardAmounts, otherRewardTokens);
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function calculateSyncedRewards(address whitelistedAddress)
		public
		override
		whenNotPaused
		returns (
			uint256 reward,
			uint256 holderReward,
			uint256[] memory otherRewardAmounts,
			address[] memory otherRewardTokens
		)
	{
		// check for validity of arguments
		require(whitelistedAddress != address(0), "LP2");

		// check if lpToken contract of DeFi product address is whitelisted and has valid holder contract
		(address _holderAddress, address _lpToken, ) = _sTokens.getHolderData(
			whitelistedAddress
		);

		// (bool _isContractWhitelisted, address _holderAddress) = _sTokens.isContractWhitelisted(_lpToken);
		require(_lpToken != address(0) && _holderAddress != address(0), "LP1");

		// initiate calculateHolderRewards first, using STokens contract
		// to sync the reward pool in holder contract with rewards from whitelisted contract
		holderReward = _sTokens.calculateHolderRewards(whitelistedAddress);

		// now initiate the _calculateRewards to distribute to the user
		// calculate liquidity and reward tokens and disburse to user
		(reward, otherRewardAmounts, otherRewardTokens) = _calculateRewards(
			_holderAddress,
			_lpToken,
			_msgSender()
		);

		emit TriggeredCalculateSyncedRewards(
			_holderAddress,
			_lpToken,
			_msgSender(),
			reward,
			holderReward,
			otherRewardAmounts,
			otherRewardTokens,
			block.timestamp
		);

		return (reward, holderReward, otherRewardAmounts, otherRewardTokens);
	}

	/*
	 * @dev adding the liquidity
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 *
	 * Emits a {AddLiquidity} event with 'lpToken, amount, rewards and liquidity'
	 *
	 */
	function addLiquidity(address whitelistedAddress, uint256 amount)
		public
		virtual
		override
		whenNotPaused
		returns (bool success)
	{
		// check for validity of arguments
		require(amount > 0 && whitelistedAddress != address(0), "LP3");

		// check if lpToken contract of DeFi product address is whitelisted and has valid holder contract
		// (bool _isContractWhitelisted, address _holderAddress) = _sTokens.isContractWhitelisted(_lpToken);
		(address _holderAddress, address _lpToken, ) = _sTokens.getHolderData(
			whitelistedAddress
		);
		require(_holderAddress != address(0) && _lpToken != address(0), "LP4");
		address messageSender = _msgSender();

		// calculate liquidity and reward tokens and disburse to user
		_calculateRewards(_holderAddress, _lpToken, messageSender);
		// finally transfer the new LP Tokens to the StakeLP contract
		TransferHelper.safeTransferFrom(
			_lpToken,
			messageSender,
			address(this),
			amount
		);

		// update the user balance
		_lpBalance[_lpToken][messageSender] = _lpBalance[_lpToken][
			messageSender
		].add(amount);
		// update the supply of lp tokens for reward and liquidity calculation
		_lpSupply[_lpToken] = _lpSupply[_lpToken].add(amount);

		// emit an event
		emit AddLiquidity(_lpToken, amount, block.timestamp);
		success = true;
		return success;
	}

	/*
	 * @dev removing the liquidity
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 *
	 * Emits a {RemoveLiquidity} event with 'lpToken, amount, rewards and liquidity'
	 *
	 */
	function removeLiquidity(address whitelistedAddress, uint256 amount)
		public
		virtual
		override
		whenNotPaused
		returns (bool success)
	{
		// check for validity of arguments
		require(amount > 0 && whitelistedAddress != address(0), "LP6");

		// check if lpToken contract of DeFi product address is whitelisted and has valid holder contract
		// (bool _isContractWhitelisted, address _holderAddress) = _sTokens.isContractWhitelisted(lpToken);
		(address _holderAddress, address _lpToken, ) = _sTokens.getHolderData(
			whitelistedAddress
		);
		require(_holderAddress != address(0) && _lpToken != address(0), "LP7");
		address messageSender = _msgSender();

		// check if suffecient balance is there
		require(_lpBalance[_lpToken][messageSender] >= amount, "LP8");

		// calculate liquidity and reward tokens and disburse to user
		_calculateRewards(_holderAddress, _lpToken, messageSender);

		// finally transfer the LP Tokens to the user
		TransferHelper.safeTransfer(_lpToken, messageSender, amount);

		// update the user balance
		_lpBalance[_lpToken][messageSender] = _lpBalance[_lpToken][
			messageSender
		].sub(amount);
		// update the supply of lp tokens for reward and liquidity calculation
		_lpSupply[_lpToken] = _lpSupply[_lpToken].sub(amount);

		emit RemoveLiquidity(_lpToken, amount, block.timestamp);
		success = true;
		return success;
	}

	/**
	 * @dev Set 'contract address', called from constructor
	 * @param uAddress: utoken contract address
	 *
	 * Emits a {SetUTokensContract} event with '_contract' set to the utoken contract address.
	 *
	 */
	function setUTokensContract(address uAddress) public virtual override {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP9");
		_uTokens = IUTokens(uAddress);
		emit SetUTokensContract(uAddress);
	}

	/**
	 * @dev Set 'contract address', called from constructor
	 * @param sAddress: stoken contract address
	 *
	 * Emits a {SetSTokensContract} event with '_contract' set to the stoken contract address.
	 *
	 */
	function setSTokensContract(address sAddress) public virtual override {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP10");
		_sTokens = ISTokens(sAddress);
		emit SetSTokensContract(sAddress);
	}

	/**
	 * @dev Set 'contract address', called from constructor
	 * @param pstakeAddress: pStake contract address
	 *
	 * Emits a {SetPSTAKEContract} event with '_contract' set to the stoken contract address.
	 *
	 */
	function setPSTAKEContract(address pstakeAddress) public virtual override {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP11");
		_pstakeTokens = IPSTAKE(pstakeAddress);
		emit SetPSTAKEContract(pstakeAddress);
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function _setHolderAddressForRewards(
		address holderContractAddress,
		address[] memory rewardTokenContractAddresses,
		uint256[] memory rewardTokenEmissions
	) internal returns (bool success) {
		// add the Holder Contract address if it isn't already available
		if (!_holderContractList.contains(holderContractAddress)) {
			_holderContractList.add(holderContractAddress);
		}

		uint256 i;
		uint256 _rewardTokenContractAddressesLength = rewardTokenContractAddresses
				.length;
		for (i = 0; i < _rewardTokenContractAddressesLength; i = i.add(1)) {
			// add the Token Contract addresss to the reward tokens list for the Holder Contract
			if (rewardTokenContractAddresses[i] != address(0)) {
				// search if the reward token contract is already part of list
				if (
					_rewardTokenListIndex[holderContractAddress][
						rewardTokenContractAddresses[i]
					] == 0
				) {
					_rewardTokenList[holderContractAddress].push(
						rewardTokenContractAddresses[i]
					);
					_rewardTokenListIndex[holderContractAddress][
						rewardTokenContractAddresses[i]
					] = _rewardTokenList[holderContractAddress].length;
				}
			}
			// add the reward token emission value to the mapping
			if (rewardTokenEmissions[i] != 0) {
				_rewardTokenEmission[holderContractAddress][
					rewardTokenContractAddresses[i]
				] = rewardTokenEmissions[i];
			}
		}
		success = true;
		return success;
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function setHolderAddressForRewards(
		address holderContractAddress,
		address[] memory rewardTokenContractAddresses,
		uint256[] memory rewardTokenEmissions
	) public returns (bool success) {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP15");
		// check if the holder contract address is not zero
		require(
			holderContractAddress != address(0) &&
				rewardTokenContractAddresses.length ==
				rewardTokenEmissions.length,
			"LP14"
		);
		_setHolderAddressForRewards(
			holderContractAddress,
			rewardTokenContractAddresses,
			rewardTokenEmissions
		);
		// emit an event capturing the action
		emit SetHolderAddressForRewards(
			holderContractAddress,
			rewardTokenContractAddresses,
			rewardTokenEmissions,
			block.timestamp
		);

		success = true;
		return success;
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function setHolderAddressesForRewards(
		address[] memory holderContractAddresses,
		address[] memory rewardTokenContractAddresses,
		uint256[] memory rewardTokenEmissions
	) public returns (bool success) {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP16");
		require(
			rewardTokenContractAddresses.length == rewardTokenEmissions.length,
			"LP17"
		);
		uint256 _holderContractAddressesLength = holderContractAddresses.length;
		uint256 i;
		for (i = 0; i < _holderContractAddressesLength; i = i.add(1)) {
			require(holderContractAddresses[i] != address(0), "LP18");
			_setHolderAddressForRewards(
				holderContractAddresses[i],
				rewardTokenContractAddresses,
				rewardTokenEmissions
			);
		}

		// emit an event capturing the action
		emit SetHolderAddressesForRewards(
			holderContractAddresses,
			rewardTokenContractAddresses,
			rewardTokenEmissions,
			block.timestamp
		);

		success = true;
		return success;
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function _removeHolderAddressForRewards(address holderContractAddress)
		internal
		returns (bool success)
	{
		// delete holder contract from enumerable set
		_holderContractList.remove(holderContractAddress);
		// get the list of token contracts and remove the index values, and their emissions
		address[] memory _rewardTokenListLocal = _rewardTokenList[
			holderContractAddress
		];
		uint256 _rewardTokenListLength = _rewardTokenListLocal.length;
		uint256 i;
		for (i = 0; i < _rewardTokenListLength; i = i.add(1)) {
			delete _rewardTokenListIndex[holderContractAddress][
				_rewardTokenListLocal[i]
			];
			delete _rewardTokenEmission[holderContractAddress][
				_rewardTokenListLocal[i]
			];
		}
		// delete the list of token contract addresses
		delete _rewardTokenList[holderContractAddress];

		success = true;
		return success;
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function removeHolderAddressForRewards(address holderContractAddress)
		public
		returns (bool success)
	{
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP15");
		// check if the holder contract address is not zero
		require(holderContractAddress != address(0), "LP14");

		_removeHolderAddressForRewards(holderContractAddress);
		// emit an event capturing the action
		emit RemoveHolderAddressForRewards(
			holderContractAddress,
			block.timestamp
		);

		success = true;
		return success;
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function removeHolderAddressesForRewards(
		address[] memory holderContractAddresses
	) public returns (bool success) {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP16");
		uint256 _holderContractAddressesLength = holderContractAddresses.length;
		uint256 i;
		for (i = 0; i < _holderContractAddressesLength; i = i.add(1)) {
			require(holderContractAddresses[i] != address(0), "LP18");
			_removeHolderAddressForRewards(holderContractAddresses[i]);
		}

		// emit an event capturing the action
		emit RemoveHolderAddressesForRewards(
			holderContractAddresses,
			block.timestamp
		);

		success = true;
		return success;
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function _removeTokenContractForRewards(
		address holderContractAddress,
		address[] memory rewardTokenContractAddresses
	) internal returns (bool success) {
		uint256 i;
		uint256 _rewardTokenContractAddressesLength = rewardTokenContractAddresses
				.length;
		for (i = 0; i < _rewardTokenContractAddressesLength; i = i.add(1)) {
			if (rewardTokenContractAddresses[i] != address(0)) {
				// remove the token address from the list
				uint256 rewardTokenListIndexLocal = _rewardTokenListIndex[
					holderContractAddress
				][rewardTokenContractAddresses[i]];
				if (rewardTokenListIndexLocal > 0) {
					if (
						rewardTokenListIndexLocal ==
						_rewardTokenList[holderContractAddress].length
					) {
						_rewardTokenList[holderContractAddress].pop();
					} else {
						_rewardTokenList[holderContractAddress][
							rewardTokenListIndexLocal.sub(1)
						] = _rewardTokenList[holderContractAddress][
							_rewardTokenList[holderContractAddress].length.sub(
								1
							)
						];
						_rewardTokenList[holderContractAddress].pop();
					}

					// delete the index value
					delete _rewardTokenListIndex[holderContractAddress][
						rewardTokenContractAddresses[i]
					];

					// delete the emission value
					delete _rewardTokenEmission[holderContractAddress][
						rewardTokenContractAddresses[i]
					];
				}
			}
		}

		success = true;
		return success;
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function removeTokenContractForRewards(
		address holderContractAddress,
		address[] memory rewardTokenContractAddresses
	) public returns (bool success) {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP15");
		// check if the holder contract address is not zero
		require(holderContractAddress != address(0), "LP14");
		_removeTokenContractForRewards(
			holderContractAddress,
			rewardTokenContractAddresses
		);
		// emit an event capturing the action
		emit RemoveTokenContractForRewards(
			holderContractAddress,
			rewardTokenContractAddresses,
			block.timestamp
		);

		success = true;
		return success;
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function removeTokenContractsForRewards(
		address[] memory holderContractAddresses,
		address[] memory rewardTokenContractAddresses
	) public returns (bool success) {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP16");
		uint256 _holderContractAddressesLength = holderContractAddresses.length;
		uint256 i;
		for (i = 0; i < _holderContractAddressesLength; i = i.add(1)) {
			require(holderContractAddresses[i] != address(0), "LP18");
			_removeTokenContractForRewards(
				holderContractAddresses[i],
				rewardTokenContractAddresses
			);
		}

		// emit an event capturing the action
		emit RemoveTokenContractsForRewards(
			holderContractAddresses,
			rewardTokenContractAddresses,
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
	function pause() public virtual returns (bool success) {
		require(hasRole(PAUSER_ROLE, _msgSender()), "LP12");
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
	function unpause() public virtual returns (bool success) {
		require(hasRole(PAUSER_ROLE, _msgSender()), "LP13");
		_unpause();
		return true;
	}
}
