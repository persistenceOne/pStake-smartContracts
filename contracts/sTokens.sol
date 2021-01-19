// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./uTokens.sol";

contract sTokens is ERC20 {
    
    address owner;
    
    mapping(address=>uint256) users;
    
    //modifier for only owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    //modifier for only owner and sender
    modifier onlyOwnerOrSender() {
        require(tx.origin == msg.sender || msg.sender == owner);
        _;
    }
    
     //Private instances of contracts to handle Utokens and Stokens
    uTokens private UTokens;
    
     //Event to track the setting of contracts
    event SetContract(
        address indexed _contract
    );
    
    uint256 private rewardRate = 1;
    mapping(address => uint256) private stakedBlocks;
    
    constructor(address _owner) public ERC20("sAtoms", "sAtoms") {
        owner = _owner;
        _mint(msg.sender, 0);
    }
    
    function setUTokensContract(address _contract) public {
        if (msg.sender == owner) {
            UTokens = uTokens(_contract);
            emit SetContract(_contract);
        }
    }
    
    function setStakedBlock(address from, uint256 _stakedBlock) public {
        stakedBlocks[from] = _stakedBlock;
    }
    
    function setRewardRate(uint256 rate) public onlyOwner returns (bool success) {
        rewardRate = rate;
        return true;
    }
    
    function mint(address to, uint256 tokens) public returns (bool success) {
        if (users[to] == 1) {
            calculateRewards(to);
            _mint(to, tokens);
        }
        else {
            users[to] = 1;
            _mint(to, tokens);
        }
        return true;
    }

    function burn(address from, uint256 tokens) public returns (bool success) {
        calculateRewards(from);
       _burn(from, tokens);
       return true;
    }

    function calculateRewards(address to) private returns (bool success){
        uint256 balance = balanceOf(to);
        // Check the supplied amount is greater than 0
        require(balance>0, "Number of tokens should be greater than 0");
        // Fetch the users stakedBlock from the mapping
        uint256 stakedBlock = stakedBlocks[to];
        // Get the current Block
        uint256 currentBlock = block.number;
        // Check the supplied block is greater than the staked block
        require(currentBlock>stakedBlock, "Current Block should be greater than staked Block");
        uint256 rewardBlock = currentBlock - stakedBlock;
        uint256 reward = (balance * rewardRate * rewardBlock) / 100;
        // Set the new stakedBlock to the current
        stakedBlocks[to] = currentBlock;
        
        // Mint new uTokens and send to the callers account
        UTokens.mint(to, reward);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override onlyOwnerOrSender returns (bool) {
        calculateRewards(msg.sender);
        _transfer(msg.sender, recipient, amount);
        return true;
        
    }
}