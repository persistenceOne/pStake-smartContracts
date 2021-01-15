// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "uTokens.sol";
import "sTokens.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/TokenTimelock.sol";

contract liquidStacking {

    using SafeMath for uint256;

    //Event to track the setting of contracts
    event SetContract(
        address indexed _contract
    );

// not required to create events for mint, burn or transfer. inherent events exist.

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

    //Event to track UnStaking
    event Unstaking(
        address indexed _from,
        uint256 _value
    );
   
    //Private instances of contracts to handle Utokens and Stokens
    uTokens private UTokens;
    sTokens private STokens;
    
    uint256 unstakinglockTime = 21 days;
    
    //Structure to handle the locking period
    struct locked{
        uint256 expire;
        uint256 amount;
    }
    
    //Mapping to handle the locking period
    mapping(address => locked) unstakingUsers;

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

    // this fn needs to be called by admin so cannot be private, instead use modifier (can be only called by admin)

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

    // this fn needs to be called by admin so cannot be private, instead use modifier (can be only called by admin)

    function setSTokensContract(address _contract) private {
        STokens = sTokens(_contract);
        emit SetContract(_contract);
    }
    
     /**
     * @dev Set 'reward rate' with Stokens for reward calculation
     * @param rate: rate provided for Stokens, Default set to 1 percent
     *
     * Emits a {MintTokens} event with 'to' set to address and 'amount' set to amount of tokens.
     *
     * Requirements:
     *
     * - `amount` cannot be less than zero.
     *
     */

     // modifier 

    function setReward(uint256 rate) public returns(bool) {
        require(rate>0, "Reward Rate should be greater than 0");
        return STokens.setRewardRate(rate);
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

     // let me get back to you on this 

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
    
    /**
     * @dev Transfer utokens from one address 'from' to the other address 'to' for desired 'amount'
     * @param from: senders address to: receiveers address, amount: number of tokens
     *
     *
     * Requirements:
     *
     * - `amount` cannot be less than zero.
     *
     */

    // this function shouldn't be there, and certainly cannot use transferFrom. thats a different function altogether

    function transferUToken(address from, address to, uint256 amount) public returns (bool) {
        require(amount>0, "Amount should be greater than 0");
        return UTokens.transferFrom(from, to, amount);
    }
    
     /**
     * @dev Transfer stokens from one address 'from' to the other address 'to' for desired 'amount', after calculating the rewards with 'currentBlock'
     * @param from: senders address to: receivers address, amount: number of tokens, cuurentBlock: Current Block number to calculate the rewards
     *
     *
     * Requirements:
     *
     * - `amount` cannot be less than zero.
     *
     */

    // this function shouldn't be there, and certainly cannot use transferFrom. thats a different function altogether


    function transferSToken(address from, address to, uint256 amount, uint256 currentBlock) public returns (bool) {
        require(amount>0, "Amount should be greater than 0");
        return STokens.transferSTokens(from, to, amount, currentBlock);
    }
    
     /**
     * @dev Stake utokens over the platform with address 'to' for desired 'amount', after fixing the 'stakedBlock' (Burn uTokens and Mint sTokens)
     * @param to: user address for staking, utok: number of tokens to stake, stkaedBlock: Current Block number to be fixed as staked Block
     *
     *
     * Requirements:
     *
     * - `utok` cannot be less than zero.
     * - 'utok' cannot be more than balance
     * - 'utok' plus new balance should be equal to the old balance
     */

     // the mint of sTokens MIGHT be happening after the bridge has performed protocol staking in the cosmos end. 
     // will let you know the order, but for now, dont change. 

    // Verify the staking - let me get back to you on that, might not be required.
    // Set the staked Block Number - not required as the mint/burn is already handling rewardCalc & setStakedBlock
    // rename setStakedBlock - redeemedTillBlock or rewardsRedeemedTillBlock
 


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

    //calculate reward for specified address - not required, burn fn should take care of calculateRewards
    // emit Unstaking(to, stok); - probably not required as burn will emit event


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
        locked storage user = unstakingUsers[to];
        user.expire = block.timestamp + unstakinglockTime;
        user.amount = stok;
        emit Unstaking(to, stok);
        return true;
    }
    
    function withdrawUnstakedTokens() public {
        require(block.timestamp>=unstakingUsers[msg.sender].expire);
        locked storage userInfo = unstakingUsers[msg.sender];
        uint256 value = userInfo.amount;
        userInfo.expire = 0;
        userInfo.amount = 0;
        UTokens.mint(msg.sender, value);
        
    }
}