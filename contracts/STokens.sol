// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/ISTokens.sol";
import "./interfaces/IUTokens.sol";

contract STokens is ERC20Upgradeable, ISTokens, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address private _liquidStakingContract;

    //Private instance of contract to handle Utokens
    IUTokens private _uTokens;


    uint256[] private _rewardRate;
    uint256[] private _rewardBlockTimestamp;
    uint256 private _valueDivisor;

    mapping(address => uint256) private _rewardsTillTimestamp;

    /**
   * @dev Constructor for initializing the SToken contract.
   * @param uaddress - address of the UToken contract.
   * @param pauserAddress - address of the pauser admin.
   * @param rewardRate - set rewardRate.
   * @param valueDivisor - valueDivisor set to 10^9.
   */
    function initialize(address uaddress, address pauserAddress, uint256 rewardRate, uint256 valueDivisor) public virtual initializer {
        __ERC20_init("pSTAKE Staked ATOMs", "stkATOMs");
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, pauserAddress);
        setUTokensContract(uaddress);
        // to set reward rate to 5e-3 or 0.005
        _rewardRate.push(rewardRate);
        _rewardBlockTimestamp.push(block.timestamp);
        _valueDivisor = valueDivisor;
        _setupDecimals(6);
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
    function setRewardRate(uint256 rewardRate) public virtual override returns (bool success) {
        require(rewardRate>0, "STokens: Reward rate should be greater than 0");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to set reward rate");
        _rewardRate.push(rewardRate);
        _rewardBlockTimestamp.push(block.timestamp);
        return true;
    }

    /**
    * @dev get reward rate and value divisor
    */
    function getRewardRate() public view virtual returns (uint256[] memory rewardRate, uint256 valueDivisor) {
        rewardRate = _rewardRate;
        valueDivisor = _valueDivisor;
    }

    /**
     * @dev get rewards till timestamp
     * @param to: account address
     */
    function getRewardsTillTimestamp(address to) public view virtual returns (uint256 rewardsTillTimestamp) {
        rewardsTillTimestamp = _rewardsTillTimestamp[to];
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
    function mint(address to, uint256 tokens) public virtual override returns (bool success) {
        require(tx.origin == to && _msgSender() == _liquidStakingContract, "STokens: User not authorised to mint STokens");
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
    function burn(address from, uint256 tokens) public  virtual override returns (bool success) {
        require(tx.origin == from && _msgSender() == _liquidStakingContract, "STokens: User not authorised to burn STokens");
        _burn(from, tokens);
        return true;
    }

    /**
     * @dev Calculate rewards for the provided 'address'
     * @param to: account address
     */
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
        _rewardsTillTimestamp[to] = block.timestamp;
        return _reward;
    }

    /**
     * @dev Calculate pending rewards for the provided 'address'
     * @param to: account address
     */
    function calculatePendingRewards(address to) public view virtual returns (uint256 pendingRewards){
        // Get the time in number of blocks
        uint256 _lastRewardTimestamp = _rewardsTillTimestamp[to];
        // Get the balance of the account
        uint256 _balance = balanceOf(to);
        uint256 _index;
        uint256 _rewardBlock;
        uint256 _simpleInterestOfInterval;
        for(_index = _rewardBlockTimestamp.length.sub(1); _index >= 0;){
            // logic applies for all indexes of array except last index
            if(_index < _rewardBlockTimestamp.length.sub(1)) {
                if(_rewardBlockTimestamp[_index] > _lastRewardTimestamp) {
                    _rewardBlock = (_rewardBlockTimestamp[_index.add(1)]).sub(_rewardBlockTimestamp[_index]);
                    _simpleInterestOfInterval = (((_balance.mul(_rewardRate[_index])).mul(_rewardBlock))).div(100 * _valueDivisor);
                    pendingRewards = pendingRewards.add(_simpleInterestOfInterval);
                }
                else {
                    _rewardBlock = (_rewardBlockTimestamp[_index.add(1)]).sub(_lastRewardTimestamp);
                    _simpleInterestOfInterval = (((_balance.mul(_rewardRate[_index])).mul(_rewardBlock))).div(100 * _valueDivisor);
                    pendingRewards = pendingRewards.add(_simpleInterestOfInterval);
                    break;
                }
            }
            // logic applies only for the last index of array
            else {
                if(_rewardBlockTimestamp[_index] > _lastRewardTimestamp) {
                    _rewardBlock = (block.timestamp).sub(_rewardBlockTimestamp[_index]);
                    _simpleInterestOfInterval = (((_balance.mul(_rewardRate[_index])).mul(_rewardBlock))).div(100 * _valueDivisor);
                    pendingRewards = pendingRewards.add(_simpleInterestOfInterval);
                }
                else {
                    _rewardBlock = (block.timestamp).sub(_lastRewardTimestamp);
                    _simpleInterestOfInterval = (((_balance.mul(_rewardRate[_index])).mul(_rewardBlock))).div(100 * _valueDivisor);
                    pendingRewards = pendingRewards.add(_simpleInterestOfInterval);
                    break;
                }
            }

            if(_index == 0) break;
            else {
                _index = _index.sub(1);
            }
        }
        return pendingRewards;
    }

    /**
     * @dev Calculate rewards for the provided 'address'
     * @param to: account address
     *
     * Emits a {TriggeredCalculateRewards} event with 'to' set to address, 'reward' set to amount of tokens and 'timestamp'
     *
     */
    function calculateRewards(address to) public virtual override whenNotPaused returns (bool success) {
        require(to == _msgSender(), "STokens: only staker can initiate their own rewards calculation");
        uint256 reward =  _calculateRewards(to);
        emit TriggeredCalculateRewards(to, reward, block.timestamp);
        return true;
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!paused(), "STokens: token transfer while paused");
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

    /*
    * @dev Set 'contract address', called from constructor
    * @param uTokenContract: utoken contract address
    *
    * Emits a {SetUTokensContract} event with '_contract' set to the utoken contract address.
    *
    */
    function setUTokensContract(address uTokenContract) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to set UToken contract address");
        _uTokens = IUTokens(uTokenContract);
        emit SetUTokensContract(uTokenContract);
    }

    /*
     * @dev Set 'contract address', called from constructor
     * @param liquidStakingContract: liquidStaking contract address
     *
     * Emits a {SetLiquidStakingContract} event with '_contract' set to the liquidStaking contract address.
     *
     */
    //This function need to be called after deployment, only admin can call the same
    function setLiquidStakingContract(address liquidStakingContract) public virtual override{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to set liquidStaking contract");
        _liquidStakingContract = liquidStakingContract;
        emit SetLiquidStakingContract(liquidStakingContract);
    }

    /**
      * @dev Triggers stopped state.
      *
      * Requirements:
      *
      * - The contract must not be paused.
      */
    function pause() public virtual returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "STokens: User not authorised to pause contracts.");
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
        require(hasRole(PAUSER_ROLE, _msgSender()), "STokens: User not authorised to unpause contracts.");
        _unpause();
        return true;
    }
}