// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "uTokens.sol";
import "sTokens.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/TokenTimelock.sol";

contract liquidStacking {
    
    address owner;

    using SafeMath for uint256;

    //Event to track the setting of contracts
    event SetContract(
        address indexed _contract
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
        uint256[] expire;
        uint256[] amount;
    }
    
    //modifier for only owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
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
        owner = msg.sender;
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
    function setUTokensContract(address _contract) public onlyOwner {
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
    function setSTokensContract(address _contract) public onlyOwner {
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

    function unStake(address to, uint256 stok) public returns(bool) {
        // Check the supplied amount is greater than 0
        require(stok>0, "Number of unstaked tokens should be greater than 0");
        // Check the current balance for sTokens is greater than the amount to be unStaked
        uint256 currentSTokenBalance = STokens.balanceOf(to);
        require(currentSTokenBalance>stok, "Insuffcient balance for account");
        // Burn the sTokens as specified with the amount
        STokens.burn(to, stok);
        locked storage user = unstakingUsers[to];
        user.expire.push(block.timestamp + unstakinglockTime);
        user.amount.push(stok);
        emit Unstaking(to, stok);
        return true;
    }

    function withdrawUnstakedTokens() public {
        locked storage userInfo = unstakingUsers[msg.sender];
        //check if any tokens are present in lock-in period for specified address
        require(userInfo.expire.length>0, "No Tokens present in Lock-in period.");
        //added count variable to not if any tokens were minted
        uint256 count = 0;
        for(uint i=0; i<=userInfo.expire.length-1; i++){
            if(block.timestamp>=userInfo.expire[i]){
                //only mint tokens when lock-in period is over
                UTokens.mint(msg.sender, userInfo.amount[0]);
                count++;
                //check the array length
                if(i<userInfo.expire.length-1){
                    userInfo.expire[i] = userInfo.expire[i+1];
                    userInfo.amount[i] = userInfo.amount[i+1];
                }
            }
        }
        //popping the last element
        if(count!=0){
            userInfo.expire.pop();
            userInfo.amount.pop();
        }
    }
}