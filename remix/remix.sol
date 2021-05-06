/*
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/ERC20Upgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/math/SafeMathUpgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/security/PausableUpgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/access/AccessControlUpgradeable.sol";

interface IUTokens is IERC20Upgradeable {

    */
/**
     * @dev Mints `amount` tokens to the caller's address `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *//*

    function mint(address to, uint256 tokens) external returns (bool);

    */
/**
     * @dev Burns `amount` tokens to the caller's address `from`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *//*

    function burn(address from, uint256 tokens) external returns (bool);

    */
/**
    * @dev Set LiquidStaking smart contract.
    *//*

    function setLiquidStakingContract(address liquidStakingContract) external;

    */
/**
     * @dev Set STokens smart contract.
     *//*

    function setSTokenContract(address stokenContract) external;

    */
/**
     * @dev Set PegTokens smart contract.
     *//*

    function setWrapperContract(address wrapperTokensContract) external;

    */
/**
     * @dev Emitted when contract addresses are set
     *//*

    event SetSTokensContract( address indexed _contract );


    */
/**
     * @dev Emitted when contract addresses are set
     *//*

    event SetWrapperContract( address indexed _contract );


    */
/**
     * @dev Emitted when contract addresses are set
     *//*

    event SetLiquidStakingContract( address indexed _contract );
}

interface ISTokens is IERC20Upgradeable {

    */
/**
     * @dev Mints `amount` tokens to the caller's address `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *//*

    function mint(address to, uint256 tokens) external returns (bool);

    */
/**
     * @dev Burns `amount` tokens to the caller's address `from`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *//*

    function burn(address from, uint256 tokens) external returns (bool);

    */
/**
      * @dev Returns the reward rate set by the admin.
      *//*

    function getRewardRate() external view returns (uint256[] memory, uint256);

    */
/**
    * @dev Returns the staked block of the user's address.
    *//*

    function getStakedBlock(address to) external view returns (uint256);

    */
/**
     * @dev Sets `reward rate`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *//*

    function setRewardRate(uint256 rate) external returns (bool);

    */
/**
   * @dev Calculates rewards `amount` tokens to the caller's address `to`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {TriggeredCalculateRewards} event.
   *//*

    function calculateRewards(address to) external returns (bool);

    */
/**
     * @dev Set UTokens smart contract.
     *
     *
     * Emits a {SetContract} event.
     *//*

    function setUTokensContract(address utokenContract) external;

    */
/**
     * @dev Set Wrapper smart contract.
     *//*

    function setWrapperContract(address wrapperContract) external;

    */
/**
    * @dev Set LiquidStaking smart contract.
    *//*

    function setLiquidStakingContract(address liquidStakingContract) external;

    */
/**
     * @dev Emitted when contract addresses are set
     *//*

    event SetUTokensContract( address indexed _contract );


    */
/**
     * @dev Emitted when contract addresses are set
     *//*

    event SetWrapperContract( address indexed _contract );


    */
/**
     * @dev Emitted when contract addresses are set
     *//*

    event SetLiquidStakingContract( address indexed _contract );

    */
/**
     * @dev Emitted when `rewards` tokens are moved to account
     *
     * Note that `value` may be zero.
     *//*

    event CalculateRewards(address indexed accountAddress, uint256 tokens, uint256 timestamp);

    */
/**
     * @dev Emitted when `rewards` tokens are moved to account
     *
     * Note that `value` may be zero.
     *//*

    event TriggeredCalculateRewards(address indexed accountAddress, uint256 tokens, uint256 timestamp);


}


contract STokens is ERC20Upgradeable, ISTokens, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address private _liquidStakingContract;
    address private _wrapperContract;

    //Private instance of contract to handle Utokens
    IUTokens private _uTokens;


    uint256[] private _rewardRate;
    uint256[] private _rewardBlockNumber;
    uint256 private _rewardDivisor;

    mapping(address => uint256) private _stakedBlocks;

    */
