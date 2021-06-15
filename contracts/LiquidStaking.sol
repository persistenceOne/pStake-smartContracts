// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

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
   * @param valueDivisor - valueDivisor set to 10^9.
   */
    function initialize(address uAddress, address sAddress, address pauserAddress, uint256 valueDivisor) public virtual initializer  {
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, pauserAddress);
        setUTokensContract(uAddress);
        setSTokensContract(sAddress);
        _unstakingLockTime = 21 hours;
        _epochInterval = 3 hours;
        _valueDivisor = valueDivisor;
        _unstakeEpoch = 1623840663;
        _unstakeEpochPrevious = 1623840663;
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
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LiquidStaking: User not authorised to set fees");
        _stakeFee = stakeFee;
        _unstakeFee = unstakeFee;
        emit SetFees(stakeFee, unstakeFee);
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
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LiquidStaking: User not authorised to set minimum values");
        _minStake = minStake;
        _minUnstake = minUnstake;
        emit SetMinimumValues(minStake, minUnstake);
        return true;
    }

    /**
    * @dev Set 'unstake epoch', called from admin
    * @param unstakeEpoch: unstake epoch
    * @param unstakeEpochPrevious: unstake epoch previous(initially set to same value as unstakeEpoch)
    *
    * Emits a {SetUnstakeEpoch} event with 'unstakeEpoch'
    *
    */
    function setUnstakeEpoch(uint256 unstakeEpoch, uint256 unstakeEpochPrevious) public virtual returns (bool success){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LiquidStaking: User not authorised to set unstake epoch");
        _unstakeEpoch = unstakeEpoch;
        _unstakeEpochPrevious = unstakeEpochPrevious;
        emit SetUnstakeEpoch(unstakeEpoch, unstakeEpochPrevious);
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
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LiquidStaking: User not authorised to set UToken contract");
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
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LiquidStaking: User not authorised to set SToken contract");
        _sTokens = ISTokens(sAddress);
        emit SetSTokensContract(sAddress);
    }

    /**
    * @dev Stake utokens over the platform with address 'to' for desired 'utok'(Burn uTokens and Mint sTokens)
    * @param to: user address for staking, utok: number of tokens to stake
    *
    *
    * Requirements:
    *
    * - `utok` cannot be less than zero.
    * - 'utok' cannot be more than balance
    * - 'utok' plus new balance should be equal to the old balance
    */
    function stake(address to, uint256 utok) public virtual override whenNotPaused returns(bool)  {
        // Check the supplied amount is greater than minimum stake value
        require(utok>_minStake, "LiquidStaking: Requires a min stake amount");
        require(to == _msgSender(), "LiquidStaking: Staking can only be done by Staker");
        // Check the current balance for uTokens is greater than the amount to be staked
        uint256 _currentUTokenBalance = _uTokens.balanceOf(to);
        require(_currentUTokenBalance>=utok, "LiquidStaking: Insuffcient balance for account");
        uint256 finalTokens = (((utok.mul(100)).mul(_valueDivisor)).sub(_stakeFee)).div(_valueDivisor.mul(100));
        emit StakeTokens(to, finalTokens, block.timestamp);
        // Burn the uTokens as specified with the amount
        _uTokens.burn(to, utok);
        // Mint the sTokens for the account specified
        _sTokens.mint(to, finalTokens);
        return true;
    }

    /**
     * @dev UnStake stokens over the platform with address 'to' for desired 'stok' (Burn sTokens and Mint uTokens with 21 days locking period)
     * @param to: user address for staking, stok: number of tokens to unstake
     *
     *
     * Requirements:
     *
     * - `stok` cannot be less than zero.
     * - 'stok' cannot be more than balance
     * - 'stok' plus new balance should be equal to the old balance
     */
    function unStake(address to, uint256 stok) public virtual override whenNotPaused returns(bool) {
        // Check the supplied amount is greater than 0
        require(to == _msgSender(), "LiquidStaking: Unstaking can only be done by Stakerr");
        require(stok>_minUnstake, "LiquidStaking: Requires a min unstake amount");
        require(_unstakeEpoch!=0, "LiquidStaking: unstake epoch not set");
        require(_unstakeEpochPrevious!=0, "LiquidStaking: unstake epoch previous not set");
        // Check the current balance for sTokens is greater than the amount to be unStaked
        uint256 _currentSTokenBalance = _sTokens.balanceOf(to);
        require(_currentSTokenBalance>=stok, "LiquidStaking: Insuffcient balance for account");
        uint256 finalTokens = (((stok.mul(100)).mul(_valueDivisor)).sub(_unstakeFee)).div(_valueDivisor.mul(100));
        // Burn the sTokens as specified with the amount
        _sTokens.burn(to, stok);
        _unstakingExpiration[to].push(block.timestamp);
        _unstakingAmount[to].push(finalTokens);
        emit UnstakeTokens(to, finalTokens, block.timestamp);

        return true;
    }

    /**
     * @dev returns the nearest epoch milestone in the future
     */
    function getUnstakeEpochMilestone(uint256 _unstakeTimestamp) public view virtual returns (uint256 unstakeEpochMilestone) {
        if(_unstakeTimestamp == 0) return 0;
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
        //adding 21 days with epoch difference
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
        require(staker == _msgSender(), "LiquidStaking: Only staker can withdraw");
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
        require(_withdrawBalance > 0, "LiquidStaking: UnStaking period still pending");
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
        if(staker == _msgSender()){
            for (uint256 i=0; i<_unstakingExpirationLength; i=i.add(1)) {
                //get getUnstakeTime and compare it with current timestamp to check if 21 days + epoch difference has passed
                (uint256 _getUnstakeTime, , ) = getUnstakeTime(_unstakingExpiration[staker][i]);
                if (block.timestamp >= _getUnstakeTime) {
                    //if 21 days + epoch difference has passed, then check the token amount and send back
                    unbondingTokens = unbondingTokens.add(_unstakingAmount[staker][i]);
                }
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
        require(hasRole(PAUSER_ROLE, _msgSender()), "LiquidStaking: User not authorised to pause contracts.");
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
        require(hasRole(PAUSER_ROLE, _msgSender()), "LiquidStaking: User not authorised to unpause contracts.");
        _unpause();
        return true;
    }
}