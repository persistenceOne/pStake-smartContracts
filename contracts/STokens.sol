// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./ISTokens.sol";
import "./IUTokens.sol";

contract STokens is ERC20Upgradeable, ISTokens, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address private _liquidStakingContract;
    address private _wrapperContract;

    //Private instance of contract to handle Utokens
    IUTokens private _uTokens;


    uint256 private _rewardRate;
    mapping(address => uint256) private _stakedBlocks;

    function initialize(address uaddress, address pauserAddress) public virtual initializer {
        __ERC20_init("pSTAKE Staked ATOM", "stkATOM");
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, pauserAddress);
        setUTokensContract(uaddress);
        _rewardRate = 1;
        _setupDecimals(6);
    }

    function setUTokensContract(address uTokenContract) public virtual override whenNotPaused{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to set UToken contract address");
        _uTokens = IUTokens(uTokenContract);
        emit SetContract(uTokenContract);
    }

    function setRewardRate(uint256 rate) public virtual override whenNotPaused returns (bool success) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to set reward rate");
        _rewardRate = rate;
        return true;
    }

    function getRewardRate() public view virtual override whenNotPaused returns (uint256 rewardRate) {
        rewardRate = _rewardRate;
        return rewardRate;
    }

    function getStakedBlock(address to) public view virtual override whenNotPaused returns (uint256 stakedBlocks) {
        stakedBlocks = _stakedBlocks[to];
        return stakedBlocks;
    }


    function mint(address to, uint256 tokens) public virtual override whenNotPaused returns (bool success) {
        require(tx.origin == to && _msgSender() == _liquidStakingContract, "STokens: User not authorised to mint STokens");
        _mint(to, tokens);
        return true;
    }

    function burn(address from, uint256 tokens) public  virtual override whenNotPaused returns (bool success) {
        require(tx.origin == from && _msgSender() == _liquidStakingContract, "STokens: User not authorised to burn STokens");
        _burn(from, tokens);
        return true;
    }

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

    function calculatePendingRewards(address to) public view virtual override whenNotPaused returns (uint256 pendingRewards){
        // Get the current Block
        uint256 _currentBlock = block.number;
        // Get the time in number of blocks
        uint256 _rewardBlock = _currentBlock.sub(_stakedBlocks[to], "STokens: Error in subtraction");
        // Get the balance of the account
        uint256 _balance = balanceOf(to);
        // Calculate the interest if P, R, T are non zero values
        if(_balance > 0 && _rewardRate > 0 && _rewardBlock > 0) {
            pendingRewards = (_balance * _rewardRate * _rewardBlock) / 100;
        }
        return pendingRewards;
    }

    function calculateRewards(address to) public virtual override whenNotPaused returns (bool success) {
        require(to == _msgSender(), "STokens: only staker can initiate their own rewards calculation");
        uint256 reward =  _calculateRewards(to);
        emit TriggeredCalculateRewards(to, reward, block.timestamp);
        return true;
    }

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

    //This function need to be called after deployment, only admin can call the same
    function setLiquidStakingContract(address liquidStakingContract) public virtual override whenNotPaused{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to set liquidStaking contract");
        _liquidStakingContract = liquidStakingContract;
    }

    function setWrapperContract(address wrapperContract) public virtual override whenNotPaused {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to set wrapper contract");
        _wrapperContract = wrapperContract;
    }

    function pause() public virtual override returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "STokens: User not authorised to pause contracts.");
        _pause();
        return true;
    }

    function unpause() public virtual override returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "STokens: User not authorised to unpause contracts.");
        _unpause();
        return true;
    }
}