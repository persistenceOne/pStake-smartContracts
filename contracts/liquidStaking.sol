// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./uToken.sol";
import "./sToken.sol";

contract liquidStaking {
    uToken private _uToken;
    sToken private _sToken;

    function mintUToken(address to, uint256 tokens) public returns (bool success) {
        _uToken.mint(to, tokens);
         return true;
    }
}