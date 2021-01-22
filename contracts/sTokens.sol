// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract uTokens {
     function mint(address to, uint256 tokens) public returns (bool success) { }
}

contract sTokens is ERC20, Ownable {
    
    address private liquidStakingContract;
    
     //Private instance of contract to handle Utokens
    uTokens private UTokens;
    
     //Event to track the setting of contracts
    event SetContract(
        address indexed _contract
    );
    
    uint256 internal rewardRate = 1;
    mapping(address => uint256) private stakedBlocks;
    
    constructor(address _uaddress) public ERC20("stackedAtoms", "sAtoms") {
        _setupDecimals(6);
        setUTokensContract(_uaddress);
    }
    
    function setUTokensContract(address _contract) public onlyOwner {
        UTokens = uTokens(_contract);
        emit SetContract(_contract);
    }
    
    function setRewardRate(uint256 rate) public onlyOwner returns (bool success) {
        rewardRate = rate;
        return true;
    }
    
    function mint(address to, uint256 tokens) public returns (bool success) {
        require(tx.origin == to);
        require(_msgSender() == liquidStakingContract);
        _mint(to, tokens);
        return true;
    }

    function burn(address from, uint256 tokens) public returns (bool success) {
        require(tx.origin == from);
        require(_msgSender() == liquidStakingContract);
        _burn(from, tokens);
        return true;
    }

    function _calculateRewards(address to) internal returns (bool success){
        uint256 balance = balanceOf(to);
        
        // Check the supplied amount is greater than 0
        require(balance>=0, "sTokens: Number of tokens should be greater than 0");
        
        // Fetch the users stakedBlock from the mapping
        uint256 stakedBlock = stakedBlocks[to];
        
        // Get the current Block
        uint256 currentBlock = block.number;
        
        // Check the supplied block is greater than the staked block
        require(currentBlock>stakedBlock, "sTokens: Current Block should be greater than staked Block");
        uint256 rewardBlock = currentBlock - stakedBlock;
        uint256 reward = (balance * rewardRate * rewardBlock) / 100;
        
        // Set the new stakedBlock to the current
        stakedBlocks[to] = currentBlock;
        
        // Mint new uTokens and send to the callers account
        UTokens.mint(to, reward);
        return true;
    }
    
    function calculateRewards(address to) public returns (bool success) {
        return _calculateRewards(to);
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (from == address(0) && to != address(0))
        {
            _calculateRewards(to);
        }
        else
        {
            _calculateRewards(from);
        }
    }
    
    //This function need to be called after deployment, only admin can call the same
     function setLiquidStakingContractAddress(address _liquidStakingContract) public onlyOwner {
        liquidStakingContract = _liquidStakingContract;
    }
}