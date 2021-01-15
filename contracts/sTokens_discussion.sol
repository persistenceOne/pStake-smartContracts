// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract sTokens is ERC20 {
    
    uint256 private rewardRate = 1;
    mapping(address => uint256) private stakedBlocks;
    
    constructor() public ERC20("sAtoms", "sAtoms") {
        _mint(msg.sender, 0);
    }
    
    // modifier - reward rate should only be executable by admin 
        function setRewardRate(uint256 rate) public returns (bool success) {
        rewardRate = rate;
        return true;
    }
    
    // block.number (msg.sender) provides the current block
    // this function not required
    /* function setStakedBlock(address from, uint256 _stakedBlock) public {
        stakedBlocks[from] = _stakedBlock;
    } */
    
    // calculateRewards function should trigger here as well
    // modifiers - it has to come from staker (to === staker address)
    function mint(address to, uint256 tokens) public returns (bool success) {
      _mint(to, tokens);
      return true;
    }

    // send , receive, calculateRewards are the three triggers
    // transfer : a -> b
    // mint :   address(0) -> a
    // burn :   a -> address(0) 


    // calculateRewards function should trigger here as well
    // modifiers
    function burn(address from, uint256 tokens) public returns (bool success) {
       _burn(from, tokens);
       return true;
    }

    // modifiers?
    // do not send currentBlock , use block.number
    // uTokens should flow to the user's address, not sTokens
    // dont call _mint directly, call mint()
    function calculateRewards(address to, uint256 currentBlock) public returns (bool success){
        uint256 balance = balanceOf(to);
        // Check the supplied amount is greater than 0
        require(balance>0, "Number of tokens should be greater than 0");
        // Fetch the users stakedBlock from the mapping
        uint256 stakedBlock = stakedBlocks[to];
        // Check the supplied block is greater than the staked block
        require(currentBlock>stakedBlock, "Current Block should be greater than staked Block");

        currentBlock = block.number;

        uint256 rewardBlock = currentBlock - stakedBlock;
        uint256 reward = (balance * rewardRate * rewardBlock) / 100;
        // Set the new stakedBlock to the current
        stakedBlocks[to] = currentBlock;
        // Mint new sTokens and send to the callers account
        _mint(to, reward);
        return true;
    }
    
    // dont create seperate transferSTokens function, override the existing transfer() function
    function transferSTokens(address sender, address recipient, uint256 amount, uint256 currentBlock) public returns (bool) {
        calculateRewards(sender, currentBlock);
        _transfer(sender, recipient, amount);
        return true;
    }


}