// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./IUTokens.sol";

contract UTokens is ERC20Upgradeable, IUTokens, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;

    bytes32 public constant BRIDGE_ADMIN_ROLE = keccak256("BRIDGE_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address private _stokenContract;
    address private _liquidStakingContract;
    address private _pegTokensContract;

    function initialize(address bridgeAdminAddress, address pauserAddress) public virtual initializer {
        __ERC20_init("pSTAKE Unstaked ATOM", "ustkATOM");
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BRIDGE_ADMIN_ROLE, bridgeAdminAddress);
        _setupRole(PAUSER_ROLE, pauserAddress);
        _setupDecimals(6);
    }

    function mint(address to, uint256 tokens) public virtual override whenNotPaused returns (bool success) {
        require((hasRole(BRIDGE_ADMIN_ROLE, tx.origin) && _msgSender() == _liquidStakingContract) || (hasRole(BRIDGE_ADMIN_ROLE, tx.origin) && _msgSender() == _pegTokensContract)  || (tx.origin == to && _msgSender() == _stokenContract) || (tx.origin == to && _msgSender()==_liquidStakingContract), "UTokens: User not authorised to mint UTokens");
        _mint(to, tokens);
        return true;
    }

    function burn(address from, uint256 tokens) public virtual override whenNotPaused returns (bool success) {
        require((tx.origin == from && _msgSender()==_liquidStakingContract) ||  (tx.origin == from && _msgSender() == _pegTokensContract), "UTokens: User not authorised to burn UTokens");
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

    function setPegTokensContractAddress(address pegTokensContract) public virtual override whenNotPaused {
        _pegTokensContract = pegTokensContract;
    }

    function pause() public virtual override returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "UTokens: User not authorised to pause contracts.");
        _pause();
        return true;
    }

    function unpause() public virtual override returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "UTokens: User not authorised to pause contracts.");
        _unpause();
        return true;
    }
}