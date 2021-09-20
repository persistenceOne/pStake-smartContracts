// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/ISTokensV3.sol";
import "./interfaces/IUTokensV2.sol";
import "./interfaces/IHolderV2.sol";
import "./libraries/FullMath.sol";
import "./interfaces/IRewardEmission.sol";

contract STokensV3 is
	ERC20Upgradeable,
	ISTokensV3,
	PausableUpgradeable,
	AccessControlUpgradeable
{
	using SafeMathUpgradeable for uint256;
	using FullMath for uint256;
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

	// constants defining access control ROLES
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

	// variables pertaining to holder logic for whitelisted addresses & StakeLP
	// deposit contract address for STokens in a DeFi product
	EnumerableSetUpgradeable.AddressSet private _whitelistedAddresses;
	// Holder contract address for this whitelisted contract. Many can point to one Holder contract
	mapping(address => address) public _holderContractAddress;
	// LP Token contract address which might be different from whitelisted contract
	mapping(address => address) public _lpContractAddress;
	// Index of whitelisted address in the Enumerable Set
	// mapping(address => uint256) public _whitelistedAddressIndex;
	// last timestamp when the holder reward calculation was performed for updating reward pool
	mapping(address => uint256) public _lastHolderRewardTimestamp;

	// variables capturing data of other contracts in the product
	address public _liquidStakingContract;
	// address public _stakeLPCoreContract;
	IUTokensV2 public _uTokens;

	// variables pertaining to moving reward rate logic
	uint256[] private _rewardRate;
	uint256[] private _lastMovingRewardTimestamp;
	uint256 public _valueDivisor;
	mapping(address => uint256) public _lastUserRewardTimestamp;

	// variable pertaining to contract upgrades versioning
	uint256 public _version;
	IRewardEmission public _iRewardEmission;

	/**
	 * @dev Constructor for initializing the SToken contract.
	 * @param uaddress - address of the UToken contract.
	 * @param pauserAddress - address of the pauser admin.
	 * @param rewardRate - set to rewardRate * 10^-5
	 * @param valueDivisor - valueDivisor set to 10^9.
	 */
	function initialize(
		address uaddress,
		address pauserAddress,
		uint256 rewardRate,
		uint256 valueDivisor
	) public virtual initializer {
		__ERC20_init("pSTAKE Staked ATOM", "stkATOM");
		__AccessControl_init();
		__Pausable_init();
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(PAUSER_ROLE, pauserAddress);
		setUTokensContract(uaddress);
		_valueDivisor = valueDivisor;
		require(rewardRate <= _valueDivisor.mul(100), "ST1");
		_rewardRate.push(rewardRate);
		_lastMovingRewardTimestamp.push(block.timestamp);
		_setupDecimals(6);
	}

	/**
	 * @dev get reward rate and value divisor
	 */
	function getUTokenAddress()
		public
		view
		virtual
		override
		returns (address uTokenAddress)
	{
		uTokenAddress = address(_uTokens);
	}

	/*
	 * @dev set reward rate called by admin
	 * @param rewardRate: reward rate
	 *
	 *
	 * Requirements:
	 *
	 * - `rate` cannot be less than or equal to zero.
	 *
	 */
	function setRewardRate(uint256 rewardRate)
		public
		virtual
		override
		returns (bool success)
	{
		// range checks for rewardRate. Since rewardRate cannot be more than 100%, the max cap
		// is _valueDivisor * 100, which then brings the fees to 100 (percentage)
		require(rewardRate <= _valueDivisor.mul(100), "ST17");
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ST2");
		_rewardRate.push(rewardRate);
		_lastMovingRewardTimestamp.push(block.timestamp);
		emit SetRewardRate(rewardRate);

		return true;
	}

	/**
	 * @dev get reward rate and value divisor
	 */
	function getRewardRate()
		public
		view
		virtual
		override
		returns (
			uint256[] memory rewardRate,
			uint256[] memory lastMovingRewardTimestamp,
			uint256 valueDivisor
		)
	{
		rewardRate = _rewardRate;
		lastMovingRewardTimestamp = _lastMovingRewardTimestamp;
		valueDivisor = _valueDivisor;
	}

	/**
	 * @dev Mint new stokens for the provided 'address' and 'tokens'
	 * @param to: account address, tokens: number of tokens
	 *
	 * Emits a {MintTokens} event with 'to' set to address and 'tokens' set to amount of tokens.
	 *
	 * Requirements:
	 *
	 * - `amount` cannot be less than zero.
	 *
	 */
	function mint(address to, uint256 tokens)
		public
		virtual
		override
		returns (bool)
	{
		require(_msgSender() == _liquidStakingContract, "ST3");
		_mint(to, tokens);
		return true;
	}

	/*
	 * @dev Burn stokens for the provided 'address' and 'tokens'
	 * @param to: account address, tokens: number of tokens
	 *
	 * Emits a {BurnTokens} event with 'to' set to address and 'tokens' set to amount of tokens.
	 *
	 * Requirements:
	 *
	 * - `amount` cannot be less than zero.
	 *
	 */
	function burn(address from, uint256 tokens)
		public
		virtual
		override
		returns (bool)
	{
		require(_msgSender() == _liquidStakingContract, "ST4");
		_burn(from, tokens);
		return true;
	}

	/**
	 * @dev Calculate pending rewards from the provided 'principal' & 'lastRewardTimestamp'. The rate is the moving reward rate.
	 * @param principal: principal amount
	 * @param lastRewardTimestamp: timestamp of last reward calculation performed
	 */
	function _calculatePendingRewards(
		uint256 principal,
		uint256 lastRewardTimestamp
	) internal view returns (uint256 pendingRewards) {
		uint256 _index;
		uint256 _rewardBlocks;
		uint256 _simpleInterestOfInterval;
		uint256 _temp;
		// return 0 if principal or timeperiod is zero
		if (principal == 0 || block.timestamp.sub(lastRewardTimestamp) == 0)
			return 0;
		// calculate rewards for each interval period between rewardRate changes
		uint256 _lastMovingRewardLength = _lastMovingRewardTimestamp.length.sub(
			1
		);
		for (
			_index = _lastMovingRewardLength;
			_index >= 0;
			_index = _index.sub(1)
		) {
			// logic applies for all indexes of array except last index
			if (_index < _lastMovingRewardTimestamp.length.sub(1)) {
				if (_lastMovingRewardTimestamp[_index] > lastRewardTimestamp) {
					_rewardBlocks = (_lastMovingRewardTimestamp[_index.add(1)])
						.sub(_lastMovingRewardTimestamp[_index]);
					_temp = principal.mulDiv(_rewardRate[_index], 100);
					_simpleInterestOfInterval = _temp.mulDiv(
						_rewardBlocks,
						_valueDivisor
					);
					pendingRewards = pendingRewards.add(
						_simpleInterestOfInterval
					);
				} else {
					_rewardBlocks = (_lastMovingRewardTimestamp[_index.add(1)])
						.sub(lastRewardTimestamp);
					_temp = principal.mulDiv(_rewardRate[_index], 100);
					_simpleInterestOfInterval = _temp.mulDiv(
						_rewardBlocks,
						_valueDivisor
					);
					pendingRewards = pendingRewards.add(
						_simpleInterestOfInterval
					);
					break;
				}
			}
			// logic applies only for the last index of array
			else {
				if (_lastMovingRewardTimestamp[_index] > lastRewardTimestamp) {
					_rewardBlocks = (block.timestamp).sub(
						_lastMovingRewardTimestamp[_index]
					);
					_temp = principal.mulDiv(_rewardRate[_index], 100);
					_simpleInterestOfInterval = _temp.mulDiv(
						_rewardBlocks,
						_valueDivisor
					);
					pendingRewards = pendingRewards.add(
						_simpleInterestOfInterval
					);
				} else {
					_rewardBlocks = (block.timestamp).sub(lastRewardTimestamp);
					_temp = principal.mulDiv(_rewardRate[_index], 100);
					_simpleInterestOfInterval = _temp.mulDiv(
						_rewardBlocks,
						_valueDivisor
					);
					pendingRewards = pendingRewards.add(
						_simpleInterestOfInterval
					);
					break;
				}
			}
		}
		return pendingRewards;
	}

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param to: account address
	 */
	function calculatePendingRewards(address to)
		public
		view
		virtual
		override
		returns (uint256 pendingRewards)
	{
		// Get the time in number of blocks
		uint256 _lastRewardTimestamp = _lastUserRewardTimestamp[to];
		// Get the balance of the account
		uint256 _balance = balanceOf(to);
		// calculate pending rewards using _calculatePendingRewards
		pendingRewards = _calculatePendingRewards(
			_balance,
			_lastRewardTimestamp
		);

		return pendingRewards;
	}

	/**
	 * @dev Calculate rewards for the provided 'address'
	 * @param to: account address
	 */
	function _calculateRewards(address to) internal returns (uint256 _reward) {
		// keep an if condition to check for address(0), instead of require condition, because address(0) is
		// a valid condition when it is a mint/burn operation
		if (to != address(0)) {
			// Calculate the rewards pending
			_reward = calculatePendingRewards(to);

			// Set the new stakedBlock to the current,
			// as per Checks-Effects-Interactions pattern
			_lastUserRewardTimestamp[to] = block.timestamp;

			// mint uTokens only if reward is greater than zero
			if (_reward > 0) {
				// Mint new uTokens and send to the callers account
				_uTokens.mint(to, _reward);
				emit CalculateRewards(to, _reward, block.timestamp);
			}
		}
		return _reward;
	}

	/**
	 * @dev Calculate rewards for the provided 'address'
	 * @param to: account address
	 *
	 * Emits a {TriggeredCalculateRewards} event with 'to' set to address, 'reward' set to amount of tokens and 'timestamp'
	 *
	 */
	function calculateRewards(address to)
		public
		virtual
		override
		whenNotPaused
		returns (uint256 reward)
	{
		require(to == _msgSender(), "ST5");
		reward = _calculateRewards(to);
		emit TriggeredCalculateRewards(to, reward, block.timestamp);
		return reward;
	}

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param to: account address
	 */
	function calculatePendingHolderRewards(address to)
		public
		view
		virtual
		override
		returns (
			uint256 pendingRewards,
			address holderAddress,
			address lpAddress
		)
	{
		(
			uint256 sTokenSupply,
			uint256 lastHolderRewardTimestamp,
			address holderAddressLocal,
			address lpAddressLocal
		) = _iRewardEmission.getPendingHolderRewardsData(to, address(this));

		// check require conditions for null values
		if (
			sTokenSupply != 0 &&
			holderAddressLocal != address(0) &&
			lpAddressLocal != address(0)
		) {
			// calculate the reward applying the moving reward rate
			pendingRewards = _calculatePendingRewards(
				sTokenSupply,
				lastHolderRewardTimestamp
			);
			holderAddress = holderAddressLocal;
			lpAddress = lpAddressLocal;
		}
	}

	/**
	 * @dev Calculate rewards for the provided 'holder address'
	 * @param to: holder address
	 */
	function _calculateHolderRewards(address to)
		internal
		returns (uint256 rewards)
	{
		(
			uint256 pendingRewards,
			address holderAddress,
			address lpAddress
		) = calculatePendingHolderRewards(to);

		// require the holderAddress and lpAddress to be valid values to proceed further
		require(holderAddress != address(0) && lpAddress != address(0), "ST7");

		// update the last timestamp of reward pool to the current time as per Checks-Effects-Interactions pattern
		_iRewardEmission.setLastHolderRewardTimestamp(to, block.timestamp);

		// Mint new uTokens and send to the holder contract account as updated reward pool
		if (pendingRewards > 0) {
			rewards = pendingRewards;
			_uTokens.mint(holderAddress, rewards);
		}
		emit CalculateHolderRewards(to, rewards, block.timestamp);
		return rewards;
	}

	/**
	 * @dev Calculate rewards for the provided 'address'
	 * @param to: account address
	 *
	 * Emits a {TriggeredCalculateRewards} event with 'to' set to address, 'reward' set to amount of tokens and 'timestamp'
	 *
	 */
	function calculateHolderRewards(address to)
		public
		virtual
		override
		whenNotPaused
		returns (uint256 rewards)
	{
		bool isToContractWhitelisted = _iRewardEmission.isContractWhitelisted(
			to,
			address(this)
		);
		// require the to address to be whitelisted as per the current SToken contract address
		require(isToContractWhitelisted, "ST");

		rewards = _calculateHolderRewards(to);
		emit TriggeredCalculateHolderRewards(to, rewards, block.timestamp);
		return rewards;
	}

	/**
	 * @dev Hook that is called before any transfer of tokens. This includes
	 * minting and burning.
	 *
	 * Calling conditions:
	 *
	 * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
	 * will be to transferred to `to`.
	 * - when `from` is zero, `amount` tokens will be minted for `to`.
	 * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
	 * - `from` and `to` are never both zero.
	 *
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual override {
		require(!paused(), "ST7");
		super._beforeTokenTransfer(from, to, amount);
		bool isFromContractWhitelisted = _iRewardEmission.isContractWhitelisted(
			from,
			address(this)
		);
		bool isToContractWhitelisted = _iRewardEmission.isContractWhitelisted(
			to,
			address(this)
		);

		if (!isFromContractWhitelisted) {
			_calculateRewards(from);
			if (!isToContractWhitelisted) {
				_calculateRewards(to);
			} else {
				_calculateHolderRewards(to);
			}
		} else {
			_calculateHolderRewards(from);
			if (!isToContractWhitelisted) {
				_calculateRewards(to);
			} else {
				_calculateHolderRewards(to);
			}
		}
	}

	/*
	 * @dev Set 'contract address', called from constructor
	 * @param uTokenContract: utoken contract address
	 *
	 * Emits a {SetUTokensContract} event with '_contract' set to the utoken contract address.
	 *
	 */
	function setUTokensContract(address uTokenContract)
		public
		virtual
		override
	{
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ST12");
		_uTokens = IUTokensV2(uTokenContract);
		emit SetUTokensContract(uTokenContract);
	}

	/*
	 * @dev Set 'contract address', called from constructor
	 * @param liquidStakingContract: liquidStaking contract address
	 *
	 * Emits a {SetLiquidStakingContract} event with '_contract' set to the liquidStaking contract address.
	 *
	 */
	function setLiquidStakingContract(address liquidStakingContract)
		public
		virtual
		override
	{
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ST13");
		_liquidStakingContract = liquidStakingContract;
		emit SetLiquidStakingContract(liquidStakingContract);
	}

	/*
	 * @dev Set 'contract address', called from constructor
	 * @param uTokenContract: utoken contract address
	 *
	 * Emits a {SetUTokensContract} event with '_contract' set to the utoken contract address.
	 *
	 */
	function setRewardEmissionContract(address rewardEmissionContract)
		public
		virtual
		override
	{
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ST12");
		_iRewardEmission = IRewardEmission(rewardEmissionContract);
		emit SetRewardEmissionContract(rewardEmissionContract);
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
