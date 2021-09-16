// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/ISTokensV2.sol";
import "./interfaces/IUTokensV2.sol";
import "./interfaces/IHolderV2.sol";
import "./interfaces/IPSTAKE.sol";
import "./interfaces/IStakeLPCoreV3.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/FullMath.sol";

contract StakeLPCoreV10 is
	IStakeLPCoreV3,
	PausableUpgradeable,
	AccessControlUpgradeable
{
	using SafeMathUpgradeable for uint256;
	using FullMath for uint256;
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

	// constant pertaining to access roles
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

	// variables pertaining to calculation LP TimeShare
	// balance of user, for an LP Token
	mapping(address => mapping(address => uint256)) public _lpBalance;
	// supply of LP tokens reserve, for an LP Token
	mapping(address => uint256) public _lpSupply;
	// last updated total LPTimeShare, for an LP Token
	mapping(address => uint256) public _lastLPTimeShare;
	// last recorded timestamp when total LPTimeShare was updated, for an LP Token
	mapping(address => uint256) public _lastLPTimeShareTimestamp;
	// last recorded timestamp when user's LPTimeShare was updated, for a user, for an LP Token
	mapping(address => mapping(address => uint256))
		public _lastLiquidityTimestamp;

	//Private instances of contracts to handle Utokens and Stokens
	IUTokensV2 public _uTokens;
	ISTokensV2 public _sTokens;
	IPSTAKE public _pstakeTokens;

	// variable pertaining to contract upgrades versioning
	uint256 public _version;

	// variables pertaining to maintaining reward tokens and amounts to be disbursed
	// List of Holder Contract Addresses
	EnumerableSetUpgradeable.AddressSet private _holderContractList;
	// list of reward tokens enabled, for the reward token, for the holder contract
	mapping(address => address[]) public _rewardTokenList;
	// index of reward token address in the _rewardTokenList array, for the reward token, for the holder contract
	mapping(address => mapping(address => uint256))
		public _rewardTokenListIndex;
	// valueDivisor to store fractional values for various reward attributes like _rewardTokenEmission
	uint256 public _valueDivisor;
	// emission (per second) of reward token into the 'reward pool', for the reward token, for the holder contract
	mapping(address => mapping(address => uint256[]))
		public _rewardTokenEmission;
	// cummulative reward amount at the reward emission timestamp, for the reward token, for the holder contract
	mapping(address => mapping(address => uint256[]))
		public _cummulativeRewardAmount;
	// timestamp recorded when the emission (per second) of reward token is changed, for the reward token,
	// for the holder contract
	mapping(address => mapping(address => uint256[]))
		public _rewardEmissionTimestamp;
	// the last timestamp when the updated reward pool was calculated,
	// for a user, for the reward token, for the holder contract
	mapping(address => mapping(address => mapping(address => uint256)))
		public _rewardPoolUserTimestamp;
	// reward sink refers to a sink variable where extra rewards dropped gets stored when the current emission rate is 0
	// for the reward token, for the holder contract
	mapping(address => mapping(address => uint256)) public _rewardSink;

	/**
	 * @dev Constructor for initializing the LiquidStaking contract.
	 * @param uAddress - address of the UToken contract.
	 * @param sAddress - address of the SToken contract.

	 */
	function initialize(
		address uAddress,
		address sAddress,
		address pStakeAddress,
		address pauserAddress
	) public virtual initializer {
		__AccessControl_init();
		__Pausable_init();
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(PAUSER_ROLE, pauserAddress);
		setUTokensContract(uAddress);
		setSTokensContract(sAddress);
		setPSTAKEContract(pStakeAddress);
		// _lastLPTimeShareTimestamp = block.timestamp;
	}

	function upgradeToV8() public {
		require(_version < 8, "LP37");
		_version = 8;
		_valueDivisor = 1e9;
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function addRewards(
		address holderContractAddress,
		address rewardTokenContractAddress,
		address rewardSender,
		uint256 rewardAmount
	) public override returns (bool success) {
		// require the message sender to be admin
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP1");
		// require the holder contract to be whitelisted for other reward tokens
		require(isHolderContractWhitelisted(holderContractAddress), "LP2");
		// require the reward token contract address be whitelisted for that holder contract
		require(
			_rewardTokenListIndex[holderContractAddress][
				rewardTokenContractAddress
			] != 0,
			"LP3"
		);
		// require reward sender and reward amounts not be zero values
		require(rewardSender != address(0) && rewardAmount != 0, "LP4");

		uint256[]
			storage _cummulativeRewardAmountArray = _cummulativeRewardAmount[
				holderContractAddress
			][rewardTokenContractAddress];
		uint256[]
			storage _rewardEmissionTimestampArray = _rewardEmissionTimestamp[
				holderContractAddress
			][rewardTokenContractAddress];
		uint256[] storage _rewardTokenEmissionArray = _rewardTokenEmission[
			holderContractAddress
		][rewardTokenContractAddress];
		uint256 arrayLength = _cummulativeRewardAmountArray.length;
		uint256 lastRewardAmount;
		uint256 updatedTimestampRemainder;
		uint256 updatedTimestamp;

		// Check if the array has at least one (or two ) entries, else skip the array updation
		// and directly transfer tokens to be allocated during first emission set, using balanceOf
		if (arrayLength > 0) {
			// array will be updated in twos. at least for the first time
			assert(arrayLength != 1);
			// if last timestamp is in the future (or exact present), then update the last entry
			if (
				_rewardEmissionTimestampArray[arrayLength.sub(1)] >=
				block.timestamp
			) {
				// get the reward diff in the last interval block
				lastRewardAmount = (
					_cummulativeRewardAmountArray[arrayLength.sub(1)]
				).sub(_cummulativeRewardAmountArray[arrayLength.sub(2)]);
				// assert that the reward diff is more than zero,
				// then add the diff to new amount and readjust timelines
				assert(lastRewardAmount > 0);
				// calculated the updated timestamp for the emission end using updated reward amount
				lastRewardAmount = lastRewardAmount.add(rewardAmount);
				// calculated updated timestamp which also includes any remainder emission at the end
				// also consider what next timestamp entry should be
				updatedTimestampRemainder = (
					(lastRewardAmount.mul(_valueDivisor)).mod(
						_rewardTokenEmissionArray[arrayLength.sub(2)]
					)
				).div(_valueDivisor);
				updatedTimestampRemainder = updatedTimestampRemainder > 0
					? 1
					: 0;

				updatedTimestamp = (
					(lastRewardAmount.mul(_valueDivisor)).div(
						_rewardTokenEmissionArray[arrayLength.sub(2)]
					)
				).add(updatedTimestampRemainder).add(
						_rewardEmissionTimestampArray[arrayLength.sub(2)]
					);
				// update the timestamp endpoint for emission end to state variable
				_rewardEmissionTimestampArray[
					arrayLength.sub(1)
				] = updatedTimestamp;
				// update the cumulative reward amount for emission end to state variable
				_cummulativeRewardAmountArray[
					arrayLength.sub(1)
				] = lastRewardAmount.add(
					_cummulativeRewardAmountArray[arrayLength.sub(2)]
				);
			} else {
				// if last timestamp is in the past, then it means the current emission rate is 0,
				// so drop the reward in the sink and wait for emission rate to be set non-zero
				lastRewardAmount = _rewardSink[holderContractAddress][
					rewardTokenContractAddress
				];
				_rewardSink[holderContractAddress][
					rewardTokenContractAddress
				] = lastRewardAmount.add(rewardAmount);
				/* _rewardSink[holderContractAddress][
					rewardTokenContractAddress
				] += rewardAmount; */
			}
		}

		// transfer the reward tokens from the sender address to the holder contract address
		// this requires the amount to be approved for transfer as a pre-condition
		IHolderV2(holderContractAddress).safeTransferFrom(
			rewardTokenContractAddress,
			rewardSender,
			holderContractAddress,
			rewardAmount
		);

		emit AddRewards(
			holderContractAddress,
			rewardTokenContractAddress,
			rewardSender,
			rewardAmount,
			block.timestamp
		);

		success = true;
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function setRewardEmission(
		address holderContractAddress,
		address rewardTokenContractAddress,
		uint256 rewardTokenEmission
	) public override returns (bool success) {
		// require the message sender to be admin
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP5");
		// require the holder contract to be whitelisted for other reward tokens
		require(isHolderContractWhitelisted(holderContractAddress), "LP6");
		// require the reward token contract address be whitelisted for that holder contract
		require(
			_rewardTokenListIndex[holderContractAddress][
				rewardTokenContractAddress
			] != 0,
			"LP7"
		);

		uint256[]
			storage _cummulativeRewardAmountArray = _cummulativeRewardAmount[
				holderContractAddress
			][rewardTokenContractAddress];
		uint256[]
			storage _rewardEmissionTimestampArray = _rewardEmissionTimestamp[
				holderContractAddress
			][rewardTokenContractAddress];
		uint256[] storage _rewardTokenEmissionArray = _rewardTokenEmission[
			holderContractAddress
		][rewardTokenContractAddress];
		uint256 arrayLength = _cummulativeRewardAmountArray.length;
		uint256 rewardAmount;
		uint256 remainingRewardAmount;
		uint256 updatedTimestampRemainder;
		uint256 updatedTimestamp;
		uint256 timeInterval;
		// Check if the array has at least one (or two) entries. If so alter the penultimate or endpoint entry
		if (arrayLength > 0) {
			// array will be updated in twos. at least for the first time
			assert(arrayLength != 1);
			// if timestamp endpoint is in the future (or exact present), then update the last entry
			if (
				_rewardEmissionTimestampArray[arrayLength.sub(1)] >
				block.timestamp
			) {
				// if current time is equal to the penultimate marker then
				// update both the penultimate entry and the endpoint entry
				if (
					block.timestamp ==
					_rewardEmissionTimestampArray[arrayLength.sub(2)]
				) {
					// get the reward diff in the last interval block
					rewardAmount = (
						_cummulativeRewardAmountArray[arrayLength.sub(1)]
					).sub(_cummulativeRewardAmountArray[arrayLength.sub(2)]);
					// assert that the reward diff is more than zero,
					assert(rewardAmount > 0);

					// set the penultimate emission value
					_rewardTokenEmissionArray[
						arrayLength.sub(2)
					] = rewardTokenEmission;

					if (rewardTokenEmission > 0) {
						// calculate the time interval across which emission will happen
						updatedTimestampRemainder = (
							(rewardAmount.mul(_valueDivisor)).mod(
								rewardTokenEmission
							)
						).div(_valueDivisor);
						updatedTimestampRemainder = updatedTimestampRemainder >
							0
							? 1
							: 0;

						updatedTimestamp = (
							(
								(rewardAmount.mul(_valueDivisor)).div(
									rewardTokenEmission
								)
							).add(updatedTimestampRemainder)
						).add(block.timestamp);

						// set the endpoint timestamp value
						_rewardEmissionTimestampArray[
							arrayLength.sub(1)
						] = updatedTimestamp;
					} else {
						// move the remnant reward amount to sink
						// rewardSinkLocal = rewardSinkLocal.add(rewardAmount);
						// rewardSinkLocal += rewardAmount;
						_rewardSink[holderContractAddress][
							rewardTokenContractAddress
						] += rewardAmount;

						// remove the endpoint reward amount
						_cummulativeRewardAmount[holderContractAddress][
							rewardTokenContractAddress
						].pop();
						// remove the endpoint reward emission
						_rewardTokenEmission[holderContractAddress][
							rewardTokenContractAddress
						].pop();
						// remove the endpoint reward timestamp
						_rewardEmissionTimestamp[holderContractAddress][
							rewardTokenContractAddress
						].pop();
					}

					// if current time is more than penultimate marker then update
					// endpoint marker and add new element as the new endpoint
				} else {
					timeInterval = block.timestamp.sub(
						_rewardEmissionTimestampArray[arrayLength.sub(2)]
					);

					rewardAmount = timeInterval.mulDiv(
						_rewardTokenEmissionArray[arrayLength.sub(2)],
						_valueDivisor
					);

					remainingRewardAmount = _cummulativeRewardAmountArray[
						arrayLength.sub(1)
					].sub(rewardAmount);

					// set the previous endpoint cumulative reward amount
					_cummulativeRewardAmountArray[
						arrayLength.sub(1)
					] = _cummulativeRewardAmountArray[arrayLength.sub(2)].add(
						rewardAmount
					);
					// set the previous endpoint reward emission
					_rewardTokenEmissionArray[
						arrayLength.sub(1)
					] = rewardTokenEmission;
					// set the previous endpoint reward timestamp
					_rewardEmissionTimestampArray[arrayLength.sub(1)] = block
						.timestamp;

					// above logic is common for both conditions of rewardTokenEmission being zero or not
					// now if rewardEmission is not zero then create new array entry as endpoint, else
					// dump remaining reward amount to reward sink
					if (rewardTokenEmission > 0) {
						// set the new endpoint cumulative reward amount
						_cummulativeRewardAmount[holderContractAddress][
							rewardTokenContractAddress
						].push(
								_cummulativeRewardAmountArray[
									arrayLength.sub(1)
								].add(remainingRewardAmount)
							);
						// set the new endpoint reward emission
						_rewardTokenEmission[holderContractAddress][
							rewardTokenContractAddress
						].push(0);
						// calculate the time interval across which emission will happen
						updatedTimestampRemainder = (
							(remainingRewardAmount.mul(_valueDivisor)).mod(
								rewardTokenEmission
							)
						).div(_valueDivisor);
						updatedTimestampRemainder = updatedTimestampRemainder >
							0
							? 1
							: 0;

						updatedTimestamp = (
							(remainingRewardAmount.mul(_valueDivisor)).div(
								rewardTokenEmission
							)
						).add(updatedTimestampRemainder).add(block.timestamp);

						// set the new endpoint reward timestamp
						_rewardEmissionTimestamp[holderContractAddress][
							rewardTokenContractAddress
						].push(updatedTimestamp);
					} else {
						/* rewardSinkLocal = rewardSinkLocal.add(
							remainingRewardAmount
						); */
						// rewardSinkLocal += remainingRewardAmount;
						_rewardSink[holderContractAddress][
							rewardTokenContractAddress
						] += remainingRewardAmount;
					}
				}
			} else {
				// if the timestamp endpoint is in the past or exact present
				// then check rewardSink and create two new entries in array
				rewardAmount = _rewardSink[holderContractAddress][
					rewardTokenContractAddress
				];
				if (rewardAmount == 0) revert("LP8");
				else {
					// set the new penultimate cumulative reward amount
					_cummulativeRewardAmount[holderContractAddress][
						rewardTokenContractAddress
					].push(_cummulativeRewardAmountArray[arrayLength.sub(1)]);

					// set the new endpoint cumulative reward amount
					_cummulativeRewardAmount[holderContractAddress][
						rewardTokenContractAddress
					].push(
							_cummulativeRewardAmountArray[arrayLength.sub(1)]
								.add(rewardAmount)
						);

					// set the new penultimate reward emission
					_rewardTokenEmission[holderContractAddress][
						rewardTokenContractAddress
					].push(rewardTokenEmission);

					// set the new endpoint reward emission
					_rewardTokenEmission[holderContractAddress][
						rewardTokenContractAddress
					].push(0);

					// set the new penultimate reward timestamp
					_rewardEmissionTimestamp[holderContractAddress][
						rewardTokenContractAddress
					].push(block.timestamp);

					// calculate the time interval across which emission will happen
					updatedTimestampRemainder = (
						(rewardAmount.mul(_valueDivisor)).mod(
							rewardTokenEmission
						)
					).div(_valueDivisor);
					updatedTimestampRemainder = updatedTimestampRemainder > 0
						? 1
						: 0;

					updatedTimestamp = (
						(rewardAmount.mul(_valueDivisor)).div(
							rewardTokenEmission
						)
					).add(updatedTimestampRemainder).add(block.timestamp);

					// set the new endpoint reward timestamp
					_rewardEmissionTimestamp[holderContractAddress][
						rewardTokenContractAddress
					].push(updatedTimestamp);
				}
			}
		} else {
			// if the array has no entries, then create two new entries in the array
			// calculate the reward amount to be set in array
			if (rewardTokenEmission > 0) {
				rewardAmount = IERC20Upgradeable(rewardTokenContractAddress)
					.balanceOf(holderContractAddress);
				if (rewardAmount > 0) {
					// calculate the time interval across which emission will happen
					updatedTimestampRemainder = (
						(rewardAmount.mul(_valueDivisor)).mod(
							rewardTokenEmission
						)
					).div(_valueDivisor);
					updatedTimestampRemainder = updatedTimestampRemainder > 0
						? 1
						: 0;

					updatedTimestamp = (
						(rewardAmount.mul(_valueDivisor)).div(
							rewardTokenEmission
						)
					).add(updatedTimestampRemainder).add(block.timestamp);

					// set the new penultimate reward amount
					_cummulativeRewardAmount[holderContractAddress][
						rewardTokenContractAddress
					].push(0);
					// set the new penultimate reward emission
					_rewardTokenEmission[holderContractAddress][
						rewardTokenContractAddress
					].push(rewardTokenEmission);
					// set the new penultimate reward timestamp
					_rewardEmissionTimestamp[holderContractAddress][
						rewardTokenContractAddress
					].push(block.timestamp);

					// set the new endpoint reward amount
					_cummulativeRewardAmount[holderContractAddress][
						rewardTokenContractAddress
					].push(rewardAmount);
					// set the new endpoint reward emission
					_rewardTokenEmission[holderContractAddress][
						rewardTokenContractAddress
					].push(0);
					// set the new endpoint reward timestamp
					_rewardEmissionTimestamp[holderContractAddress][
						rewardTokenContractAddress
					].push(updatedTimestamp);
				} else {
					// if there is no reward balance then revert because one cannot
					// set an emission rate if there is no reward balance
					revert("LP9");
				}
			} else {
				// if new emission set is zero then revert because one cannot set a zero
				// emission rate the very first time as its already set as zero
				revert("LP10");
			}
		}

		emit SetRewardEmission(
			holderContractAddress,
			rewardTokenContractAddress,
			rewardTokenEmission,
			_valueDivisor,
			block.timestamp
		);
		success = true;
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param to: user address
	 * @param liquidityWeightFactor: coming as an argument for further calculations
	 * @param rewardWeightFactor: coming as an argument for further calculations
	 * @param valueDivisor: coming as an argument for further calculations
	 */
	function getEmissionData(
		address holderContractAddress,
		address rewardTokenContractAddress
	)
		public
		view
		returns (
			uint256[] memory cummulativeRewardAmount,
			uint256[] memory rewardTokenEmission,
			uint256[] memory rewardEmissionTimestamp
		)
	{
		return (
			_cummulativeRewardAmount[holderContractAddress][
				rewardTokenContractAddress
			],
			_rewardTokenEmission[holderContractAddress][
				rewardTokenContractAddress
			],
			_rewardEmissionTimestamp[holderContractAddress][
				rewardTokenContractAddress
			]
		);
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function deleteEmissionData(
		address holderContractAddress,
		address rewardTokenContractAddress
	) public returns (bool success) {
		delete _cummulativeRewardAmount[holderContractAddress][
			rewardTokenContractAddress
		];
		delete _rewardTokenEmission[holderContractAddress][
			rewardTokenContractAddress
		];
		delete _rewardEmissionTimestamp[holderContractAddress][
			rewardTokenContractAddress
		];
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
		virtual
		override
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
			to,
			_userLPTimeShare,
			_totalSupplyLPTimeShare
		);
	}

	function _getCumulativeRewardValue(
		address holderContractAddress,
		address rewardTokenContractAddress,
		uint256 rewardTimestamp
	) public view returns (uint256 cumulativeRewardValue) {
		uint256[]
			storage _cummulativeRewardAmountArray = _cummulativeRewardAmount[
				holderContractAddress
			][rewardTokenContractAddress];
		uint256[]
			storage _rewardEmissionTimestampArray = _rewardEmissionTimestamp[
				holderContractAddress
			][rewardTokenContractAddress];
		uint256[] storage _rewardTokenEmissionArray = _rewardTokenEmission[
			holderContractAddress
		][rewardTokenContractAddress];
		uint256 arrayLength = _rewardEmissionTimestampArray.length;
		uint256 higherIndex;
		uint256 lowerIndex;
		uint256 midIndex;
		uint256 rewardAmount;
		uint256 timeInterval;
		// if the timestamp marker is more than the endpoint reward timestamp, then return
		if (
			rewardTimestamp > _rewardEmissionTimestampArray[arrayLength.sub(1)]
		) {
			cumulativeRewardValue = _cummulativeRewardAmountArray[
				arrayLength.sub(1)
			];
			return cumulativeRewardValue;
		}
		// find the index which is exact match for rewardTimestamp or comes closest to it
		higherIndex = arrayLength.sub(1);
		// if the given timestamp matches the first or last index of array, then return the
		// cumulative reward amount of that index location
		if (
			_rewardEmissionTimestampArray[lowerIndex] == rewardTimestamp ||
			_rewardEmissionTimestampArray[higherIndex] == rewardTimestamp
		) {
			cumulativeRewardValue = rewardTimestamp ==
				_rewardEmissionTimestampArray[lowerIndex]
				? _cummulativeRewardAmountArray[lowerIndex]
				: _cummulativeRewardAmountArray[higherIndex];
		} else {
			while (higherIndex.sub(lowerIndex) > 1) {
				midIndex = (higherIndex.add(lowerIndex)).div(2);
				if (
					rewardTimestamp == _rewardEmissionTimestampArray[midIndex]
				) {
					cumulativeRewardValue = _cummulativeRewardAmountArray[
						midIndex
					];
					break;
				} else if (
					rewardTimestamp < _rewardEmissionTimestampArray[midIndex]
				) {
					higherIndex = midIndex;
				} else {
					lowerIndex = midIndex;
				}
			}
			if (higherIndex.sub(lowerIndex) <= 1) {
				cumulativeRewardValue = _cummulativeRewardAmountArray[
					lowerIndex
				];
				timeInterval = rewardTimestamp.sub(
					_rewardEmissionTimestampArray[lowerIndex]
				);
				rewardAmount = timeInterval.mul(
					_rewardTokenEmissionArray[lowerIndex]
				);
				cumulativeRewardValue = cumulativeRewardValue.add(rewardAmount);
			}
		}
		return cumulativeRewardValue;
	}

	function _calculateOtherPendingRewards(
		address holderAddress,
		address to,
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
		// make sure _totalSupplyLPTimeShare is not zero
		if (_totalSupplyLPTimeShare == 0) {
			return (
				otherRewardAmounts,
				otherRewardTokens,
				updatedRewardPoolBalances
			);
		}
		uint256 _rewardTokenListLength = _rewardTokenList[holderAddress].length;
		otherRewardAmounts = new uint256[](_rewardTokenListLength);
		otherRewardTokens = new address[](_rewardTokenListLength);
		updatedRewardPoolBalances = new uint256[](_rewardTokenListLength);

		uint256 _updatedRewardPool;
		uint256 _startingCumulativeRewardValue;
		uint256 _endingCumulativeRewardValue;

		for (uint256 i = 0; i < _rewardTokenListLength; i = i.add(1)) {
			// allocate token contract address to otherRewardTokens
			otherRewardTokens[i] = _rewardTokenList[holderAddress][i];

			// calculate the updated reward pool to be considered for user's reward share calculation
			// if no emission array is found or current time has crossed the last entry of _rewardEmissionTimestamp
			// (reward endpoint timestamp) then set the updated reward pool to zero
			uint256 _rewardEmissionTimestampLength = _rewardEmissionTimestamp[
				holderAddress
			][otherRewardTokens[i]].length;
			uint256 _rewardPoolUserTimestampLocal = _rewardPoolUserTimestamp[
				holderAddress
			][otherRewardTokens[i]][to];
			if (
				_rewardEmissionTimestampLength == 0 ||
				_rewardPoolUserTimestampLocal >
				_rewardEmissionTimestamp[holderAddress][otherRewardTokens[i]][
					_rewardEmissionTimestampLength.sub(1)
				]
			) {
				_updatedRewardPool = 0;
			} else {
				// calculate reward pool balance as per user's _rewardPoolUserTimestamp and current time
				_startingCumulativeRewardValue = _getCumulativeRewardValue(
					holderAddress,
					otherRewardTokens[i],
					_rewardPoolUserTimestampLocal
				);
				_endingCumulativeRewardValue = _getCumulativeRewardValue(
					holderAddress,
					otherRewardTokens[i],
					block.timestamp
				);
				_updatedRewardPool = _endingCumulativeRewardValue.sub(
					_startingCumulativeRewardValue
				);
			}

			// calculate reward amount values for each reward token by calculating LPTimeShare of the updatedRewardPool
			if (_updatedRewardPool > 0) {
				// calculate user's reward for that particular reward token
				otherRewardAmounts[i] = _updatedRewardPool.mulDiv(
					_userLPTimeShare,
					_totalSupplyLPTimeShare
				);
				// allocate updated reward pool balance after subtracting user's reward amounts
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
		address uTokenAddress,
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
			IHolderV2(holderAddress).safeTransfer(uTokenAddress, to, reward);

		// DISBURSE THE OTHER REWARD TOKENS TO USER (transfer)
		uint256 i;
		uint256 otherRewardTokensLength = otherRewardTokens.length;
		for (i = 0; i < otherRewardTokensLength; i = i.add(1)) {
			// set the last 'updated reward pool' calculation timestamp to current time
			_rewardPoolUserTimestamp[holderAddress][otherRewardTokens[i]][
				to
			] = block.timestamp;

			// dispatch the rewards for that specific token
			if (otherRewardAmounts[i] > 0) {
				IHolderV2(holderAddress).safeTransfer(
					otherRewardTokens[i],
					to,
					otherRewardAmounts[i]
				);
			}
		}

		emit CalculateRewardsStakeLP(
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
	function calculateRewards(address whitelistedAddress, address sTokenAddress)
		public
		virtual
		override
		whenNotPaused
		returns (
			uint256 reward,
			uint256[] memory otherRewardAmounts,
			address[] memory otherRewardTokens
		)
	{
		// check for validity of arguments
		require(
			whitelistedAddress != address(0) && sTokenAddress != address(0),
			"LP11"
		);

		// check if lpToken contract of DeFi product address is whitelisted and has valid holder contract
		(
			address _holderAddress,
			address _lpToken,
			address _uTokenAddress,

		) = ISTokensV2(sTokenAddress).getHolderData(whitelistedAddress);

		// (bool _isContractWhitelisted, address _holderAddress) = _sTokens.isContractWhitelisted(_lpToken);
		require(
			_lpToken != address(0) &&
				_holderAddress != address(0) &&
				_uTokenAddress != address(0),
			"LP12"
		);

		// calculate liquidity and reward tokens and disburse to user
		(reward, otherRewardAmounts, otherRewardTokens) = _calculateRewards(
			_holderAddress,
			_lpToken,
			_uTokenAddress,
			_msgSender()
		);

		emit TriggeredCalculateRewardsStakeLP(
			_holderAddress,
			_lpToken,
			_uTokenAddress,
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
	function calculateSyncedRewards(
		address whitelistedAddress,
		address sTokenAddress
	)
		public
		virtual
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
		require(
			whitelistedAddress != address(0) && sTokenAddress != address(0),
			"LP13"
		);

		// check if lpToken contract of DeFi product address is whitelisted and has valid holder contract
		(
			address _holderAddress,
			address _lpToken,
			address _uTokenAddress,

		) = ISTokensV2(sTokenAddress).getHolderData(whitelistedAddress);

		// (bool _isContractWhitelisted, address _holderAddress) = _sTokens.isContractWhitelisted(_lpToken);
		require(
			_lpToken != address(0) &&
				_holderAddress != address(0) &&
				_uTokenAddress != address(0),
			"LP14"
		);

		// initiate calculateHolderRewards first, using STokens contract
		// to sync the reward pool in holder contract with rewards from whitelisted contract
		holderReward = _sTokens.calculateHolderRewards(whitelistedAddress);

		// now initiate the _calculateRewards to distribute to the user
		// calculate liquidity and reward tokens and disburse to user
		(reward, otherRewardAmounts, otherRewardTokens) = _calculateRewards(
			_holderAddress,
			_lpToken,
			_uTokenAddress,
			_msgSender()
		);

		emit TriggeredCalculateSyncedRewards(
			_holderAddress,
			_lpToken,
			_uTokenAddress,
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
	function addLiquidity(
		address whitelistedAddress,
		address sTokenAddress,
		uint256 amount
	) public virtual override whenNotPaused returns (bool success) {
		// check for validity of arguments
		require(
			amount > 0 &&
				whitelistedAddress != address(0) &&
				sTokenAddress != address(0),
			"LP15"
		);

		// check if lpToken contract of DeFi product address is whitelisted and has valid holder contract
		// (bool _isContractWhitelisted, address _holderAddress) = _sTokens.isContractWhitelisted(_lpToken);
		(
			address _holderAddress,
			address _lpToken,
			address _uTokenAddress,

		) = ISTokensV2(sTokenAddress).getHolderData(whitelistedAddress);
		require(
			_holderAddress != address(0) &&
				_lpToken != address(0) &&
				_uTokenAddress != address(0),
			"LP16"
		);
		address messageSender = _msgSender();

		// calculate liquidity and reward tokens and disburse to user
		_calculateRewards(
			_holderAddress,
			_lpToken,
			_uTokenAddress,
			messageSender
		);
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
	function removeLiquidity(
		address whitelistedAddress,
		address sTokenAddress,
		uint256 amount
	) public virtual override whenNotPaused returns (bool success) {
		// check for validity of arguments
		require(
			amount > 0 &&
				whitelistedAddress != address(0) &&
				sTokenAddress != address(0),
			"LP17"
		);

		// check if lpToken contract of DeFi product address is whitelisted and has valid holder contract
		// (bool _isContractWhitelisted, address _holderAddress) = _sTokens.isContractWhitelisted(lpToken);
		(
			address _holderAddress,
			address _lpToken,
			address _uTokenAddress,

		) = ISTokensV2(sTokenAddress).getHolderData(whitelistedAddress);
		require(
			_holderAddress != address(0) &&
				_lpToken != address(0) &&
				_uTokenAddress != address(0),
			"LP18"
		);
		address messageSender = _msgSender();

		// check if suffecient balance is there
		require(_lpBalance[_lpToken][messageSender] >= amount, "LP19");

		// calculate liquidity and reward tokens and disburse to user
		_calculateRewards(
			_holderAddress,
			_lpToken,
			_uTokenAddress,
			messageSender
		);

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
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP20");
		_uTokens = IUTokensV2(uAddress);
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
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP21");
		_sTokens = ISTokensV2(sAddress);
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
		address[] memory rewardTokenContractAddresses
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
		}
		success = true;
		return success;
	}

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param holderAddress: holder contract address
	 */
	function isHolderContractWhitelisted(address holderAddress)
		public
		view
		virtual
		override
		returns (bool result)
	{
		result = _holderContractList.contains(holderAddress);
		return result;
	}

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function setHolderAddressesForRewards(
		address[] memory holderContractAddresses,
		address[] memory rewardTokenContractAddresses
	) public override returns (bool success) {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP24");
		uint256 _holderContractAddressesLength = holderContractAddresses.length;
		uint256 i;
		for (i = 0; i < _holderContractAddressesLength; i = i.add(1)) {
			require(holderContractAddresses[i] != address(0), "LP26");
			_setHolderAddressForRewards(
				holderContractAddresses[i],
				rewardTokenContractAddresses
			);
		}

		// emit an event capturing the action
		emit SetHolderAddressesForRewards(
			holderContractAddresses,
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
	function removeHolderAddressesForRewards(
		address[] memory holderContractAddresses
	) public override returns (bool success) {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP29");
		uint256 _holderContractAddressesLength = holderContractAddresses.length;
		uint256 i;
		for (i = 0; i < _holderContractAddressesLength; i = i.add(1)) {
			require(holderContractAddresses[i] != address(0), "LP30");
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
	function removeTokenContractsForRewards(
		address[] memory holderContractAddresses,
		address[] memory rewardTokenContractAddresses
	) public override returns (bool success) {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP33");
		uint256 _holderContractAddressesLength = holderContractAddresses.length;
		uint256 i;
		for (i = 0; i < _holderContractAddressesLength; i = i.add(1)) {
			require(holderContractAddresses[i] != address(0), "LP34");
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
	function pause() public virtual override returns (bool success) {
		require(hasRole(PAUSER_ROLE, _msgSender()), "LP35");
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
		require(hasRole(PAUSER_ROLE, _msgSender()), "LP36");
		_unpause();
		return true;
	}
}
