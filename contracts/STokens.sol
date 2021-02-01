// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UTokens {
    function mint(address _to, uint256 _tokens) public returns (bool _success) { }
}

contract STokens is ERC20, Ownable {

    address private _liquidStakingContract;

    //Private instance of contract to handle Utokens
    UTokens private _uTokens;

    //Event to track the setting of contracts
    event SetContract(
        address indexed _contract
    );

    event CalculateRewards(address to, uint256 reward);
    event TriggeredCalculateRewards(address to, uint256 reward);


    uint256 private _rewardRate = 1;
    mapping(address => uint256) private _stakedBlocks;

    constructor(address uaddress) ERC20("stackedAtoms", "sAtoms") {
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

    function getRewardRate() public view returns (uint256) {
        return _rewardRate;
    }

    function getStakedBlock(address to) public view returns (uint256) {
        return _stakedBlocks[to];
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

        // Get the current Block
        uint256 _currentBlock = block.number;

        // Check the supplied block is greater than the staked block
        require(_currentBlock>_stakedBlocks[to], "STokens: Current Block should be greater than staked Block");
        uint256 _rewardBlock = _currentBlock - _stakedBlocks[to];

        // Set the new stakedBlock to the current
        _stakedBlocks[to] = _currentBlock;

        //Get the balance of the account
        uint256 _balance = balanceOf(to);
        uint256 _reward;

        if(_balance > 0 && _rewardRate > 0 && _rewardBlock > 0)
        {
            _reward = (_balance * _rewardRate * _rewardBlock) / 100;
            // Mint new uTokens and send to the callers account
            emit CalculateRewards(to, _reward);
            _uTokens.mint(to, _reward);
        }
        return _reward;
    }

    function calculateRewards(address to) public returns (bool success) {
        require(to == _msgSender(), "STokens: only staker can initiate their own rewards calculation");
        uint256 reward =  _calculateRewards(to);
        emit TriggeredCalculateRewards(to, reward);
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