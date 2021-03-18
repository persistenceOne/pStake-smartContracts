// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./ISTokens.sol";
import "./IUTokens.sol";
import "./ILiquidStaking.sol";

contract LiquidStaking is ILiquidStaking, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;

    //Private instances of contracts to handle Utokens and Stokens
    IUTokens private _uTokens;
    ISTokens private _sTokens;

    bytes32 public constant BRIDGE_ADMIN_ROLE = keccak256("BRIDGE_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 _unstakinglockTime;

    //Mapping to handle the Expiry period
    mapping(address => uint256[]) _unstakingExpiration;

    //Mapping to handle the Expiry amount
    mapping(address => uint256[]) _unstakingAmount;

    /**
     * @dev Sets the values for {utoken contract address} and {stoken contract address}
     * @param uAddress: utoken address, sAddress: stoken address
     *
     * Both contract addresses are immutable: they can only be set once during
     * construction.
     */
    function initialize(address uAddress, address sAddress, address bridgeAdminAddress, address pauserAddress) public virtual initializer  {
        __AccessControl_init();
        __AccessControl_init_unchained();
        __Pausable_init();
        __Pausable_init_unchained();
        setUTokensContract(uAddress);
        setSTokensContract(sAddress);
        _unstakinglockTime = 21 days;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BRIDGE_ADMIN_ROLE, bridgeAdminAddress);
        _setupRole(PAUSER_ROLE, pauserAddress);
    }

    /**
     * @dev Set 'contract address', called from constructor
     * @param uAddress: utoken contract address
     *
     * Emits a {SetContract} event with '_contract' set to the utoken contract address.
     *
     */
    function setUTokensContract(address uAddress) public virtual override whenNotPaused {
        _uTokens = IUTokens(uAddress);
        emit SetUTokensContract(uAddress);
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
        emit SetSTokensContract(sAddress);
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
        require(hasRole(BRIDGE_ADMIN_ROLE, msg.sender), "LiquidStaking: Only bridge admin can mint new tokens for a user");
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
        //require(hasRole(STAKER_ROLE, _msgSender()), "LiquidStaking: Wihdraw can only be done by Staker");
        uint256 _currentUTokenBalance = _uTokens.balanceOf(from);
        require(_currentUTokenBalance>=tokens, "LiquidStaking: Insuffcient balance for account");
        require(from == _msgSender(), "LiquidStaking: Withdraw can only be done by Staker");
        _uTokens.burn(from, tokens);
        emit WithdrawUTokens(from, tokens, toAtomAddress, block.timestamp);
    }

    /**
    * @dev Stake utokens over the platform with address 'to' for desired 'utok'(Burn uTokens and Mint sTokens)
    * @param to: user address for staking, utok: number of tokens to stake
    *
    *
    * Requirements:
    *
    * - `utok` cannot be less than zero.
    * - 'utok' cannot be more than balance
    * - 'utok' plus new balance should be equal to the old balance
    */
    function stake(address to, uint256 utok) public virtual override whenNotPaused returns(bool)  {
        // Check the supplied amount is greater than 0
        require(utok>0, "LiquidStaking: Number of staked tokens should be greater than 0");
        require(to == _msgSender(), "LiquidStaking: Staking can only be done by Staker");
        // require(hasRole(STAKER_ROLE, _msgSender()), "LiquidStaking: Staking can only be done by Staker");
        // Check the current balance for uTokens is greater than the amount to be staked
        uint256 _currentUTokenBalance = _uTokens.balanceOf(to);
        require(_currentUTokenBalance>=utok, "LiquidStaking: Insuffcient balance for account");
        emit StakeTokens(to, utok, block.timestamp);
        // Burn the uTokens as specified with the amount
        _uTokens.burn(to, utok);
        // Mint the sTokens for the account specified
        _sTokens.mint(to, utok);
        return true;
    }

    /**
     * @dev UnStake stokens over the platform with address 'to' for desired 'stok' (Burn sTokens and Mint uTokens with 21 days locking period)
     * @param to: user address for staking, stok: number of tokens to unstake
     *
     *
     * Requirements:
     *
     * - `stok` cannot be less than zero.
     * - 'stok' cannot be more than balance
     * - 'stok' plus new balance should be equal to the old balance
     */
    function unStake(address to, uint256 stok) public virtual override whenNotPaused returns(bool) {
        // Check the supplied amount is greater than 0
        //   require(hasRole(STAKER_ROLE, _msgSender()), "LiquidStaking: Unstaking can only be done by Staker");
        require(stok>0, "LiquidStaking: Number of unstaked tokens should be greater than 0");
        // Check the current balance for sTokens is greater than the amount to be unStaked
        uint256 _currentSTokenBalance = _sTokens.balanceOf(to);
        require(_currentSTokenBalance>=stok, "LiquidStaking: Insuffcient balance for account");
        emit UnstakeTokens(to, stok, block.timestamp);
        // Burn the sTokens as specified with the amount
        _sTokens.burn(to, stok);
        _unstakingExpiration[to].push(block.timestamp + _unstakinglockTime);
        _unstakingAmount[to].push(stok);
        return true;
    }

    /**
     * @dev Lock the unstaked tokens for 21 days, user can withdraw the same (Mint uTokens with 21 days locking period)
     *
     * Requirements:
     *
     * - `current block timestamp` should be after 21 days from the period where unstaked function is called.
     */
    function withdrawUnstakedTokens(address staker) public virtual override whenNotPaused{
        require(staker == _msgSender(), "LiquidStaking: Only staker can withdraw");
        // require(hasRole(STAKER_ROLE, _msgSender()), "LiquidStaking: Only staker can withdrawr");
        uint256 _withdrawBalance;
        for (uint256 i=0; i<_unstakingExpiration[staker].length; i++) {
            if (block.timestamp > _unstakingExpiration[staker][i]) {
                _withdrawBalance = _withdrawBalance + _unstakingAmount[staker][i];
                _unstakingExpiration[staker][i] = 0;
                _unstakingAmount[staker][i] = 0;
            }
        }
        require(_withdrawBalance > 0, "LiquidStaking: UnStaking period still pending");
        emit WithdrawUnstakeTokens(staker, _withdrawBalance, block.timestamp);
        _uTokens.mint(msg.sender, _withdrawBalance);
    }

    function getTotalUnbondedTokens(address staker) public view virtual override whenNotPaused returns (uint256 unbondingTokens) {
        if(staker == _msgSender()){
            for (uint256 i=0; i<_unstakingExpiration[staker].length; i++) {
                if (block.timestamp > _unstakingExpiration[staker][i]) {
                    unbondingTokens = unbondingTokens + _unstakingAmount[staker][i];
                }
            }
        }
        return unbondingTokens;
    }

    function pause() public virtual override returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "LiquidStaking: User not authorised to pause contracts.");
        _pause();
        return true;
    }

    function unpause() public virtual override returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "LiquidStaking: User not authorised to pause contracts.");
        _unpause();
        return true;
    }
}