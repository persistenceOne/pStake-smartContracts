// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract uTokens is ERC20 {
    
    address owner;
    
    constructor() public ERC20("uAtoms", "uAtmos") {
        _mint(msg.sender, 0);
        owner = msg.sender;
    }
    // If we add in modifiers to these function then contract to contract calls would not work, to by pass add in the checks within the function
    function mint(address to, uint256 tokens) public returns (bool success) {
        if (to == owner || to == tx.origin)
        {
            _mint(to, tokens);
            return true;
        }
        else {
            return false;
        }
    }
    
     // If we add in modifiers to these function then contract to contract calls would not work, to by pass add in the checks within the function
    function burn(address from, uint256 tokens) public returns (bool success) {
        if (from == owner || from == tx.origin)
        {
           _burn(from, tokens);
           return true;
        }
        else {
            return false;
        }
       
    }
}