/**
   * @dev Constructor for initializing the SToken contract.
   * @param pauserAddress - address of the pauser admin.
   *//*

    function initialize( address pauserAddress, uint256 rewardRate) public virtual initializer {
        __ERC20_init("pSTAKE Staked ATOMs", "stkATOMs");
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, pauserAddress);
        // setUTokensContract(uaddress);
        // to set reward rate to 5e-3 or 0.005
        _rewardRate.push(rewardRate);
        _rewardBlockNumber.push(block.number);
        _rewardDivisor = 10**9;
        // _setupDecimals(6);
    }

    */
/*
    * @dev set reward rate
    * @param rate: reward rate
    *
    *
    * Requirements:
    *
    * - `rate` cannot be less than or equal to zero.
    *
    *//*

    function setRewardRate(uint256 rewardRate) public virtual override returns (bool success) {
        require(rewardRate>0, "STokens: Reward rate should be greater than 0");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to set reward rate");
        _rewardRate.push(rewardRate);
        _rewardBlockNumber.push(block.number);
        return true;
    }

    */
/**
    * @dev get reward rate
    *//*

    function getRewardRate() public view virtual override returns (uint256[] memory rewardRate, uint256 rewardDivisor) {
        rewardRate = _rewardRate;
        rewardDivisor = _rewardDivisor;
        return (rewardRate, rewardDivisor);
    }

    */
/**
     * @dev get staked block
     * @param to: account address
     *//*

    function getStakedBlock(address to) public view virtual override returns (uint256 stakedBlocks) {
        stakedBlocks = _stakedBlocks[to];
        return stakedBlocks;
    }

    */
/**
     * @dev Mint new stokens for the provided 'address' and 'amount'
     * @param to: account address, amount: number of tokens
     *
     * Emits a {MintTokens} event with 'to' set to address and 'amount' set to amount of tokens.
     *
     * Requirements:
     *
     * - `amount` cannot be less than zero.
     *
     *//*

    function mint(address to, uint256 tokens) public virtual override whenNotPaused returns (bool success) {
        // require(tx.origin == to && _msgSender() == _liquidStakingContract, "STokens: User not authorised to mint STokens");
        _mint(to, tokens);
        return true;
    }

    */
/*
     * @dev Burn stokens for the provided 'address' and 'amount'
     * @param to: account address, amount: number of tokens
     *
     * Emits a {BurnTokens} event with 'to' set to address and 'amount' set to amount of tokens.
     *
     * Requirements:
     *
     * - `amount` cannot be less than zero.
     *
     *//*

    function burn(address from, uint256 tokens) public  virtual override whenNotPaused returns (bool success) {
        //  require(tx.origin == from && _msgSender() == _liquidStakingContract, "STokens: User not authorised to burn STokens");
        _burn(from, tokens);
        return true;
    }

    */
/**
     * @dev Calculate rewards for the provided 'address'
     * @param to: account address
     *//*

    function _calculateRewards(address to) internal returns (uint256){
        // Calculate the rewards pending
        uint256 _reward = calculatePendingRewards(to);
        // mint uTokens only if reward is greater than zero
        if(_reward>0) {
            // Mint new uTokens and send to the callers account
            emit CalculateRewards(to, _reward, block.timestamp);
            _uTokens.mint(to, _reward);
        }
        // Set the new stakedBlock to the current
        _stakedBlocks[to] = block.number;
        return _reward;
    }

    */
