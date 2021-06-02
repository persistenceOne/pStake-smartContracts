// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IUTokens.sol";
import "./interfaces/ITokenWrapper.sol";
import "./Bech32Validation.sol";
import "./Bech32.sol";

contract TokenWrapper is ITokenWrapper, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;
    using Bech32 for string;

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

    bytes hrpBytes;
    bytes controlDigitBytes;
    uint dataBytesSize;

    /*
   * @dev Constructor for initializing the TokenWrapper contract.
   * @param uAddress - address of the UToken contract.
   * @param bridgeAdminAddress - address of the bridge admin.
   * @param pauserAddress - address of the pauser admin.
   * @param valueDivisor - valueDivisor set to 10^9.
   */
    function initialize(address uAddress, address bridgeAdminAddress, address pauserAddress, uint256 valueDivisor) public virtual initializer  {
         __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BRIDGE_ADMIN_ROLE, bridgeAdminAddress);
        _setupRole(PAUSER_ROLE, pauserAddress);
        setUTokensContract(uAddress);
        _valueDivisor = valueDivisor;
        // setting bech32 validationattributes
        hrpBytes = "cosmos";
        controlDigitBytes = "1"; 
        dataBytesSize = 38;
    }

    /**
     * @dev Set 'fees', called from admin
     * @param withdrawFee: withdraw fee
     * @param depositFee: deposit fee
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
     * @dev get fees, minimum set values and value divisor
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
     * @param minDeposit: deposit minimum value
     * @param minWithdraw: withdraw minimum value
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
     * @dev Set 'contract address', called for utokens smart contract
     * @param uAddress: utoken contract address
     *
     * Emits a {SetUTokensContract} event with '_contract' set to the utoken contract address.
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
     * @dev common function added to be called by generateUTokens and generateUTokensInBatch and mints new utokens for the provided 'address' and 'amount'
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
     * Emits a {GenerateUTokens} event with 'to' set to address and 'amount' set to amount of tokens.
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
     * @dev Mint new utokens for the provided 'address' and 'amount' in batch
     * @param to[]: array of account addresses, amount[]: array of tokens
     *
     * Emits a {GenerateUTokens} event with 'to' set to address and 'amount' set to amount of tokens.
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
     * @dev Burn utokens for the provided 'address' and 'tokens'
     * @param from: account address, tokens: number of tokens, toChainAddress: atom wallet address
     *
     * Emits a {WithdrawUTokens} event with 'from' set to address, 'finalTokens' set to amount of tokens and 'toChainAddress'
     *
     * Requirements:
     *
     * - `tokens` cannot be less than zero.
     *
     */
    function withdrawUTokens(address from, uint256 tokens, string memory toChainAddress) public virtual override whenNotPaused {
        require(tokens>_minWithdraw, "TokenWrapper: Requires a min withdraw amount");
        //check if toChainAddress is valid address
        bool isAddressValid = toChainAddress.isBech32AddressValid(hrpBytes, controlDigitBytes, dataBytesSize);
        require(isAddressValid == true, "TokenWrapper: Invalid chain address ");
        uint256 _currentUTokenBalance = _uTokens.balanceOf(from);
        require(_currentUTokenBalance>=tokens, "TokenWrapper: Insuffcient balance for account");
        require(from == _msgSender(), "TokenWrapper: Withdraw can only be done by Staker");
        uint256 finalTokens = (((tokens.mul(100)).mul(_valueDivisor)).sub(_withdrawFee)).div(_valueDivisor.mul(100));
        _uTokens.burn(from, finalTokens);
        emit WithdrawUTokens(from, finalTokens, toChainAddress, block.timestamp);
    }
}

