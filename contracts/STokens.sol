// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UTokens {
    function mint(address _to, uint256 _tokens) public returns (bool _success) { }
}

contract STokens is ERC20, Ownable {

    using SafeMath for uint256;

    address private _liquidStakingContract;

    //Private instance of contract to handle Utokens
    UTokens private _uTokens;

    //Event to track the setting of contracts
    event SetContract(
        address indexed _contract
    );

    event CalculateRewards(address indexed to, uint256 reward, uint256 timestamp);
    event TriggeredCalculateRewards(address indexed to, uint256 reward, uint256 timestamp);


    uint256 private _rewardRate = 1;
    mapping(address => uint256) private _stakedBlocks;

    constructor(address uaddress) ERC20("stakedATOM", "stkATOM") {
        _setupDecimals(6);
        setUTokensContract(uaddress);
    }

    function setUTokensContract(address uTokenContract) public onlyOwner {
        _uTokens = UTokens(uTokenContract);
        emit SetContract(uTokenContract);
    }

    function setRewardRate(uint256 rate) public onlyOwner returns (bool success) {
        _rewardRate = rate;
        return true;
    }

    function getRewardRate() public view returns (uint256 rewardRate) {
        rewardRate = _rewardRate;
        return rewardRate;
    }

    function getStakedBlock(address to) public view returns (uint256 stakedBlocks) {
        stakedBlocks = _stakedBlocks[to];
        return stakedBlocks;
    }


    function mint(address to, uint256 tokens) public returns (bool success) {
        require(tx.origin == to && _msgSender() == _liquidStakingContract, "STokens: User not authorised to mint STokens");
        _mint(to, tokens);
        return true;
    }

    function burn(address from, uint256 tokens) public returns (bool success) {
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

    function calculatePendingRewards(address to) public view returns (uint256 pendingRewards){
        // Get the current Block
        uint256 _currentBlock = block.number;
        // Get the time in number of blocks
        uint256 _rewardBlock = _currentBlock.sub(_stakedBlocks[to]);
        // Get the balance of the account
        uint256 _balance = balanceOf(to);
        // Calculate the interest if P, R, T are non zero values
        if(_balance > 0 && _rewardRate > 0 && _rewardBlock > 0) {
            pendingRewards = (_balance * _rewardRate * _rewardBlock) / 100;
        }
        return pendingRewards;
    }

    function calculateRewards(address to) public returns (bool success) {
        require(to == _msgSender(), "STokens: only staker can initiate their own rewards calculation");
        uint256 reward =  _calculateRewards(to);
        emit TriggeredCalculateRewards(to, reward, block.timestamp);
        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
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
    function setLiquidStakingContractAddress(address liquidStakingContract) public onlyOwner {
        _liquidStakingContract = liquidStakingContract;
    }
}