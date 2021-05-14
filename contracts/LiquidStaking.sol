// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./interfaces/ISTokens.sol";
import "./interfaces/IUTokens.sol";
import "./interfaces/ILiquidStaking.sol";
import "./interfaces/ITokenWrapper.sol";

contract LiquidStaking is ILiquidStaking, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;

    //Private instances of contracts to handle Utokens and Stokens
    IUTokens private _uTokens;
    ISTokens private _sTokens;
    ITokenWrapper private _tokenWrapper;

    // defining the fees and minimum values
    uint256 private _minStake;
    uint256 private _minUnstake;
    uint256 private _stakeFee;
    uint256 private _unstakeFee;
    uint256 private _feeDivisor;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 _unstakinglockTime;
    uint256 _epochInterval;
    uint256 _unstakeEpoch;

    //Mapping to handle the Expiry period
    mapping(address => uint256[]) _unstakingExpiration;

    //Mapping to handle the Expiry amount
    mapping(address => uint256[]) _unstakingAmount;

    /**
   * @dev Constructor for initializing the LiquidStaking contract.
   * @param uAddress - address of the UToken contract.
   * @param sAddress - address of the SToken contract.
   * @param wrapperAddress - address of the tokenWrapper contract.
   * @param pauserAddress - address of the pauser admin.
   */
    function initialize(address uAddress, address sAddress, address wrapperAddress, address pauserAddress, uint256 feeDivisor) public virtual initializer  {
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, pauserAddress);
        setUTokensContract(uAddress);
        setSTokensContract(sAddress);
        setWrapperContract(wrapperAddress);
        _unstakinglockTime = 21 days;
        _epochInterval = 3 days;
        _feeDivisor = feeDivisor;
    }

    /**
     * @dev Set 'fees', called from admin
     * @param stakeFee: stake fee
     * @param unstakeFee: unstake fee
     *
     * Emits a {SetFee} event with 'fee' set to the stake and unstake.
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
     * @dev get fees
     *
     */
    function getFeesAndMinimumValues() public view virtual returns (uint256 stakeFee, uint256 unstakeFee, uint256 minStake, uint256 minUnstake) {
        stakeFee = _stakeFee;
        unstakeFee = _unstakeFee;
        minStake = _minStake;
        minUnstake = _minStake;
        return (stakeFee, unstakeFee, minStake, minUnstake);
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
    *
    * Emits a {SetUnstakeEpoch} event with 'unstakeEpoch'
    *
    */
    function setUnstakeEpoch(uint256 unstakeEpoch) public virtual returns (bool success){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LiquidStaking: User not authorised to set unstake epoch");
        _unstakeEpoch = unstakeEpoch;
        emit SetUnstakeEpoch(unstakeEpoch);
        return true;
    }

    /**
     * @dev Set 'contract address', called from constructor
     * @param uAddress: utoken contract address
     *
     * Emits a {SetContract} event with '_contract' set to the utoken contract address.
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
     * Emits a {SetContract} event with '_contract' set to the stoken contract address.
     *
     */
    function setSTokensContract(address sAddress) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LiquidStaking: User not authorised to set SToken contract");
        _sTokens = ISTokens(sAddress);
        emit SetSTokensContract(sAddress);
    }
    /*
    * @dev Set 'contract address', called from constructor
    * @param sAddress: stoken contract address
    *
    * Emits a {SetContract} event with '_contract' set to the stoken contract address.
    *
    */
    function setWrapperContract(address wrapperAddress) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LiquidStaking: User not authorised to set wrapper contract");
        _tokenWrapper = ITokenWrapper(wrapperAddress);
        emit SetWrapperContract(wrapperAddress);
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
        // Check the supplied amount is greater than 0
        require(utok>_minStake, "LiquidStaking: Requires a min stake amount");
        require(to == _msgSender(), "LiquidStaking: Staking can only be done by Staker");
        // require(hasRole(STAKER_ROLE, _msgSender()), "LiquidStaking: Staking can only be done by Staker");
        // Check the current balance for uTokens is greater than the amount to be staked
        uint256 _currentUTokenBalance = _uTokens.balanceOf(to);
        require(_currentUTokenBalance>=utok, "LiquidStaking: Insuffcient balance for account");
        uint256 finalTokens = (((utok.mul(100)).mul(_feeDivisor)).sub(_stakeFee)).div(_feeDivisor.mul(100));
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
        // Check the current balance for sTokens is greater than the amount to be unStaked
        uint256 _currentSTokenBalance = _sTokens.balanceOf(to);
        require(_currentSTokenBalance>=stok, "LiquidStaking: Insuffcient balance for account");
        uint256 finalTokens = (((stok.mul(100)).mul(_feeDivisor)).sub(_unstakeFee)).div(_feeDivisor.mul(100));
        // Burn the sTokens as specified with the amount
        _sTokens.burn(to, stok);
        uint256 _unstakeEpochTime = getUnstakeEpochTime();
        _unstakingExpiration[to].push((_unstakeEpochTime + block.timestamp) + _unstakinglockTime);
        _unstakingAmount[to].push(finalTokens);
        emit UnstakeTokens(to, finalTokens, (_unstakeEpochTime + block.timestamp) + _unstakinglockTime);
        return true;
    }

    /**
     * @dev get unstake epoch time
     */
    function getUnstakeEpochTime() public view virtual returns (uint256 unstakeEpochTime_) {
        uint256 _currentTime = block.timestamp;
        if(_unstakeEpoch > _currentTime) return (_unstakeEpoch.sub(_currentTime));

        uint256 _timeDiff = _currentTime.sub(_unstakeEpoch);
        unstakeEpochTime_ = _timeDiff.mod(_epochInterval);
        return unstakeEpochTime_;
    }

    /**
     * @dev Lock the unstaked tokens for 21 days, user can withdraw the same (Mint uTokens with 21 days locking period)
     *
     * Requirements:
     *
     * - `current block timestamp` should be after 21 days from the period where unstaked function is called.
     */
    function withdrawUnstakedTokens(address staker) public virtual override whenNotPaused{
        require(staker == _msgSender(), "LiquidStaking: Only staker can withdraw");
        // require(hasRole(STAKER_ROLE, _msgSender()), "LiquidStaking: Only staker can withdraw");
        uint256 _withdrawBalance;
        for (uint256 i=0; i<_unstakingExpiration[staker].length; i=i.add(1)) {
            if (block.timestamp > _unstakingExpiration[staker][i]) {
                _withdrawBalance = _withdrawBalance.add(_unstakingAmount[staker][i]);
                _unstakingExpiration[staker][i] = 0;
                _unstakingAmount[staker][i] = 0;
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
        if(staker == _msgSender()){
            for (uint256 i=0; i<_unstakingExpiration[staker].length; i=i.add(1)) {
                if (block.timestamp > _unstakingExpiration[staker][i]) {
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