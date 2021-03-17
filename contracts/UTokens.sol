// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract UTokens is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable {

    using SafeMathUpgradeable for uint256;
    
    address private _stokenContract;
    address private _liquidStakingContract;

    function initialize() public virtual initializer {
        __ERC20_init("unstakedATOM", "ustkATOM");
        _setupDecimals(6);
    }
    
    function mint(address to, uint256 tokens) public whenNotPaused returns (bool success) {
       require((tx.origin == owner() && _msgSender() == _liquidStakingContract)  || (tx.origin == to && _msgSender() == _stokenContract) || (tx.origin == to && _msgSender()==_liquidStakingContract), "UTokens: User not authorised to mint UTokens");
        _mint(to, tokens);
        return true;
    }
     
    function burn(address from, uint256 tokens) public whenNotPaused returns (bool success) {
        require(tx.origin == from && _msgSender()==_liquidStakingContract, "UTokens: User not authorised to burn UTokens");
        _burn(from, tokens);
        return true;
    }
    
    //These functions need to be called after deployment, only admin can call the same
    function setSTokenContractAddress(address stokenContract) public whenNotPaused onlyOwner {
        _stokenContract = stokenContract;
    }
    
     function setLiquidStakingContractAddress(address liquidStakingContract) public whenNotPaused onlyOwner {
        _liquidStakingContract = liquidStakingContract;
    }
}