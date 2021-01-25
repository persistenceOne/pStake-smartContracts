// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UTokens is ERC20, Ownable {
    
    address private _stokenContract;
    address private _liquidStakingContract;
    
    constructor() public ERC20("unstakedAtoms", "uAtoms") {
        _setupDecimals(6);
    }
    
    function mint(address to, uint256 tokens) public returns (bool success) {
       require((tx.origin == owner() && _msgSender() == _liquidStakingContract)  || (tx.origin == to && _msgSender() == _stokenContract) || (tx.origin == to && _msgSender()==_liquidStakingContract), "UTokens: User not authorised to mint UTokens");
        _mint(to, tokens);
        return true;
    }
     
    function burn(address from, uint256 tokens) public returns (bool success) {
        require(tx.origin == from && _msgSender()==_liquidStakingContract, "UTokens: User not authorised to burn UTokens");
        _burn(from, tokens);
        return true;
    }
    
    //These functions need to be called after deployment, only admin can call the same
    function setSTokenContractAddress(address stokenContract) public onlyOwner {
        _stokenContract = stokenContract;
    }
    
     function setLiquidStakingContractAddress(address liquidStakingContract) public onlyOwner {
        _liquidStakingContract = liquidStakingContract;
    }
}