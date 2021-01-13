// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract uTokens is ERC20 {
    constructor() public ERC20("uAtoms", "XPRT") {
        _mint(msg.sender, 0);
    }

    function mint(address to, uint256 tokens) public returns (bool success) {
        _mint(to, tokens);
        return true;
    }

    function burn(address from, uint256 tokens) public returns (bool success) {
        _burn(from, tokens);
        return true;
    }
}