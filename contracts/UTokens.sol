// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IUTokens.sol";

contract UTokens is ERC20Upgradeable, IUTokens, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;

    bytes32 public constant BRIDGE_ADMIN_ROLE = keccak256("BRIDGE_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address private _stokenContract;
    address private _liquidStakingContract;
    address private _wrapperContract;

    /**
   * @dev Constructor for initializing the UToken contract.
   * @param bridgeAdminAddress - address of the bridge admin.
   * @param pauserAddress - address of the pauser admin.
   */
    function initialize(address bridgeAdminAddress, address pauserAddress) public virtual initializer {
        __ERC20_init("pSTAKE Unstaked ATOMs", "ustkATOMs");
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BRIDGE_ADMIN_ROLE, bridgeAdminAddress);
        _setupRole(PAUSER_ROLE, pauserAddress);
        _setupDecimals(6);
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
    function mint(address to, uint256 tokens) public virtual override whenNotPaused returns (bool success) {
        require((hasRole(BRIDGE_ADMIN_ROLE, tx.origin) && _msgSender() == _wrapperContract)  || (_msgSender() == _stokenContract) || (tx.origin == to && _msgSender()==_liquidStakingContract), "UTokens: User not authorised to mint UTokens");
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
    function burn(address from, uint256 tokens) public virtual override whenNotPaused returns (bool success) {
        require((tx.origin == from && _msgSender()==_liquidStakingContract) ||  (tx.origin == from && _msgSender() == _wrapperContract), "UTokens: User not authorised to burn UTokens");
        _burn(from, tokens);
        return true;
    }

    /*
    * @dev Set 'contract address', called from constructor
    * @param stokenContract: stoken contract address
    *
    * Emits a {SetContract} event with '_contract' set to the stoken contract address.
    *
    */
    //These functions need to be called after deployment, only admin can call the same
    function setSTokenContract(address stokenContract) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "UTokens: User not authorised to set SToken contract");
        _stokenContract = stokenContract;
        emit SetSTokensContract(stokenContract);
    }

    /*
     * @dev Set 'contract address', for liquid staking smart contract
     * @param liquidStakingContract: liquidStaking contract address
     *
     * Emits a {SetLiquidStakingContract} event with '_contract' set to the liquidStaking contract address.
     *
     */
    function setLiquidStakingContract(address liquidStakingContract) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "UTokens: User not authorised to set liquidStaking contract");
        _liquidStakingContract = liquidStakingContract;
        emit SetLiquidStakingContract(liquidStakingContract);
    }

    /*
     * @dev Set 'contract address', called from constructor
     * @param wrapperTokensContract: tokenWrapper contract address
     *
     * Emits a {SetContract} event with '_contract' set to the tokenWrapper contract address.
     *
     */
    function setWrapperContract(address wrapperTokensContract) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "UTokens: User not authorised to set wrapper contract");
        _wrapperContract = wrapperTokensContract;
        emit SetWrapperContract(wrapperTokensContract);
    }

    /**
      * @dev Triggers stopped state.
      *
      * Requirements:
      *
      * - The contract must not be paused.
      */
    function pause() public virtual returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "UTokens: User not authorised to pause contracts.");
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
        require(hasRole(PAUSER_ROLE, _msgSender()), "UTokens: User not authorised to unpause contracts.");
        _unpause();
        return true;
    }
}