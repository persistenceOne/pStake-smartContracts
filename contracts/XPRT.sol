// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract XPRT is ERC20Upgradeable, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;

    bytes32 public constant BRIDGE_ADMIN_ROLE = keccak256("BRIDGE_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
   * @dev Constructor for initializing the UToken contract.
   * @param bridgeAdminAddress - address of the bridge admin.
   * @param pauserAddress - address of the pauser admin.
   */
    function initialize(address bridgeAdminAddress, address pauserAddress, address preAllocationAddress, uint256 preAllocationTokens) public virtual initializer {
        __ERC20_init("Persistence XPRT", "XPRT");
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BRIDGE_ADMIN_ROLE, bridgeAdminAddress);
        _setupRole(PAUSER_ROLE, pauserAddress);
        _setupDecimals(6);
        _mint(preAllocationAddress, preAllocationTokens);
    }

    /**
    * @dev Mint new utokens for the provided 'address' and 'amount'
    * @param to: account address, amount: number of tokens
    *
    * Emits a {MintTokens} event with 'to' set to address and 'amount' set to amount of tokens.
    *
    * Requirements:
    *
    * - `amount` cannot be less than zero.
    *
    */
    function mint(address to, uint256 tokens) public virtual whenNotPaused returns (bool success) {
        require(hasRole(BRIDGE_ADMIN_ROLE, _msgSender()), "XPRT: User not authorised to mint tokens");
        _mint(to, tokens);
        return true;
    }

    /*
     * @dev Burn utokens for the provided 'address' and 'amount'
     * @param to: account address, amount: number of tokens
     *
     * Emits a {BurnTokens} event with 'to' set to address and 'amount' set to amount of tokens.
     *
     * Requirements:
     *
     * - `amount` cannot be less than zero.
     *
     */
    function burn(address from, uint256 tokens) public virtual whenNotPaused returns (bool success) {
        require(hasRole(BRIDGE_ADMIN_ROLE, _msgSender()), "XPRT: User not authorised to burn tokens");
        _burn(from, tokens);
        return true;
    }

    /**
      * @dev Triggers stopped state.
      *
      * Requirements:
      *
      * - The contract must not be paused.
      */
    function pause() public virtual returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "XPRT: User not authorised to pause contracts.");
        _pause();
        return true;
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public virtual returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "XPRT: User not authorised to unpause contracts.");
        _unpause();
        return true;
    }
}