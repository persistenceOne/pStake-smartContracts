// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "uTokens.sol";
import "sTokens.sol";

contract liquidStacking {

    using SafeMath for uint256;

    //Event to track the setting of contracts
    event SetContract(
        address indexed _contract
    );

    //Event to track the minting of tokens
    event MintTokens(
        address indexed _from,
        uint256 _value
    );

    //Event to track Staking
    event Staking(
        address indexed _from,
        uint256 _value
    );

    //Event to track Staking
    event Unstaking(
        address indexed _from,
        uint256 _value
    );

    uTokens private UTokens;
    sTokens private STokens;

    /**
     * @dev Sets the values for {utoken contract address} and {stoken contract address}
     * @param _uaddress: utoken address, _saddress: stoken address
     *
     * Both contract addresses are immutable: they can only be set once during
     * construction.
     */
    constructor(address _uaddress, address _saddress) public {
        setUTokensContract(_uaddress);
        setSTokensContract(_saddress);
    }

    /**
     * @dev Set 'contract address', called from constructor
     * @param _contract: utoken contract address
     *
     * Emits a {SetContract} event with '_contract' set to the utoken contract address.
     *
     */
    function setUTokensContract(address _contract) private {
        UTokens = uTokens(_contract);
        emit SetContract(_contract);
    }

    /**
     * @dev Set 'contract address', called from constructor
     * @param _contract: stoken contract address
     *
     * Emits a {SetContract} event with '_contract' set to the stoken contract address.
     *
     */
    function setSTokensContract(address _contract) private {
        STokens = sTokens(_contract);
        emit SetContract(_contract);
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
        require(amount>0, "Token Amount should be greater than 0");
        UTokens.mint(to, amount);
        emit MintTokens(to, amount);
    }

    /**
     * @dev Get utoken balance for the 'address'
     * @param _address: utoken contract address
     *
     */
    function getUtokenBalance(address _address) public view returns(uint256) {
        return UTokens.balanceOf(_address);
    }

    /**
     * @dev Get utoken balance for the 'address'
     * @param to: utoken contract address
     *
     */
    function getStokenBalance(address to) public view returns(uint256) {
        return STokens.balanceOf(to);
    }

    function transferUToken(address from, address to, uint256 amount) public returns (bool) {
        return UTokens.transferFrom(from, to, amount);
    }

    function transferSToken(address from, address to, uint256 amount, uint256 currentBlock) public returns (bool) {
        return STokens.transferSTokens(from, to, amount, currentBlock);
    }

    function stake(address to, uint256 utok, uint256 stakedBlock) public returns(bool) {
        // Check the supplied amount is greater than 0
        require(utok>0, "Number of staked tokens should be greater than 0");
        // Check the current balance for uTokens is greater than the amount to be staked
        uint256 currentUTokenBalance = UTokens.balanceOf(to);
        require(currentUTokenBalance>utok, "Insuffcient balance for account");
        // Burn the uTokens as specified with the amount
        UTokens.burn(to, utok);
        // Mint the sTokens for the account specified
        STokens.mint(to, utok);
        // Verify the staking
        uint256 newUTokenBalance = UTokens.balanceOf(to);
        uint256 verifyBalance = newUTokenBalance + utok;
        require(currentUTokenBalance == verifyBalance, "Stake Unsuccessful");
        // Set the staked Block Number
        STokens.setStakedBlock(to, stakedBlock);
        emit Staking(to, utok);
        return true;
    }

    function unStake(address to, uint256 stok, uint256 unStakedBlock) public returns(bool) {
        // Check the supplied amount is greater than 0
        require(stok>0, "Number of unstaked tokens should be greater than 0");
        // Check the current balance for sTokens is greater than the amount to be unStaked
        uint256 currentSTokenBalance = STokens.balanceOf(to);
        require(currentSTokenBalance>stok, "Insuffcient balance for account");
        //calculate reward for specified address
        STokens.calculateRewards(to, unStakedBlock);
        // Burn the sTokens as specified with the amount
        STokens.burn(to, stok);
        // Mint the uTokens for the account specified
        UTokens.mint(to, stok);
        // Verify the unStaking
        uint256 newSTokenBalance = STokens.balanceOf(to);
        uint256 verifyBalance = newSTokenBalance + stok;
        require(currentSTokenBalance == verifyBalance, "Unstake Unsuccessful");
        // Set the unStaked Block Number
        STokens.setStakedBlock(to, 0);
        emit Unstaking(to, stok);
        return true;
    }
}