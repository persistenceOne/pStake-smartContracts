// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./interfaces/ISTokens.sol";
import "./interfaces/IUTokens.sol";
import "./interfaces/ILiquidStaking.sol";

contract LiquidStaking is ILiquidStaking, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;

    //Private instances of contracts to handle Utokens and Stokens
    IUTokens private _uTokens;
    ISTokens private _sTokens;

    // defining the fees and minimum values
    uint256 private _minStake;
    uint256 private _minUnstake;
    uint256 private _stakeFee;
    uint256 private _unstakeFee;
    uint256 private _valueDivisor;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 private _unstakingLockTime;
    uint256 private _epochInterval;
    uint256 private _unstakeEpoch;
    uint256 private _unstakeEpochPrevious;

    //Mapping to handle the Expiry period
    mapping(address => uint256[]) private _unstakingExpiration;

    //Mapping to handle the Expiry amount
    mapping(address => uint256[]) private _unstakingAmount;

    //mappint to handle a counter variable indicating from what index to start the loop.
    mapping(address => uint256) internal _withdrawCounters;

    /**
   * @dev Constructor for initializing the LiquidStaking contract.
   * @param uAddress - address of the UToken contract.
   * @param sAddress - address of the SToken contract.
   * @param pauserAddress - address of the pauser admin.
   * @param unstakingLockTime - varies from 21 hours to 21 days.
   * @param epochInterval - varies from 3 hours to 3 days.
   * @param valueDivisor - valueDivisor set to 10^9.
   */
    function initialize(address uAddress, address sAddress, address pauserAddress, uint256 unstakingLockTime, uint256 epochInterval, uint256 valueDivisor) public virtual initializer  {
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, pauserAddress);
        setUTokensContract(uAddress);
        setSTokensContract(sAddress);
        setUnstakingLockTime(unstakingLockTime);
        _valueDivisor = valueDivisor;
        setUnstakeEpoch(_unstakeEpoch, _unstakeEpochPrevious, epochInterval);
    }

    /**
     * @dev Set 'fees', called from admin
     * @param stakeFee: stake fee
     * @param unstakeFee: unstake fee
     *
     * Emits a {SetFees} event with 'fee' set to the stake and unstake.
     *
     */
    function setFees(uint256 stakeFee, uint256 unstakeFee) public virtual returns (bool success) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ1");
        // range checks for fees. Since fee cannot be more than 100%, the max cap 
        // is _valueDivisor * 100, which then brings the fees to 100 (percentage) 
        require(stakeFee <= _valueDivisor.mul(100) && unstakeFee <= _valueDivisor.mul(100), "LQ2");
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
    function setUnstakingLockTime(uint256 unstakingLockTime) public virtual returns (bool success) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ3");
        _unstakingLockTime = unstakingLockTime;
        emit SetUnstakingLockTime(unstakingLockTime);
        return true;
    }

    /**
     * @dev get fees, min values, value divisor and epoch props
     *
     */
    function getStakeUnstakeProps() public view virtual returns (
        uint256 stakeFee, uint256 unstakeFee, uint256 minStake, uint256 minUnstake, uint256 valueDivisor,
        uint256 epochInterval, uint256 unstakeEpoch, uint256 unstakeEpochPrevious, uint256 unstakingLockTime
    ) {
        stakeFee = _stakeFee;
        unstakeFee = _unstakeFee;
        minStake = _minStake;
        minUnstake = _minStake;
        valueDivisor = _valueDivisor;
        epochInterval= _epochInterval;
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
    function setMinimumValues(uint256 minStake, uint256 minUnstake) public virtual returns (bool success){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ4");
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
    function setUnstakeEpoch(uint256 unstakeEpoch, uint256 unstakeEpochPrevious, uint256 epochInterval) public virtual returns (bool success){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ5");
        require(unstakeEpochPrevious <= unstakeEpoch, "LQ6");
        if(unstakeEpoch == 0 && epochInterval != 0) revert("LQ7");
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
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ8");
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
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ9");
        _sTokens = ISTokens(sAddress);
        emit SetSTokensContract(sAddress);
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
    function stake(address to, uint256 amount) public virtual override whenNotPaused returns(bool)  {
        // Check the supplied amount is greater than minimum stake value
        require(to == _msgSender(), "LQ11");
        // Check the current balance for uTokens is greater than the amount to be staked
        uint256 _currentUTokenBalance = _uTokens.balanceOf(to);
        uint256 _finalTokens = amount.add((amount.mul(_stakeFee)).div(_valueDivisor.mul(100)));
        // the value which should be greater than or equal to _minStake
        // is amount since minval applies to number of sTokens to be minted
        require(amount >= _minStake, "LQ10");
        // uint256 finalTokens = (((amount.mul(100)).mul(_valueDivisor)).sub(_stakeFee)).div(_valueDivisor.mul(100));
        require(_currentUTokenBalance >= _finalTokens, "LQ12");
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
    function unStake(address to, uint256 amount) public virtual override whenNotPaused returns(bool) {
        // Check the supplied amount is greater than 0
        require(to == _msgSender(), "LQ13");
        require(_unstakeEpoch!=0, "LQ15");
        require(_unstakeEpochPrevious!=0, "LQ16");
        // Check the current balance for sTokens is greater than the amount to be unStaked
        uint256 _currentSTokenBalance = _sTokens.balanceOf(to);
        uint256 _finalTokens = amount.add((amount.mul(_unstakeFee)).div(_valueDivisor.mul(100)));
        // the value which should be greater than or equal to _minSUnstake
        // is amount since minval applies to number of uTokens to be withdrawn
        require(amount >= _minUnstake, "LQ14");
        require(_currentSTokenBalance >= _finalTokens, "LQ17");
        // uint256 _finalTokens = (((amount.mul(100)).mul(_valueDivisor)).sub(_unstakeFee)).div(_valueDivisor.mul(100));
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
    function getUnstakeEpochMilestone(uint256 _unstakeTimestamp) public view virtual returns (uint256 unstakeEpochMilestone) {
        if(_unstakeTimestamp == 0) return 0;
        // if epoch values are not relevant, then the epoch milestone is the unstake timestamp itself (backward compatibility)
        if((_unstakeEpoch == 0 && _unstakeEpochPrevious == 0) || _epochInterval == 0) return _unstakeTimestamp;
        if(_unstakeEpoch > _unstakeTimestamp) return (_unstakeEpoch);
        uint256 _referenceStartTime = (_unstakeTimestamp).add(_unstakeEpoch.sub(_unstakeEpochPrevious));
        uint256 _timeDiff = _referenceStartTime.sub(_unstakeEpoch);
        unstakeEpochMilestone = (_timeDiff.mod(_epochInterval)).add(_referenceStartTime);
        return (unstakeEpochMilestone);
    }

    /**
     * @dev returns the time left for unbonding to finish
     */
    function getUnstakeTime(uint256 _unstakeTimestamp) public view virtual returns (uint256 unstakeTime ,uint256 unstakeEpoch, uint256 unstakeEpochPrevious) {
        uint256 _unstakeEpochMilestone = getUnstakeEpochMilestone(_unstakeTimestamp);
        if(_unstakeEpochMilestone == 0) return (0, unstakeEpoch, unstakeEpochPrevious);
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
    function withdrawUnstakedTokens(address staker) public virtual override whenNotPaused{
        require(staker == _msgSender(), "LQ18");
        uint256 _withdrawBalance;
        uint256 _unstakingExpirationLength = _unstakingExpiration[staker].length;
        for (uint256 i=_withdrawCounters[_msgSender()]; i<_unstakingExpirationLength; i=i.add(1)) {
            //get getUnstakeTime and compare it with current timestamp to check if 21 days + epoch difference has passed
            (uint256 _getUnstakeTime, , ) = getUnstakeTime(_unstakingExpiration[staker][i]);
            if (block.timestamp >= _getUnstakeTime) {
                //if 21 days + epoch difference has passed, then add the balance and then mint uTokens
                _withdrawBalance = _withdrawBalance.add(_unstakingAmount[staker][i]);
                _unstakingExpiration[staker][i] = 0;
                _unstakingAmount[staker][i] = 0;
                _withdrawCounters[_msgSender()]++;
            }
        }
        require(_withdrawBalance > 0, "LQ19");
        emit WithdrawUnstakeTokens(staker, _withdrawBalance, block.timestamp);
        _uTokens.mint(_msgSender(), _withdrawBalance);
    }

    /**
     * @dev get Total Unbonded Tokens
     * @param staker: account address
     *
     */
    function getTotalUnbondedTokens(address staker) public view virtual returns (uint256 unbondingTokens) {
        uint256 _unstakingExpirationLength = _unstakingExpiration[staker].length;
            for (uint256 i=_withdrawCounters[staker]; i<_unstakingExpirationLength; i=i.add(1)) {
                //get getUnstakeTime and compare it with current timestamp to check if 21 days + epoch difference has passed
                (uint256 _getUnstakeTime, , ) = getUnstakeTime(_unstakingExpiration[staker][i]);
                if (block.timestamp >= _getUnstakeTime) {
                    //if 21 days + epoch difference has passed, then check the token amount and send back
                    unbondingTokens = unbondingTokens.add(_unstakingAmount[staker][i]);
                }
            }
        return unbondingTokens;
    }

    /**
      * @dev Triggers stopped state.
      *
      * Requirements:
      *
      * - The contract must not be paused.
      */
    function pause() public virtual returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "LQ20");
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
        require(hasRole(PAUSER_ROLE, _msgSender()), "LQ21");
        _unpause();
        return true;
    }
}