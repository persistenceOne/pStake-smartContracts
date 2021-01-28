// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UTokens {
    function mint(address to, uint256 tokens) public returns (bool success) { }
    function burn(address from, uint256 tokens) public returns (bool success) { }
    function balanceOf(address account) public view returns (uint256) { }
}

contract STokens {
    function mint(address to, uint256 tokens) public returns (bool success) { }
    function balanceOf(address account) public view returns (uint256) { }
    function burn(address from, uint256 tokens) public returns (bool success) { }
}

contract LiquidStaking is Ownable {

    using SafeMath for uint256;

    //Event to track the setting of contracts
    event SetContract(
        address indexed _contract
    );

    //Private instances of contracts to handle Utokens and Stokens
    UTokens private _uTokens;
    STokens private _sTokens;

    uint256 _unstakinglockTime = 21 days;

    //Mapping to handle the Expiry period
    mapping(address => uint256[]) _unstakingExpiration;

    //Mapping to handle the Expiry amount
    mapping(address => uint256[]) _unstakingAmount;

    event GenerateUTokens(address to, uint256 amount);
    event WithdrawUTokens(address from, uint256 tokens, bytes32 toAtomAddress);
    event StakeTokens(address staker, uint256 tokens);
    event UnstakeTokens(address staker, uint256 tokens);
    event WithdrawUnstakeTokens(address staker, uint256 tokens);

    /**
     * @dev Sets the values for {utoken contract address} and {stoken contract address}
     * @param uAddress: utoken address, sAddress: stoken address
     *
     * Both contract addresses are immutable: they can only be set once during
     * construction.
     */
    constructor(address uAddress, address sAddress) {
        setUTokensContract(uAddress);
        setSTokensContract(sAddress);
    }

    /**
     * @dev Set 'contract address', called from constructor
     * @param uAddress: utoken contract address
     *
     * Emits a {SetContract} event with '_contract' set to the utoken contract address.
     *
     */
    function setUTokensContract(address uAddress) public onlyOwner {
        _uTokens = UTokens(uAddress);
        emit SetContract(uAddress);
    }

    /**
     * @dev Set 'contract address', called from constructor
     * @param sAddress: stoken contract address
     *
     * Emits a {SetContract} event with '_contract' set to the stoken contract address.
     *
     */
    function setSTokensContract(address sAddress) public onlyOwner {
        _sTokens = STokens(sAddress);
        emit SetContract(sAddress);
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
    function generateUTokens(address to, uint256 amount) public {
        require(amount>0, "LiquidStaking: Number of tokens should be greater than 0");
        require(_msgSender() == owner(), "LiquidStaking: Only owner can mint new tokens for a user");
        emit GenerateUTokens(to, amount);
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
    function withdrawUTokens(address from, uint256 tokens, bytes32 toAtomAddress) public {
        require(tokens>0, "LiquidStaking: Number of unstaked tokens should be greater than 0");
        uint256 _currentUTokenBalance = _uTokens.balanceOf(from);
        require(_currentUTokenBalance>=tokens, "LiquidStaking: Insuffcient balance for account");
        require(from == _msgSender(), "LiquidStaking: Withdraw can only be done by Staker");
        _uTokens.burn(from, tokens);
        emit WithdrawUTokens(from, tokens, toAtomAddress);
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
    function stake(address to, uint256 utok) public returns(bool) {
        // Check the supplied amount is greater than 0
        require(utok>0, "LiquidStaking: Number of staked tokens should be greater than 0");
        require(to == _msgSender(), "LiquidStaking: Staking can only be done by Staker");
        // Check the current balance for uTokens is greater than the amount to be staked
        uint256 _currentUTokenBalance = _uTokens.balanceOf(to);
        require(_currentUTokenBalance>=utok, "LiquidStaking: Insuffcient balance for account");
        // Burn the uTokens as specified with the amount
        _uTokens.burn(to, utok);
        // Mint the sTokens for the account specified
        _sTokens.mint(to, utok);
        emit StakeTokens(to, utok);
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
    function unStake(address to, uint256 stok) public returns(bool) {
        // Check the supplied amount is greater than 0
        require(to == _msgSender(), "LiquidStaking: Unstaking can only be done by Staker");
        require(stok>0, "LiquidStaking: Number of unstaked tokens should be greater than 0");
        // Check the current balance for sTokens is greater than the amount to be unStaked
        uint256 _currentSTokenBalance = _sTokens.balanceOf(to);
        require(_currentSTokenBalance>=stok, "LiquidStaking: Insuffcient balance for account");
        // Burn the sTokens as specified with the amount
        _sTokens.burn(to, stok);

        _unstakingExpiration[to].push(block.timestamp + _unstakinglockTime);
        _unstakingAmount[to].push(stok);
        emit UnstakeTokens(to, stok);
        return true;
    }

    /**
     * @dev Lock the unstaked tokens for 21 days, user can withdraw the same (Mint uTokens with 21 days locking period)
     *
     * Requirements:
     *
     * - `current block timestamp` should be after 21 days from the period where unstaked function is called.
     */
    function withdrawUnstakedTokens(address staker) public {
        require(staker == _msgSender(), "LiquidStaking: Only staker can withdraw");
        uint256 _withdrawBalance;
        for (uint256 i=0; i<_unstakingExpiration[staker].length; i++) {
            if (_unstakingExpiration[staker][i] > block.timestamp) {
                _withdrawBalance = _withdrawBalance + _unstakingAmount[staker][i];
                _unstakingExpiration[staker][i] = 0;
                _unstakingAmount[staker][i] = 0;
            }
        }
        require(_withdrawBalance == 0, "LiquidStaking: UnStaking period still pending");
        emit WithdrawUnstakeTokens(staker, _withdrawBalance);
        _uTokens.mint(msg.sender, _withdrawBalance);
    }
}