// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";


contract uTokens is ERC20 {
    constructor() public ERC20("uAtoms", "uAtoms") {
        _mint(msg.sender, 0);
    }
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
    
    function burn(address to, uint256 amount) public {
        _burn(to, amount);
    }
    
    
}