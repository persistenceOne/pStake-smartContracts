// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/ISTokens.sol";
import "./interfaces/IUTokens.sol";
import "./interfaces/IHolder.sol";

contract STokens is ERC20Upgradeable, ISTokens, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // constants defining access control ROLES
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // variables pertaining to holder logic for whitelisted addresses
    EnumerableSetUpgradeable.AddressSet private whitelistedAddresses;

    // _depositContractAddress has been discontinued
    // mapping(address => address) private _depositContractAddress;

    /*
    :: variables held for each holder logic mappings below ::
    function signature to get LPToken Balance, of user, in LP-ERC20-Contract  (balanceOf(userAddress) for LP token)
    function signature to get LPToken Total Supply, in LP-ERC20-Contract (totalSupply() for LP token)
    function signature to get SToken Total Supply of SToken-LP-Contract (getReserves() for SToken)
    timestamp value of last reward calculation for LP contract as per reserve
    timestamp value of last reward calculation for user as per liquidity
    */
    mapping(address => address[3]) private _holderContractAddresses;
    mapping(address => bytes4[3]) private _holderContractFuncSigs;
    mapping(address => uint256) private _holderContractRewardBalance;
    mapping(address => uint256) private _holderContractTotalLPTimeShare;
    mapping(address => mapping(address => uint256)) private _holderContractLPBalanceTimestamps;
    mapping(address => uint256) private _holderContractLPSupplyTimestamp;
    mapping(address => uint256) private _holderContractTotalRewardsTimestamp;


    // variables capturing data of other contracts in the product
    address private _liquidStakingContract;
    IUTokens private _uTokens;

    // variables pertaining to moving reward rate logic
    uint256[] private _rewardRate;
    uint256[] private _rewardBlockTimestamp;
    uint256 private _valueDivisor;
    mapping(address => uint256) private _rewardsTillTimestamp;

    /**
   * @dev Constructor for initializing the SToken contract.
   * @param uaddress - address of the UToken contract.
   * @param pauserAddress - address of the pauser admin.
   * @param rewardRate - set rewardRate.
   * @param valueDivisor - valueDivisor set to 10^9.
   */
    function initialize(address uaddress, address pauserAddress, uint256 rewardRate, uint256 valueDivisor) public virtual initializer {
        __ERC20_init("pSTAKE Staked ATOMs", "stkATOM");
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, pauserAddress);
        setUTokensContract(uaddress);
        // to set reward rate to 5e-3 or 0.005
        _rewardRate.push(rewardRate);
        _rewardBlockTimestamp.push(block.timestamp);
        _valueDivisor = valueDivisor;
        _setupDecimals(6);
    }


    /*
    * @dev set reward rate called by admin
    * @param rewardRate: reward rate
    *
    *
    * Requirements:
    *
    * - `rate` cannot be less than or equal to zero.
    *
    */
    function setRewardRate(uint256 rewardRate) public virtual override returns (bool success) {
        require(rewardRate>0, "STokens: Reward rate should be greater than 0");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to set reward rate");
        _rewardRate.push(rewardRate);
        _rewardBlockTimestamp.push(block.timestamp);
        return true;
    }


    /**
    * @dev get reward rate and value divisor
    */
    function getRewardRate() public view virtual returns (uint256[] memory rewardRate, uint256 valueDivisor) {
        rewardRate = _rewardRate;
        valueDivisor = _valueDivisor;
    }


    /**
     * @dev get rewards till timestamp
     * @param to: account address
     */
    function getRewardsTillTimestamp(address to) public view virtual returns (uint256 rewardsTillTimestamp) {
        rewardsTillTimestamp = _rewardsTillTimestamp[to];
    }


    /**
     * @dev Mint new stokens for the provided 'address' and 'tokens'
     * @param to: account address, tokens: number of tokens
     *
     * Emits a {MintTokens} event with 'to' set to address and 'tokens' set to amount of tokens.
     *
     * Requirements:
     *
     * - `amount` cannot be less than zero.
     *
     */
    function mint(address to, uint256 tokens) public virtual override returns (bool success) {
        require(tx.origin == to && _msgSender() == _liquidStakingContract, "STokens: User not authorised to mint STokens");
        _mint(to, tokens);
        return true;
    }


    /*
     * @dev Burn stokens for the provided 'address' and 'tokens'
     * @param to: account address, tokens: number of tokens
     *
     * Emits a {BurnTokens} event with 'to' set to address and 'tokens' set to amount of tokens.
     *
     * Requirements:
     *
     * - `amount` cannot be less than zero.
     *
     */
    function burn(address from, uint256 tokens) public  virtual override returns (bool success) {
        require(tx.origin == from && _msgSender() == _liquidStakingContract, "STokens: User not authorised to burn STokens");
        _burn(from, tokens);
        return true;
    }


    /**
     * @dev Calculate rewards for the provided 'address'
     * @param to: account address
     */
    function _calculateRewards(address to) internal returns (uint256){
        // Calculate the rewards pending
        uint256 _reward = calculatePendingRewards(to);
        // mint uTokens only if reward is greater than zero
        if(_reward>0) {
            // Mint new uTokens and send to the callers account
            emit CalculateRewards(to, _reward, block.timestamp);
            _uTokens.mint(to, _reward);
        }
        // Set the new stakedBlock to the current
        _rewardsTillTimestamp[to] = block.timestamp;
        return _reward;
    }


    /**
     * @dev Calculate rewards for the provided 'address'
     * @param to: account address
     *
     * Emits a {TriggeredCalculateRewards} event with 'to' set to address, 'reward' set to amount of tokens and 'timestamp'
     *
     */
    function calculateRewards(address to) public virtual override whenNotPaused returns (bool success) {
        require(to == _msgSender(), "STokens: only staker can initiate their own rewards calculation");
        uint256 reward =  _calculateRewards(to);
        emit TriggeredCalculateRewards(to, reward, block.timestamp);
        return true;
    }


    /**
     * @dev Calculate pending rewards from the provided 'principal' & 'lastRewardTimestamp'. The rate is the moving reward rate.
     * @param principal: principal amount
     * @param lastRewardTimestamp: timestamp of last reward calculation performed
     */
    function _calculatePendingRewards(uint256 principal, uint256 lastRewardTimestamp) internal view returns (uint256 pendingRewards){
        uint256 _index;
        uint256 _rewardBlocks;
        uint256 _simpleInterestOfInterval;
        for(_index = _rewardBlockTimestamp.length.sub(1); _index >= 0;){
            // logic applies for all indexes of array except last index
            if(_index < _rewardBlockTimestamp.length.sub(1)) {
                if(_rewardBlockTimestamp[_index] > lastRewardTimestamp) {
                    _rewardBlocks = (_rewardBlockTimestamp[_index.add(1)]).sub(_rewardBlockTimestamp[_index]);
                    _simpleInterestOfInterval = (((principal.mul(_rewardRate[_index])).mul(_rewardBlocks))).div(100 * _valueDivisor);
                    pendingRewards = pendingRewards.add(_simpleInterestOfInterval);
                }
                else {
                    _rewardBlocks = (_rewardBlockTimestamp[_index.add(1)]).sub(lastRewardTimestamp);
                    _simpleInterestOfInterval = (((principal.mul(_rewardRate[_index])).mul(_rewardBlocks))).div(100 * _valueDivisor);
                    pendingRewards = pendingRewards.add(_simpleInterestOfInterval);
                    break;
                }
            }
            // logic applies only for the last index of array
            else {
                if(_rewardBlockTimestamp[_index] > lastRewardTimestamp) {
                    _rewardBlocks = (block.timestamp).sub(_rewardBlockTimestamp[_index]);
                    _simpleInterestOfInterval = (((principal.mul(_rewardRate[_index])).mul(_rewardBlocks))).div(100 * _valueDivisor);
                    pendingRewards = pendingRewards.add(_simpleInterestOfInterval);
                }
                else {
                    _rewardBlocks = (block.timestamp).sub(lastRewardTimestamp);
                    _simpleInterestOfInterval = (((principal.mul(_rewardRate[_index])).mul(_rewardBlocks))).div(100 * _valueDivisor);
                    pendingRewards = pendingRewards.add(_simpleInterestOfInterval);
                    break;
                }
            }

            if(_index == 0) break;
            else {
                _index = _index.sub(1);
            }
        }
        return pendingRewards;
    }

    /**
     * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
     * @param to: account address
     */
    function calculatePendingRewards(address to) public view virtual returns (uint256 pendingRewards){
        // Get the time in number of blocks
        uint256 _lastRewardTimestamp = _rewardsTillTimestamp[to];
        // Get the balance of the account
        uint256 _balance = balanceOf(to);
        // calculate pending rewards using _calculatePendingRewards
        pendingRewards = _calculatePendingRewards(_balance, _lastRewardTimestamp);

        return pendingRewards;
    }


    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!paused(), "STokens: token transfer while paused");
        super._beforeTokenTransfer(from, to, amount);
        if(from == address(0)){
            // cannot have a scenario of transfer from address(0) to address(0)
            // if(to == address(0)){}

            if(!whitelistedAddresses.contains(to)){
                _calculateRewards(to);
            }
            else {
                generateHolderRewards(to, from);
            }

        }

        if(from != address(0) && !whitelistedAddresses.contains(from)){

            if(to == address(0)){
                _calculateRewards(from);
            }

            if(to != address(0) && !whitelistedAddresses.contains(to)){
                _calculateRewards(from);
                _calculateRewards(to);
            }

            if(to != address(0) && whitelistedAddresses.contains(to)){
                _calculateRewards(from);
                generateHolderRewards(to, from);
            }

        }

        if(from != address(0) && whitelistedAddresses.contains(from)){

            if(to == address(0)){
                generateHolderRewards(from, to);
            }

            if(to != address(0) && !whitelistedAddresses.contains(to)){
                generateHolderRewards(from, to);
                _calculateRewards(to);
            }

            if(to != address(0) && whitelistedAddresses.contains(to)){
                generateHolderRewards(from, address(0));
                generateHolderRewards(to, address(0));
            }

        }
    }


    /**
    * @dev redeem rewards from holder contract
    * @param whitelistedAddress: contract address of the liquidity pool/product
    */
    function generateHolderRewards(address whitelistedAddress, address userAddress) internal returns (bool){

        // CALCULATE TOTAL REWARD OF WHITELISTED CONTRACT USING STOKEN RESERVE TOTAL SUPPLY::

        uint256 _sTokenReserveSupply;
        uint256 _lpTokenBalance;
        uint256 _lpTokenSupply;

        // get the lpBalance, lpSupply and sTokenReserveSupply to calculate reward shares
        if(_holderContractAddresses[whitelistedAddress][0] == address(this))
            (_sTokenReserveSupply, _lpTokenBalance, _lpTokenSupply) =  getHolderAttributes(whitelistedAddress, userAddress);
        else {
            address _holderContract = _holderContractAddresses[whitelistedAddress][0];
            (_sTokenReserveSupply, _lpTokenBalance, _lpTokenSupply) =  IHolder(_holderContract).getHolderAttributes(whitelistedAddress, userAddress);
        }


        // get the last reward timestamp of sToken reserve
        uint256 _sTokenReserveTimestamp = _holderContractTotalRewardsTimestamp[whitelistedAddress];
        uint256 _additionalRewardBalance;

        // calculate the new rewards accrued and get the value of updated total rewards (without saving to state)
        if(_sTokenReserveSupply != 0)
            _additionalRewardBalance = _calculatePendingRewards(_sTokenReserveSupply, _sTokenReserveTimestamp);
        uint256 _totalRewardBalance = _holderContractRewardBalance[whitelistedAddress].add(_additionalRewardBalance);

        if(userAddress != address(0)) {
            // CALCULATE LPTIMESHARE OF LP BALANCE OF USER & LP TOTAL SUPPLY OF CONTRACT::

            (uint256 lpBalanceTimeShare, uint256 lpTotalSupplyTimeShare) = getLPTimeShares(whitelistedAddress, userAddress);
            if(_lpBalanceTimeShare > 0 && _lpTotalSupplyTimeShare > 0) {
                // calculate the reward share for the user
                uint256 _userReward = (_totalRewardBalance.mul(_lpBalanceTimeShare)).div(_lpTotalSupplyTimeShare);

                // Mint new uTokens and send to the callers account
                emit CalculateRewards(userAddress, _userReward, block.timestamp);
                _uTokens.mint(userAddress, _userReward);
                _totalRewardBalance = _totalRewardBalance.sub(_userReward);
            }

            // update the value of time share of total supply of contract
            _holderContractTotalLPTimeShare[whitelistedAddress] = _lpTotalSupplyTimeShare.sub(_lpBalanceTimeShare);
            // update the timestamp of user's lp balance
            _holderContractLPBalanceTimestamps[whitelistedAddress][userAddress] = block.timestamp;

        }

        // update the reward balance of whitelisted contract
        _holderContractRewardBalance[whitelistedAddress] = _totalRewardBalance;

        // update the reward timestamp of whitelisted contract
        _holderContractLPSupplyTimestamp[whitelistedAddress] = block.timestamp;
        _holderContractTotalRewardsTimestamp[whitelistedAddress] = block.timestamp;
        return true;
    }

    function getLPTimeShares(address whitelistedAddress, address userAddress) public view returns (uint256 lpBalanceTimeShare, uint256 lpTotalSupplyTimeShare){
        uint256 _lpNewSupplyTimeShare;
        uint256 _lastLPBalanceShareTimeInterval = block.timestamp.sub(_holderContractLPBalanceTimestamps[whitelistedAddress][userAddress]);
        // calculate the time share of balance of user
        // (dont use _calculatePendingRewards since reward rate is irrelevant here)
        if(_lpTokenBalance != 0 &&  _lastLPBalanceShareTimeInterval != 0) {
            lpBalanceTimeShare = _lpTokenBalance.mul(_lastLPBalanceShareTimeInterval);
        }

        // CALCULATE LPTIMESHARE OF LP TOTAL SUPPLY OF CONTRACT::
        // get the LP total Supply's last timestamp for LPTimeShare calculation
        // uint256 _lastLPSupplyShareTimestamp = _holderContractLPSupplyTimestamp[whitelistedAddress];
        uint256 _lastLPSupplyShareTimeInterval = block.timestamp.sub(_holderContractLPSupplyTimestamp[whitelistedAddress]);
        // calculate the new incoming time share of total supply of contract
        // (dont use _calculatePendingRewards since reward rate is irrelevant here)
        if(_lpTokenSupply != 0 &&  _lastLPSupplyShareTimeInterval != 0) {
            _lpNewSupplyTimeShare = _lpTokenSupply.mul(_lastLPSupplyShareTimeInterval);
        }

        // calculate the total time share of total supply of contract
        lpTotalSupplyTimeShare = _holderContractTotalLPTimeShare[whitelistedAddress].add(_lpNewSupplyTimeShare);
        assert(lpTotalSupplyTimeShare != 0);

    }




    function getHolderAttributes(address whitelistedAddress, address userAddress) public view returns (uint256 lpBalance, uint256 lpSupply, uint256 sTokenSupply){
        // copy all holder logic attributes to local variables
        address _lpTokenERC20ContractAddress = _holderContractAddresses[whitelistedAddress][1];
        address _sTokenReserveContractAddress = _holderContractAddresses[whitelistedAddress][2];

        bytes4 _lpTokenBalanceFuncSig = _holderContractFuncSigs[whitelistedAddress][0];
        bytes4 _lpTokenSupplyFuncSig = _holderContractFuncSigs[whitelistedAddress][1];
        bytes4 _sTokenSupplyFuncSig = _holderContractFuncSigs[whitelistedAddress][2];

        // get the SToken Reserve Supply
        (bool success, bytes memory data) =
        _sTokenReserveContractAddress.staticcall(abi.encodeWithSelector(_sTokenSupplyFuncSig, whitelistedAddress));
        require(success && data.length >= 32);
        sTokenSupply =  abi.decode(data, (uint256));

        // get the LP Token balance of user
        if(userAddress != address(0)) {
            (bool success2, bytes memory data2) =
            _lpTokenERC20ContractAddress.staticcall(abi.encodeWithSelector(_lpTokenBalanceFuncSig, userAddress));
            require(success2 && data2.length >= 32);
            lpBalance =  abi.decode(data2, (uint256));
        }
        else
            lpBalance = 0;

        // get the LP Token total supply of ERC20-LP-Contract
        if(userAddress != address(0)) {

            (bool success3, bytes memory data3) =
            _lpTokenERC20ContractAddress.staticcall(abi.encodeWithSelector(_lpTokenSupplyFuncSig));
            require(success3 && data3.length >= 32);
            lpSupply =  abi.decode(data3, (uint256));
        }
        else
            lpSupply = 0;

    }





    /*
    * @dev Set 'whitelisted address', performed by admin only
    * @param whitelistedAddress: contract address of the whitelisted party
    *
    * Emits a {UpdateWhitelistedAddress} event
    *
    */
    function updateWhitelistedAddress(address whitelistedAddress, address holderContractAddress, address lpTokenERC20ContractAddress, address sTokenReserveContractAddress, bytes4 lpTokenBalanceFuncSig, bytes4 lpTokenSupplyFuncSig, bytes4 sTokenSupplyFuncSig ) public virtual returns (bool success){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to update whitelisted address");
        // lpTokenERC20ContractAddress or sTokenReserveContractAddress can be address(0) but not whitelistedAddress
        require(whitelistedAddress != address(0), "STokens: Address is zero");
        if(!whitelistedAddresses.contains(whitelistedAddress)) whitelistedAddresses.add(whitelistedAddress);
        // add the contract addresses to holder mapping variable
        _holderContractAddresses[whitelistedAddress][0] = holderContractAddress;
        _holderContractAddresses[whitelistedAddress][1] = lpTokenERC20ContractAddress;
        _holderContractAddresses[whitelistedAddress][2] = sTokenReserveContractAddress;
        // add the function signatures to holder mapping variable
        _holderContractFuncSigs[whitelistedAddress][0] = lpTokenBalanceFuncSig;
        _holderContractFuncSigs[whitelistedAddress][1] = lpTokenSupplyFuncSig;
        _holderContractFuncSigs[whitelistedAddress][2] = sTokenSupplyFuncSig;
        emit UpdateWhitelistedAddress(whitelistedAddress, holderContractAddress, lpTokenERC20ContractAddress, sTokenReserveContractAddress, lpTokenBalanceFuncSig, lpTokenSupplyFuncSig, sTokenSupplyFuncSig, block.timestamp);
        return true;
    }

    /*
  * @dev remove 'whitelisted address', performed by admin only
  * @param whitelistedAddress: contract address of the whitelisted party
  * @param holderContractAddress: holder contract address of the corresponding whitelistedAddress
  *
  * Emits a {RemoveWhitelistedAddress} event
  *
  */
    function removeWhitelistedAddress(address whitelistedAddress) public virtual returns (bool success){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to add whitelisted address");
        require(whitelistedAddress != address(0), "STokens: Address is zero");
        // remove whitelistedAddress from the list
        whitelistedAddresses.remove(whitelistedAddress);

        address _holderContractAddress = _holderContractAddresses[whitelistedAddress][0];
        address _lpTokenERC20ContractAddress = _holderContractAddresses[whitelistedAddress][1];
        address _sTokenReserveContractAddress = _holderContractAddresses[whitelistedAddress][2];

        bytes4 _lpTokenBalanceFuncSig = _holderContractFuncSigs[whitelistedAddress][0];
        bytes4 _lpTokenSupplyFuncSig = _holderContractFuncSigs[whitelistedAddress][1];
        bytes4 _sTokenSupplyFuncSig = _holderContractFuncSigs[whitelistedAddress][2];

        // delete holder contract values
        delete _holderContractAddresses[whitelistedAddress];
        // delete holder function signature values
        delete _holderContractFuncSigs[whitelistedAddress];

        emit RemoveWhitelistedAddress(whitelistedAddress, _holderContractAddress, _lpTokenERC20ContractAddress, _sTokenReserveContractAddress, _lpTokenBalanceFuncSig, _lpTokenSupplyFuncSig, _sTokenSupplyFuncSig, block.timestamp);
        return true;
    }


    /*
    * @dev Set 'contract address', called from constructor
    * @param uTokenContract: utoken contract address
    *
    * Emits a {SetUTokensContract} event with '_contract' set to the utoken contract address.
    *
    */
    function setUTokensContract(address uTokenContract) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to set UToken contract address");
        _uTokens = IUTokens(uTokenContract);
        emit SetUTokensContract(uTokenContract);
    }

    /*
     * @dev Set 'contract address', called from constructor
     * @param liquidStakingContract: liquidStaking contract address
     *
     * Emits a {SetLiquidStakingContract} event with '_contract' set to the liquidStaking contract address.
     *
     */
    //This function need to be called after deployment, only admin can call the same
    function setLiquidStakingContract(address liquidStakingContract) public virtual override{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "STokens: User not authorised to set liquidStaking contract");
        _liquidStakingContract = liquidStakingContract;
        emit SetLiquidStakingContract(liquidStakingContract);
    }

    /**
      * @dev Triggers stopped state.
      *
      * Requirements:
      *
      * - The contract must not be paused.
      */
    function pause() public virtual returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "STokens: User not authorised to pause contracts.");
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
        require(hasRole(PAUSER_ROLE, _msgSender()), "STokens: User not authorised to unpause contracts.");
        _unpause();
        return true;
    }
}