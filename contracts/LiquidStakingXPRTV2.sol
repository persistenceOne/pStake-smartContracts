/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./interfaces/ISTokensXPRT.sol";
import "./interfaces/IUTokensXPRT.sol";
import "./interfaces/ILiquidStakingXPRTV2.sol";
import "./interfaces/ITokenWrapperXPRTV2.sol";
import "./libraries/FullMath.sol";

contract LiquidStakingXPRTV2 is
ILiquidStakingXPRTV2,
PausableUpgradeable,
AccessControlUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using FullMath for uint256;

    //Private instances of contracts to handle Utokens and Stokens
    IUTokensXPRT public _uTokens;
    ISTokensXPRT public _sTokens;

    // defining the fees and minimum values
    uint256 private _minStake;
    uint256 private _minUnstake;
    uint256 private _stakeFee;
    uint256 private _unstakeFee;
    uint256 public _valueDivisor;

    // constants defining access control ROLES
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // variables pertaining to unbonding logic
    uint256 private _unstakingLockTime;
    uint256 private _epochInterval;
    uint256 private _unstakeEpoch;
    uint256 private _unstakeEpochPrevious;

    //Mapping to handle the Expiry period
    mapping(address => uint256[]) public _unstakingExpiration;

    //Mapping to handle the Expiry amount
    mapping(address => uint256[]) public _unstakingAmount;

    //mappint to handle a counter variable indicating from what index to start the loop.
    mapping(address => uint256) public _withdrawCounters;

    // variable pertaining to contract upgrades versioning
    uint256 public _version;

    uint256 public _batchingLimit;

    // TokenWrapper contract address
    address public override _tokenWrapperContract;

    // BRIDGE_ADMIN role constant (needs to be set)
    bytes32 public constant BRIDGE_ADMIN_ROLE = keccak256("BRIDGE_ADMIN_ROLE");


    /**
     * @dev Constructor for initializing the LiquidStaking contract.
     * @param uAddress - address of the UToken contract.
     * @param sAddress - address of the SToken contract.
     * @param pauserAddress - address of the pauser admin.
     * @param unstakingLockTime - varies from 21 hours to 21 days.
     * @param epochInterval - varies from 3 hours to 3 days.
     * @param valueDivisor - valueDivisor set to 10^9.
     */
    function initialize(
        address uAddress,
        address sAddress,
        address pauserAddress,
        uint256 unstakingLockTime,
        uint256 epochInterval,
        uint256 valueDivisor
    ) public virtual initializer {
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, pauserAddress);
        setUTokensContract(uAddress);
        setSTokensContract(sAddress);
        setUnstakingLockTime(unstakingLockTime);
        setMinimumValues(1, 1);
        _valueDivisor = valueDivisor;
        setUnstakeEpoch(block.timestamp, block.timestamp, epochInterval);
    }

    /**
     * @dev Set 'fees', called from admin
     * @param stakeFee: stake fee
     * @param unstakeFee: unstake fee
     *
     * Emits a {SetFees} event with 'fee' set to the stake and unstake.
     *
     */
    function setFees(uint256 stakeFee, uint256 unstakeFee)
    public
    virtual
    override
    returns (bool success)
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ1");
        // range checks for fees. Since fee cannot be more than 100%, the max cap
        // is _valueDivisor * 100, which then brings the fees to 100 (percentage)
        require(
            (stakeFee <= _valueDivisor.mul(100) || stakeFee == 0) &&
            (unstakeFee <= _valueDivisor.mul(100) || unstakeFee == 0),
            "LQ2"
        );
        _stakeFee = stakeFee;
        _unstakeFee = unstakeFee;
        emit SetFees(stakeFee, unstakeFee);
        return true;
    }

    /**
     * @dev Set 'unstake props', called from admin
     * @param unstakingLockTime: varies from 21 hours to 21 days
     *
     * Emits a {SetUnstakeProps} event with 'fee' set to the stake and unstake.
     *
     */
    function setUnstakingLockTime(uint256 unstakingLockTime)
    public
    virtual
    override
    returns (bool success)
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ3");
        _unstakingLockTime = unstakingLockTime;
        emit SetUnstakingLockTime(unstakingLockTime);
        return true;
    }

    /**
     * @dev get the SToken and UToken address
     *
     */
    function getTokens()
    public
    view
    virtual
    override
    returns (address sTokenAddress, address uTokenAddress)
    {
        sTokenAddress = address(_sTokens);
        uTokenAddress = address(_uTokens);
    }

    /**
     * @dev get fees, min values, value divisor and epoch props
     *
     */
    function getStakeUnstakeProps()
    public
    view
    virtual
    override
    returns (
        uint256 stakeFee,
        uint256 unstakeFee,
        uint256 minStake,
        uint256 minUnstake,
        uint256 valueDivisor,
        uint256 epochInterval,
        uint256 unstakeEpoch,
        uint256 unstakeEpochPrevious,
        uint256 unstakingLockTime
    )
    {
        stakeFee = _stakeFee;
        unstakeFee = _unstakeFee;
        minStake = _minStake;
        minUnstake = _minStake;
        valueDivisor = _valueDivisor;
        epochInterval = _epochInterval;
        unstakeEpoch = _unstakeEpoch;
        unstakeEpochPrevious = _unstakeEpochPrevious;
        unstakingLockTime = _unstakingLockTime;
    }

    /**
     * @dev Set 'minimum values', called from admin
     * @param minStake: stake minimum value
     * @param minUnstake: unstake minimum value
     *
     * Emits a {SetMinimumValues} event with 'minimum value' set to the stake and unstake.
     *
     */
    function setMinimumValues(uint256 minStake, uint256 minUnstake)
    public
    virtual
    override
    returns (bool success)
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ4");
        require(minStake >= 1, "LQ5");
        require(minUnstake >= 1, "LQ6");
        _minStake = minStake;
        _minUnstake = minUnstake;
        emit SetMinimumValues(minStake, minUnstake);
        return true;
    }

    /**
     * @dev Set 'unstake epoch', called from admin
     * @param unstakeEpoch: unstake epoch
     * @param unstakeEpochPrevious: unstake epoch previous(initially set to same value as unstakeEpoch)
     * @param epochInterval: varies from 3 hours to 3 days
     *
     * Emits a {SetUnstakeEpoch} event with 'unstakeEpoch'
     *
     */
    function setUnstakeEpoch(
        uint256 unstakeEpoch,
        uint256 unstakeEpochPrevious,
        uint256 epochInterval
    ) public virtual override returns (bool success) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ7");
        require(unstakeEpochPrevious <= unstakeEpoch, "LQ8");
        if (unstakeEpoch == 0 && epochInterval != 0) revert("LQ9");
        _unstakeEpoch = unstakeEpoch;
        _unstakeEpochPrevious = unstakeEpochPrevious;
        _epochInterval = epochInterval;
        emit SetUnstakeEpoch(unstakeEpoch, unstakeEpochPrevious, epochInterval);
        return true;
    }

    /**
     * @dev Set 'contract address', called from constructor
     * @param uAddress: utoken contract address
     *
     * Emits a {SetUTokensContract} event with '_contract' set to the utoken contract address.
     *
     */
    function setUTokensContract(address uAddress) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ10");
        _uTokens = IUTokensXPRT(uAddress);
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
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ11");
        _sTokens = ISTokensXPRT(sAddress);
        emit SetSTokensContract(sAddress);
    }

    /**
     * @dev Set 'contract address', called from constructor
     * @param tokenWrapperContract: stoken contract address
     *
     * Emits a {SetTokenWrapperContract} event with '_contract' set to the stoken contract address.
     *
     */
    function setTokenWrapperContract(address tokenWrapperContract)
    public
    virtual
    override
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ27");
        _tokenWrapperContract = tokenWrapperContract;
        emit SetTokenWrapperContract(tokenWrapperContract);
    }


    /**
     * @dev Stake utokens over the platform with address 'to' for desired 'amount'(Burn uTokens and Mint sTokens)
     * @param to: user address for staking, amount: number of tokens to stake
     * @param stakingAmount: amount to be converted to stkToken
     * @param wrappingAmount: amount to be converted to pToken
     *
     */
    function _stakeDirect(
    address to,
    uint256 stakingAmount,
    uint256 wrappingAmount
    ) internal returns (uint256 amountStaked, uint256 amountWrapped) {
        // require to addres to be non zero and stakingAmount & wrappingAmount to not be zero simultaneously
        require(
        to != address(0) && !(stakingAmount == 0 && wrappingAmount == 0),
        "LQ26"
        );
        // factor the fee component and find the resultant STokens to be minted
        uint256 stakeFeeAmount;
        uint256 depositFeeAmount;
        uint256 depositFee;
        uint256 valueDivisor;

        stakeFeeAmount = (stakingAmount.mulDiv(_stakeFee, _valueDivisor)).div(
        100
        );
        amountStaked = stakingAmount.sub(stakeFeeAmount);

        // get the deposit fee from the TokenWrapper contract
        (depositFee, , , , valueDivisor) = ITokenWrapperXPRTV2(
        _tokenWrapperContract
        ).getProps();

        // factor the fee component and find the resultant UTokens to be minted
        depositFeeAmount = (wrappingAmount.mulDiv(depositFee, valueDivisor))
        .div(100);
        amountWrapped = wrappingAmount.sub(depositFeeAmount);

        // perform the mint for the staked and the wrapped amounts
        _uTokens.mint(to, amountWrapped);
        _sTokens.mint(to, amountStaked);
    }

    /**
     * @dev Stake utokens over the platform with address 'to' for desired 'amount'(Burn uTokens and Mint sTokens)
     * @param to: user address for staking, amount: number of tokens to stake
     * @param stakingAmount: amount to be converted to stkToken
     * @param wrappingAmount: amount to be converted to pToken
     *
     */
    function stakeDirect(
    address to,
    uint256 stakingAmount,
    uint256 wrappingAmount
    )
    public
    virtual
    override
    returns (uint256 amountStaked, uint256 amountWrapped)
    {
        // only bridge admin is allowed to execute this function
        require(hasRole(BRIDGE_ADMIN_ROLE, _msgSender()), "LQ25");

        (amountStaked, amountWrapped) = _stakeDirect(
        to,
        stakingAmount,
        wrappingAmount
        );

        emit StakeDirect(
        to,
        stakingAmount,
        amountStaked,
        wrappingAmount,
        amountWrapped,
        block.timestamp
        );
    }

    /**
     * @dev Stake utokens over the platform with address 'to' for desired 'amount'(Burn uTokens and Mint sTokens)
     * @param toAddressses: user addresses for staking, amount: number of tokens to stake
     * @param stakingAmounts: amounts to be converted to stkToken
     * @param wrappingAmounts: amounts to be converted to pToken
     *
     * Emits a {StakeDirectInBatch} event with 'to' set to address and 'amount' set to amount of tokens.
     */
    function stakeDirectInBatch(
    address[] calldata toAddressses,
    uint256[] calldata stakingAmounts,
    uint256[] calldata wrappingAmounts
    )
    external
    virtual
    override
    returns (
    uint256[] memory amountsStaked,
    uint256[] memory amountsWrapped
    )
    {
        // only bridge admin is allowed to execute this function
        require(hasRole(BRIDGE_ADMIN_ROLE, _msgSender()), "LQ28");

        // require the array sizes to be equal
        require(
        toAddressses.length == stakingAmounts.length &&
        stakingAmounts.length == wrappingAmounts.length,
        "LQ29"
        );

        uint256 amountStaked;
        uint256 amountWrapped;
        uint256 index;
        uint256 arrayLength = toAddressses.length;
        amountsStaked = new uint256[](arrayLength);
        amountsWrapped = new uint256[](arrayLength);

        for (index = 0; index < arrayLength; index++) {
        (amountStaked, amountWrapped) = _stakeDirect(
        toAddressses[index],
        stakingAmounts[index],
        wrappingAmounts[index]
        );
        amountsStaked[index] = amountStaked;
        amountsWrapped[index] = amountWrapped;
        }

        emit StakeDirectInBatch(
        toAddressses,
        stakingAmounts,
        amountsStaked,
        wrappingAmounts,
        amountsWrapped,
        block.timestamp
        );
    }


    /**
     * @dev Stake utokens over the platform with address 'to' for desired 'amount'(Burn uTokens and Mint sTokens)
     * @param to: user address for staking, amount: number of tokens to stake
     *
     *
     * Requirements:
     *
     * - `amount` cannot be less than zero.
     * - 'amount' cannot be more than balance
     * - 'amount' plus new balance should be equal to the old balance
     */
    function stake(address to, uint256 amount)
    public
    virtual
    override
    whenNotPaused
    returns (bool)
    {
        // Check the supplied amount is greater than minimum stake value
        require(to == _msgSender(), "LQ12");
        // Check the current balance for uTokens is greater than the amount to be staked
        uint256 _currentUTokenBalance = _uTokens.balanceOf(to);
        uint256 _stakeFeeAmount = (amount.mulDiv(_stakeFee, _valueDivisor)).div(
            100
        );
        uint256 _finalTokens = amount.add(_stakeFeeAmount);
        // the value which should be greater than or equal to _minStake
        // is amount since minval applies to number of sTokens to be minted
        require(amount >= _minStake, "LQ13");
        require(_currentUTokenBalance >= _finalTokens, "LQ14");
        emit StakeTokens(to, amount, _finalTokens, block.timestamp);
        // Burn the uTokens as specified with the amount
        _uTokens.burn(to, _finalTokens);
        // Mint the sTokens for the account specified
        _sTokens.mint(to, amount);
        return true;
    }

    /**
     * @dev UnStake stokens over the platform with address 'to' for desired 'amount' (Burn sTokens and Mint uTokens with 21 days locking period)
     * @param to: user address for staking, amount: number of tokens to unstake
     *
     *
     * Requirements:
     *
     * - `amount` cannot be less than zero.
     * - 'amount' cannot be more than balance
     * - 'amount' plus new balance should be equal to the old balance
     */
    function unStake(address to, uint256 amount)
    public
    virtual
    override
    whenNotPaused
    returns (bool)
    {
        // Check the supplied amount is greater than 0
        require(to == _msgSender(), "LQ15");
        // Check the current balance for sTokens is greater than the amount to be unStaked
        uint256 _currentSTokenBalance = _sTokens.balanceOf(to);
        uint256 _unstakeFeeAmount = (amount.mulDiv(_unstakeFee, _valueDivisor))
        .div(100);
        uint256 _finalTokens = amount.add(_unstakeFeeAmount);
        // the value which should be greater than or equal to _minSUnstake
        // is amount since minval applies to number of uTokens to be withdrawn
        require(amount >= _minUnstake, "LQ18");
        require(_currentSTokenBalance >= _finalTokens, "LQ19");
        // Burn the sTokens as specified with the amount
        _sTokens.burn(to, _finalTokens);
        _unstakingExpiration[to].push(block.timestamp);
        // array will hold amount and not _finalTokens because that is the amount of
        // uTokens pending to be credited after withdraw period
        _unstakingAmount[to].push(amount);
        // the event needs to capture _finalTokens that were and not amount
        emit UnstakeTokens(to, amount, _finalTokens, block.timestamp);

        return true;
    }

    /**
     * @dev returns the nearest epoch milestone in the future
     */
    function getUnstakeEpochMilestone(uint256 _unstakeTimestamp)
    public
    view
    virtual
    override
    returns (uint256 unstakeEpochMilestone)
    {
        if (_unstakeTimestamp == 0) return 0;
        // if epoch values are not relevant, then the epoch milestone is the unstake timestamp itself (backward compatibility)
        if (
            (_unstakeEpoch == 0 && _unstakeEpochPrevious == 0) ||
            _epochInterval == 0
        ) return _unstakeTimestamp;
        if (_unstakeEpoch > _unstakeTimestamp) return (_unstakeEpoch);
        uint256 _referenceStartTime = (_unstakeTimestamp).add(
            _unstakeEpoch.sub(_unstakeEpochPrevious)
        );
        uint256 _timeDiff = _referenceStartTime.sub(_unstakeEpoch);
        unstakeEpochMilestone = (_timeDiff.mod(_epochInterval)).add(
            _referenceStartTime
        );
        return (unstakeEpochMilestone);
    }

    /**
     * @dev returns the time left for unbonding to finish
     */
    function getUnstakeTime(uint256 _unstakeTimestamp)
    public
    view
    virtual
    override
    returns (
        uint256 unstakeTime,
        uint256 unstakeEpoch,
        uint256 unstakeEpochPrevious
    )
    {
        uint256 _unstakeEpochMilestone = getUnstakeEpochMilestone(
            _unstakeTimestamp
        );
        if (_unstakeEpochMilestone == 0)
            return (0, unstakeEpoch, unstakeEpochPrevious);
        unstakeEpoch = _unstakeEpoch;
        unstakeEpochPrevious = _unstakeEpochPrevious;
        //adding unstakingLockTime with epoch difference
        unstakeTime = _unstakeEpochMilestone.add(_unstakingLockTime);
        return (unstakeTime, unstakeEpoch, unstakeEpochPrevious);
    }

    /**
     * @dev Lock the unstaked tokens for 21 days, user can withdraw the same (Mint uTokens with 21 days locking period)
     *
     * @param staker: user address for withdraw
     *
     * Requirements:
     *
     * - `current block timestamp` should be after 21 days from the period where unstaked function is called.
     */
    function withdrawUnstakedTokens(address staker)
    public
    virtual
    override
    whenNotPaused
    {
        require(staker == _msgSender(), "LQ20");
        uint256 _withdrawBalance;
        uint256 _counter = _withdrawCounters[staker];
        uint256 _counter2 = _withdrawCounters[staker];
        uint256 _unstakingExpirationLength = _unstakingExpiration[staker]
        .length > _batchingLimit.add(_counter)
        ? _batchingLimit.add(_counter)
        : _unstakingExpiration[staker].length;

        for (
            uint256 i = _counter;
            i < _unstakingExpirationLength;
            i = i.add(1)
        ) {
            //get getUnstakeTime and compare it with current timestamp to check if 21 days + epoch difference has passed
            (uint256 _getUnstakeTime, , ) = getUnstakeTime(
                _unstakingExpiration[staker][i]
            );
            if (block.timestamp >= _getUnstakeTime) {
                //if 21 days + epoch difference has passed, then add the balance and then mint uTokens
                _withdrawBalance = _withdrawBalance.add(
                    _unstakingAmount[staker][i]
                );
                delete _unstakingExpiration[staker][i];
                delete _unstakingAmount[staker][i];
                _counter2 = _counter2.add(1);
            }
        }

        // update _withdrawCounters[staker] only once outside for loop to save gas
        _withdrawCounters[staker] = _counter2;
        require(_withdrawBalance > 0, "LQ21");
        emit WithdrawUnstakeTokens(staker, _withdrawBalance, block.timestamp);
        _uTokens.mint(staker, _withdrawBalance);
    }

    /**
     * @dev get Total Unbonded Tokens
     * @param staker: account address
     *
     */
    function getTotalUnbondedTokens(address staker)
    public
    view
    virtual
    override
    returns (uint256 unbondingTokens)
    {
        uint256 _unstakingExpirationLength = _unstakingExpiration[staker]
        .length;
        uint256 _counter = _withdrawCounters[staker];
        for (
            uint256 i = _counter;
            i < _unstakingExpirationLength;
            i = i.add(1)
        ) {
            //get getUnstakeTime and compare it with current timestamp to check if 21 days + epoch difference has passed
            (uint256 _getUnstakeTime, , ) = getUnstakeTime(
                _unstakingExpiration[staker][i]
            );
            if (block.timestamp >= _getUnstakeTime) {
                //if 21 days + epoch difference has passed, then check the token amount and send back
                unbondingTokens = unbondingTokens.add(
                    _unstakingAmount[staker][i]
                );
            }
        }
        return unbondingTokens;
    }

    /**
     * @dev get Total Unbonding Tokens
     * @param staker: account address
     *
     */
    function getTotalUnbondingTokens(address staker)
    public
    view
    virtual
    override
    returns (uint256 unbondingTokens)
    {
        uint256 _unstakingExpirationLength = _unstakingExpiration[staker]
        .length;
        uint256 _counter = _withdrawCounters[staker];
        for (
            uint256 i = _counter;
            i < _unstakingExpirationLength;
            i = i.add(1)
        ) {
            //get getUnstakeTime and compare it with current timestamp to check if 21 days + epoch difference has passed
            (uint256 _getUnstakeTime, , ) = getUnstakeTime(
                _unstakingExpiration[staker][i]
            );
            if (block.timestamp < _getUnstakeTime) {
                //if 21 days + epoch difference have not passed, then check the token amount and send back
                unbondingTokens = unbondingTokens.add(
                    _unstakingAmount[staker][i]
                );
            }
        }
        return unbondingTokens;
    }

    /**
     * @dev Set 'fees', called from admin
     * Emits a {SetFees} event with 'fee' set to the stake and unstake.
     *
     */
    function setBatchingLimit(uint256 batchingLimit)
    public
    virtual
    override
    returns (bool success)
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ24");
        _batchingLimit = batchingLimit;
        emit SetBatchingLimit(batchingLimit, block.timestamp);
        success = true;
        return success;
    }

    /**
     * @dev get fees, min values, value divisor and epoch props
     *
     */
    function getBatchingLimit()
    public
    view
    virtual
    override
    returns (uint256 batchingLimit)
    {
        batchingLimit = _batchingLimit;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public virtual override returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "LQ22");
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
        require(hasRole(PAUSER_ROLE, _msgSender()), "LQ23");
        _unpause();
        return true;
    }
}