/**
     * @dev Calculate pending rewards for the provided 'address'
     * @param to: account address
     *//*

    function calculatePendingRewards(address to) public view virtual returns (uint256 pendingRewards){
        // Get the current Block
        //uint256 _currentBlock = block.number;
        // Get the time in number of blocks
        uint256 _lastRewardBlockNumber = _stakedBlocks[to];

        // uint256 _rewardBlock = _currentBlock.sub(_stakedBlocks[to], "STokens: Error in subtraction");
        // Get the balance of the account
        uint256 _balance = balanceOf(to);
        uint256 _index;
        uint256 _rewardBlock;
        uint256 _simpleInterestOfInterval;

        for(_index=_rewardBlockNumber.length-1; _index>0; _index--){
            if(_rewardBlockNumber[_index] > _lastRewardBlockNumber) {
                _index = _index.add(1);
                break;
            }
        }

        if(_index == _rewardBlockNumber.length) {
            _rewardBlock = _lastRewardBlockNumber.sub(_rewardBlockNumber[_index.sub(1)]);
            _simpleInterestOfInterval = (_balance * _rewardRate[_index.sub(1)] * _rewardBlock) / (100 * _rewardDivisor);
            pendingRewards = _simpleInterestOfInterval;
            return pendingRewards;
        }

        for(; _index< _rewardBlockNumber.length; _index++){
            // Calculate the interest if P, R, T are non zero values
            _rewardBlock = _rewardBlockNumber[_index].sub(_lastRewardBlockNumber);
            _lastRewardBlockNumber = _rewardBlockNumber[_index];
            if(_balance > 0 && _rewardBlockNumber[_index] > 0 && _rewardBlock > 0) {
                // calculate the simple interest for that particular interval
                _simpleInterestOfInterval = (_balance * _rewardRate[_index] * _rewardBlock) / (100 * _rewardDivisor);
                pendingRewards = pendingRewards.add(_simpleInterestOfInterval);
            }

        }

        return pendingRewards;
    }

    */
/**
     * @dev Calculate rewards for the provided 'address'
     * @param to: account address
     *
     * Emits a {TriggeredCalculateRewards} event with 'to' set to address, 'reward' set to amount of tokens and 'timestamp'
     *
     *//*

    function calculateRewards(address to) public virtual override whenNotPaused returns (bool success) {
        require(to == _msgSender(), "STokens: only staker can initiate their own rewards calculation");
        uint256 reward =  _calculateRewards(to);
        emit TriggeredCalculateRewards(to, reward, block.timestamp);
        return true;
    }

    */
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
     *//*

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!paused(), "ERC20Pausable: token transfer while paused");
        super._beforeTokenTransfer(from, to, amount);
        if (from != address(0))
        {
            _calculateRewards(from);
        }
        if (to != address(0))
        {
            _calculateRewards(to);
        }
    }

    */
/*
    * @dev Set 'contract address', called from constructor
    * @param uTokenContract: utoken contract address
    *
    * Emits a {SetContract} event with '_contract' set to the utoken contract address.
    *
    *//*

    function setUTokensContract(address uTokenContract) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to set UToken contract address");
        _uTokens = IUTokens(uTokenContract);
        emit SetUTokensContract(uTokenContract);
    }

    */
/*
     * @dev Set 'contract address', called from constructor
     * @param liquidStakingContract: liquidStaking contract address
     *
     * Emits a {SetContract} event with '_contract' set to the liquidStaking contract address.
     *
     *//*

    //This function need to be called after deployment, only admin can call the same
    function setLiquidStakingContract(address liquidStakingContract) public virtual override{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to set liquidStaking contract");
        _liquidStakingContract = liquidStakingContract;
        emit SetLiquidStakingContract(liquidStakingContract);
    }

    */
/*
     * @dev Set 'contract address', called from constructor
     * @param wrapperContract: wrapperContract contract address
     *
     * Emits a {SetContract} event with '_contract' set to the wrapper contract address.
     *
     *//*

    function setWrapperContract(address wrapperContract) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to set wrapper contract");
        _wrapperContract = wrapperContract;
        emit SetWrapperContract(wrapperContract);
    }

    */
/**
      * @dev Triggers stopped state.
      *
      * Requirements:
      *
      * - The contract must not be paused.
      *//*

    function pause() public virtual returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "STokens: User not authorised to pause contracts.");
        _pause();
        return true;
    }

    */
/**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     *//*

    function unpause() public virtual returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "STokens: User not authorised to unpause contracts.");
        _unpause();
        return true;
    }
}*/
