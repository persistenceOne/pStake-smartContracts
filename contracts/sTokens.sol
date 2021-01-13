// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract sTokens is ERC20 {
    constructor() public ERC20("sAtoms", "XPRT") {
        _mint(msg.sender, 0);
    }
    
    function mint(address to, uint256 tokens) public returns (bool success) {
      uint256 token = tokens * (10**uint256(decimals()));
      _mint(to, token);
      return true;
    }

    function burn(address from, uint256 tokens) public returns (bool success) {
       uint256 token = tokens * (10**uint256(decimals()));
       _burn(from, token);
       return true;
    }

    function sendReward(address to, uint256 rewardPercentage) public returns (bool success){
        uint256 balance = balanceOf(to);
        // Check the supplied amount is greater than 0
        require(balance>0, "Number of tokens should be greater than 0");
        uint256 reward = (balance * rewardPercentage) / 100;
        _mint(to, reward);
        return true;
    }
}