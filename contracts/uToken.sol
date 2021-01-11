// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.2-solc-0.7/contracts/token/ERC20/ERC20.sol";

contract uToken is ERC20 {

    constructor () ERC20("uAtoms", "uAtoms") {
        _mint(_msgSender(), 0);
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

     function transfer(address to, uint256 tokens) public override returns (bool success) {
         uint256 token = tokens * (10**uint256(decimals()));
       _transfer(_msgSender(), to, token);
         return true;
     }
}
