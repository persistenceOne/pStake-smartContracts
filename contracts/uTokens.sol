// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract uTokens is ERC20, Ownable {
    
    address private stokenContract;
    address private liquidStakingContract;
    
    constructor() public ERC20("unstakedAtoms", "uAtoms") {
        _setupDecimals(6);
    }
    
    function mint(address to, uint256 tokens) public returns (bool success) {
        if ((tx.origin == owner() && _msgSender() == liquidStakingContract)  || (tx.origin == to && _msgSender() == stokenContract) || (tx.origin == to && _msgSender()==liquidStakingContract))
        {
            _mint(to, tokens);
            return true;
        }
        else {
            return false;
        }
    }
     
    function burn(address from, uint256 tokens) public returns (bool success) {
        require(tx.origin == from);
        require(_msgSender()==liquidStakingContract);
        _burn(from, tokens);
        return true;
    }
    
    //These functions need to be called after deployment, only admin can call the same
    function setSTokenContractAddress(address _stokenContract) public onlyOwner {
        stokenContract = _stokenContract;
    }
    
     function setLiquidStakingContractAddress(address _liquidStakingContract) public onlyOwner {
        liquidStakingContract = _liquidStakingContract;
    }
}