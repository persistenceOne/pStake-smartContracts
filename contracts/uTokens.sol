// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract uTokens is ERC20 {
    
    address owner;
    
    //modifier for only owner and sender
    modifier onlyOwnerOrSender() {
        require(tx.origin == msg.sender || msg.sender == owner);
        _;
    }
    
    constructor() public ERC20("uAtoms", "uAtmos") {
        _mint(msg.sender, 0);
        owner = msg.sender;
    }
    
    function mint(address to, uint256 tokens) public onlyOwnerOrSender returns (bool success) {
        if (tx.origin == to || owner == to )
        {
            _mint(to, tokens);
            return true;
        }
        else
        {
            return false;
        }
    }

    function burn(address from, uint256 tokens) public onlyOwnerOrSender returns (bool success) {
       if (tx.origin == from || owner == from) {
           _burn(from, tokens);
           return true;
       }
       else
       {
           return false;
       }
       
    }
}