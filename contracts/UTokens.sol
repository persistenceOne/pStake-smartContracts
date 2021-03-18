// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./IUTokens.sol";

contract UTokens is ERC20Upgradeable, IUTokens, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address private _stokenContract;
    address private _liquidStakingContract;

    function initialize(address pauserAddress) public virtual initializer {
        __ERC20_init("unstakedATOM", "ustkATOM");
        __AccessControl_init();
        __AccessControl_init_unchained();
        __Pausable_init();
        __Pausable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, pauserAddress);
        _setupDecimals(6);
    }

    function mint(address to, uint256 tokens) public virtual override whenNotPaused returns (bool success) {
        require((_msgSender() == _liquidStakingContract)  || (tx.origin == to && _msgSender() == _stokenContract) || (tx.origin == to && _msgSender()==_liquidStakingContract), "UTokens: User not authorised to mint UTokens");
        _mint(to, tokens);
        return true;
    }

    function burn(address from, uint256 tokens) public virtual override whenNotPaused returns (bool success) {
        require(tx.origin == from && _msgSender()==_liquidStakingContract, "UTokens: User not authorised to burn UTokens");
        _burn(from, tokens);
        return true;
    }

    //These functions need to be called after deployment, only admin can call the same
    function setSTokenContractAddress(address stokenContract) public virtual override whenNotPaused {
        _stokenContract = stokenContract;
    }

    function setLiquidStakingContractAddress(address liquidStakingContract) public virtual override whenNotPaused {
        _liquidStakingContract = liquidStakingContract;
    }

    function pause() public virtual override returns (bool success) {
        require(hasRole(PAUSER_ROLE, msg.sender), "UTokens: User not authorised to pause contracts.");
        _pause();
        return true;
    }

    function unpause() public virtual override returns (bool success) {
        require(hasRole(PAUSER_ROLE, msg.sender), "UTokens: User not authorised to pause contracts.");
        _unpause();
        return true;
    }
}