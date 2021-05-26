// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IUTokens.sol";
import "./interfaces/ITokenWrapper.sol";

contract TokenWrapper is ITokenWrapper, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;

    //Private instances of contracts to handle Utokens and Stokens
    IUTokens private _uTokens;

    // defining the fees and minimum values
    uint256 private _minDeposit;
    uint256 private _minWithdraw;
    uint256 private _depositFee;
    uint256 private _withdrawFee;
    uint256 private _valueDivisor;

    bytes32 public constant BRIDGE_ADMIN_ROLE = keccak256("BRIDGE_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /*
   * @dev Constructor for initializing the TokenWrapper contract.
   * @param uAddress - address of the UToken contract.
   * @param sAddress - address of the SToken contract.
   * @param bridgeAdminAddress - address of the bridge admin.
   * @param pauserAddress - address of the pauser admin.
   */
    function initialize(address uAddress, address bridgeAdminAddress, address pauserAddress, uint256 valueDivisor) public virtual initializer  {
         __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BRIDGE_ADMIN_ROLE, bridgeAdminAddress);
        _setupRole(PAUSER_ROLE, pauserAddress);
        setUTokensContract(uAddress);
        _valueDivisor = valueDivisor;
    }

    /**
     * @dev Set 'fees', called from admin
     * @param withdrawFee: withdraw fee
     *
     * Emits a {SetFees} event with 'fee' set to the withdraw.
     *
     */
    function setFees(uint256 depositFee, uint256 withdrawFee) public virtual returns (bool success){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TokenWrapper: User not authorised to set fees");
        _depositFee = depositFee;
        _withdrawFee = withdrawFee;
        emit SetFees(depositFee, withdrawFee);
        return true;
    }

    /**
     * @dev get fees
     *
     */
    function getProps() public view virtual returns (uint256 depositFee, uint256 withdrawFee, uint256 minDeposit, uint256 minWithdraw, uint256 valueDivisor) {
        depositFee = _depositFee;
        withdrawFee = _withdrawFee;
        minDeposit = _minDeposit;
        minWithdraw = _minWithdraw;
        valueDivisor = _valueDivisor;
    }

    /**
     * @dev Set 'minimum values', called from admin
     * @param minWithdraw: stake minimum value
     *
     * Emits a {SetMinimumValues} event with 'minimum value' set to withdraw.
     *
     */
    function setMinimumValues(uint256 minDeposit, uint256 minWithdraw) public virtual returns (bool success){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TokenWrapper: User not authorised to set minimum values");
        _minDeposit = minDeposit;
        _minWithdraw = minWithdraw;
        emit SetMinimumValues(minDeposit, minWithdraw);
        return true;
    }

    /*
     * @dev Set 'contract address', called from constructor
     * @param uAddress: utoken contract address
     *
     * Emits a {SetContract} event with '_contract' set to the utoken contract address.
     *
     */
    function setUTokensContract(address uAddress) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TokenWrapper: User not authorised to set UToken contract");
        _uTokens = IUTokens(uAddress);
        emit SetUTokensContract(uAddress);
    }

    /**
      * @dev Triggers stopped state.
      *
      * Requirements:
      *
      * - The contract must not be paused.
      */
    function pause() public virtual returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "TokenWrapper: User not authorised to pause contracts");
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
        require(hasRole(PAUSER_ROLE, _msgSender()), "TokenWrapper: User not authorised to unpause contracts");
        _unpause();
        return true;
    }

    /**
     * @dev Mint new utokens for the provided 'address' and 'amount'
     * @param to: account address, amount: number of tokens
     * Requirements:
     *
     * - `amount` cannot be less than zero.
     *
     */
    function _generateUTokens(address to, uint256 amount) internal virtual returns (uint256 finalTokens){
        finalTokens = (((amount.mul(100)).mul(_valueDivisor)).sub(_depositFee)).div(_valueDivisor.mul(100));
        _uTokens.mint(to, finalTokens);
        return finalTokens;
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
        require(amount>0, "TokenWrapper: Requires a min deposit amount");
        require(hasRole(BRIDGE_ADMIN_ROLE, _msgSender()), "TokenWrapper: Only bridge admin can mint new tokens for a user");
        uint256 _finalTokens = _generateUTokens(to, amount);
        emit GenerateUTokens(to, _finalTokens, block.timestamp);
    }

    /**
     * @dev Mint new utokens for the provided 'address' and 'amount' iin batch
     * @param to: account address, amount: number of tokens
     *
     * Emits a {MintTokens} event with 'to' set to address and 'amount' set to amount of tokens.
     *
     * Requirements:
     *
     * - `amount` cannot be less than zero.
     *
     */
    function generateUTokensInBatch(address[] memory to, uint256[] memory amount) public virtual whenNotPaused {
        require(to.length == amount.length, "TokenWrapper: Mismatch array length");
        require(hasRole(BRIDGE_ADMIN_ROLE, _msgSender()), "TokenWrapper: Only bridge admin can mint new tokens for a user");
        uint256 i;
        uint256 _finalTokens;
        for ( i=0; i<to.length; i=i.add(1)) {
            require(amount[i]>0, "TokenWrapper: Requires a min deposit amount");
            _finalTokens = _generateUTokens(to[i], amount[i]);
        }
        emit GenerateUTokens(to[i.sub(1)], _finalTokens, block.timestamp);
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
        require(tokens>_minWithdraw, "TokenWrapper: Requires a min withdraw amount");
        uint256 _currentUTokenBalance = _uTokens.balanceOf(from);
        require(_currentUTokenBalance>=tokens, "TokenWrapper: Insuffcient balance for account");
        require(from == _msgSender(), "TokenWrapper: Withdraw can only be done by Staker");
        uint256 finalTokens = (((tokens.mul(100)).mul(_valueDivisor)).sub(_withdrawFee)).div(_valueDivisor.mul(100));
        _uTokens.burn(from, finalTokens);
        emit WithdrawUTokens(from, finalTokens, toAtomAddress, block.timestamp);
    }
}

