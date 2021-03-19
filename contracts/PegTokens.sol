// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./ISTokens.sol";
import "./IUTokens.sol";
import "./IPegTokens.sol";

contract PegTokens is IPegTokens, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;

    //Private instances of contracts to handle Utokens and Stokens
    IUTokens private _uTokens;
    ISTokens private _sTokens;

    address private _liquidStakingContract;

    bytes32 public constant BRIDGE_ADMIN_ROLE = keccak256("BRIDGE_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    function initialize(address uAddress, address sAddress, address bridgeAdminAddress, address pauserAddress) public virtual initializer  {
         __AccessControl_init();
         __AccessControl_init_unchained();
        __Pausable_init();
        __Pausable_init_unchained();
        setUTokensContract(uAddress);
        setSTokensContract(sAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BRIDGE_ADMIN_ROLE, bridgeAdminAddress);
        _setupRole(PAUSER_ROLE, pauserAddress);
    }

    function setUTokensContract(address uAddress) public virtual override whenNotPaused {
        _uTokens = IUTokens(uAddress);
        emit SetContract(uAddress);
    }

    /**
     * @dev Set 'contract address', called from constructor
     * @param sAddress: stoken contract address
     *
     * Emits a {SetContract} event with '_contract' set to the stoken contract address.
     *
     */
    function setSTokensContract(address sAddress) public virtual override whenNotPaused {
        _sTokens = ISTokens(sAddress);
        emit SetContract(sAddress);
    }

    /*
     * @dev Set 'contract address', called from constructor
     * @param sAddress: stoken contract address
     *
     * Emits a {SetContract} event with '_contract' set to the stoken contract address.
     *
     */
    function setLiquidStakingContract(address liquidStakingContract) public virtual override whenNotPaused {
        _liquidStakingContract = liquidStakingContract;
    }

    function pause() public virtual override returns (bool success) {
        //  require(hasRole(PAUSER_ROLE, _msgSender()), "UTokens: User not authorised to pause contracts.");
        _pause();
        return true;
    }

    function unpause() public virtual override returns (bool success) {
        // require(hasRole(PAUSER_ROLE, _msgSender()), "UTokens: User not authorised to pause contracts.");
        _unpause();
        return true;
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
    function generateUTokens(address to, uint256 amount) public virtual override whenNotPaused {
        require(amount>0, "LiquidStaking: Number of tokens should be greater than 0");
        // require(_msgSender == owner(), "LiquidStaking: Only owner can mint new tokens for a user");
        emit GenerateUTokens(to, amount, block.timestamp);
        _uTokens.mint(to, amount);
    }

    /**
     * @dev Burn utokens for the provided 'address' and 'amount'
     * @param from: account address, tokens: number of tokens, toAtomAddress: atom wallet address
     *
     * Emits a {BurnTokens} event with 'from' set to address and 'tokens' set to amount of tokens.
     *
     * Requirements:
     *
     * - `tokens` cannot be less than zero.
     *
     */
    function withdrawUTokens(address from, uint256 tokens, string memory toAtomAddress) public virtual override whenNotPaused {
        require(tokens>0, "LiquidStaking: Number of unstaked tokens should be greater than 0");
        // require(hasRole(STAKER_ROLE, _msgSender()), "LiquidStaking: Wihdraw can only be done by Staker");
        uint256 _currentUTokenBalance = _uTokens.balanceOf(from);
        require(_currentUTokenBalance>=tokens, "LiquidStaking: Insuffcient balance for account");
        require(from == _msgSender(), "LiquidStaking: Withdraw can only be done by Staker");
        _uTokens.burn(from, tokens);
        emit WithdrawUTokens(from, tokens, toAtomAddress, block.timestamp);
    }
}

