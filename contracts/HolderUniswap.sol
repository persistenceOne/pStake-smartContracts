// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.0;

import "./interfaces/IHolder.sol";
import "./interfaces/ISTokens.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/Uniswap/IUniswapV2ERC20.sol";
import "./interfaces/Uniswap/IUniswapV2Pair.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./interfaces/IUTokens.sol";

contract HolderUniswap is IHolder, Initializable, AccessControlUpgradeable{

    using SafeMathUpgradeable for uint256;
    IERC20Upgradeable sTokenContract;

    // constants defining access control ROLES
    // bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // mapping(address => uint256) private _holderContractRewardBalance;
    // mapping(address => uint256) private _holderContractTotalRewardsTimestamp;

    // variables pertaining to moving reward rate logic
    uint256 private _valueDivisor;

    IUTokens private _uTokens;

    // mapping(address => uint256) private _rewardsTillTimestamp;

    // mapping(address => address[3]) private _holderContractAddresses;
    // mapping(address => bytes4[3]) private _holderContractFuncSigs;

    // mapping(address => uint256) private _holderContractTotalLPTimeShare;
    // mapping(address => mapping(address => uint256)) private _holderContractLPBalanceTimestamps;
    // mapping(address => uint256) private _holderContractLPSupplyTimestamp;

    /**
   * @dev Constructor for initializing the Holder Uniswap contract.
   * @param _sTokenContractAddress - address of the SToken contract.
   * @param valueDivisor - valueDivisor set to 10^9.
   */
    function initialize(address _sTokenContractAddress, uint256 valueDivisor) public virtual initializer {
        __AccessControl_init();
        sTokenContract = IERC20Upgradeable(_sTokenContractAddress);
        _valueDivisor = valueDivisor;
    }

    /**
     * @dev get holder contract attributes
     *
     */
    /* function getHolderAttributes(address whitelistedAddress, address userAddress) public view returns (uint256 lpBalance, uint256 lpSupply, uint256 sTokenSupply){
        lpBalance = IUniswapV2ERC20(whitelistedAddress).balanceOf(userAddress);
        lpSupply = IUniswapV2ERC20(whitelistedAddress).totalSupply();
        sTokenSupply = sTokenContract.balanceOf(whitelistedAddress);
    } */

    /**
     * @dev get SToken reserve supply of the whitelisted contract 
     *
     */
    function getSTokenSupply(address to, address from, uint256 amount) public override view returns (uint256 sTokenSupply){
        sTokenSupply = sTokenContract.balanceOf(to);
        return sTokenSupply;
    }

    /**
    * @dev Calculate pending rewards from the provided 'principal' & 'lastRewardTimestamp'. The rate is the moving reward rate.
    * @param principal: principal amount
    * @param lastRewardTimestamp: timestamp of last reward calculation performed
    * @param rewardRate: reward rate in an array
    * @param _rewardBlockTimestamp: reward block timestamp in an array
    */
    /* function _calculatePendingRewards(uint256 principal, uint256 lastRewardTimestamp, uint256[] memory rewardRate, uint256[] memory _rewardBlockTimestamp) internal view returns (uint256 pendingRewards){
        uint256 _index;
        uint256 _rewardBlocks;
        uint256 _simpleInterestOfInterval;
        for(_index = _rewardBlockTimestamp.length.sub(1); _index >= 0;){
            // logic applies for all indexes of array except last index
            if(_index < _rewardBlockTimestamp.length.sub(1)) {
                if(_rewardBlockTimestamp[_index] > lastRewardTimestamp) {
                    _rewardBlocks = (_rewardBlockTimestamp[_index.add(1)]).sub(_rewardBlockTimestamp[_index]);
                    _simpleInterestOfInterval = (((principal.mul(rewardRate[_index])).mul(_rewardBlocks))).div(100 * _valueDivisor);
                    pendingRewards = pendingRewards.add(_simpleInterestOfInterval);
                }
                else {
                    _rewardBlocks = (_rewardBlockTimestamp[_index.add(1)]).sub(lastRewardTimestamp);
                    _simpleInterestOfInterval = (((principal.mul(rewardRate[_index])).mul(_rewardBlocks))).div(100 * _valueDivisor);
                    pendingRewards = pendingRewards.add(_simpleInterestOfInterval);
                    break;
                }
            }
            // logic applies only for the last index of array
            else {
                if(_rewardBlockTimestamp[_index] > lastRewardTimestamp) {
                    _rewardBlocks = (block.timestamp).sub(_rewardBlockTimestamp[_index]);
                    _simpleInterestOfInterval = (((principal.mul(rewardRate[_index])).mul(_rewardBlocks))).div(100 * _valueDivisor);
                    pendingRewards = pendingRewards.add(_simpleInterestOfInterval);
                }
                else {
                    _rewardBlocks = (block.timestamp).sub(lastRewardTimestamp);
                    _simpleInterestOfInterval = (((principal.mul(rewardRate[_index])).mul(_rewardBlocks))).div(100 * _valueDivisor);
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
    } */

    /**
    * @dev redeem rewards from holder contract
    * @param whitelistedAddress: contract address of the liquidity pool/product
    * @param rewardRate: reward rate in an array
    * @param rewardBlockTimestamp: reward block timestamp in an array
    */
    /* function calculateHolderRewards(address whitelistedAddress, address userAddress, uint256[] calldata rewardRate, uint256[] calldata rewardBlockTimestamp) public override returns (bool){

        // CALCULATE TOTAL REWARD POOL OF HOLDER CONTRACT USING STOKEN RESERVE TOTAL SUPPLY::
        uint256 _sTokenReserveSupply;
        uint256 _lpTokenBalance;
        uint256 _lpTokenSupply;

        // get the lpBalance, lpSupply and sTokenReserveSupply to calculate reward shares
        (_lpTokenBalance, _lpTokenSupply, _sTokenReserveSupply) =  getHolderAttributes(whitelistedAddress, userAddress);


        // get the last reward timestamp of sToken reserve
        uint256 _sTokenReserveTimestamp = _holderContractTotalRewardsTimestamp[whitelistedAddress];
        uint256 _additionalRewardBalance;

        // calculate the new rewards accrued and get the value of updated total rewards (without saving to state)
        if(_sTokenReserveSupply != 0)
            _additionalRewardBalance = _calculatePendingRewards(_sTokenReserveSupply, _sTokenReserveTimestamp, rewardRate, rewardBlockTimestamp);

        bool rewardBalance = calculateRewardsBalance(whitelistedAddress, _additionalRewardBalance);

        // add the additional rewards generated to the existing total pool
        uint256 _totalRewardBalance = _holderContractRewardBalance[whitelistedAddress].add(_additionalRewardBalance);

        // update the reward timestamp of whitelisted contract
        _holderContractTotalRewardsTimestamp[whitelistedAddress] = block.timestamp;

        // update the reward balance of whitelisted contract
        // _holderContractRewardBalance[whitelistedAddress] = _totalRewardBalance;

        // OR

        // Directly send the rewards to the holder address (this address itself)
        if(_additionalRewardBalance>0) {
            // Mint new uTokens and send to the callers account
            _uTokens.mint(address(this), _additionalRewardBalance);
        }

        // find the simple schematic of transfer of value between SToken contract and holder contract, for whitelisted address
        // issue with separated holder logic:
        // 1. need to send rewardRate and rewardTimestamps dynamic array to holder contract func also 
        // 2. holder contract need to execute mint function

        emit CalculateHolderRewards(address(this), _additionalRewardBalance, block.timestamp);
        return rewardBalance;
    } */

    /**
    * @dev redeem rewards from holder contract
    */
    /* function calculateRewardsBalance(address whitelistedAddress, uint256 _additionalRewardBalance) internal returns (bool){
        // add the additional rewards generated to the existing total pool
        uint256 _totalRewardBalance = _holderContractRewardBalance[whitelistedAddress].add(_additionalRewardBalance);

        // update the reward timestamp of whitelisted contract
        _holderContractTotalRewardsTimestamp[whitelistedAddress] = block.timestamp;

        // update the reward balance of whitelisted contract
        // _holderContractRewardBalance[whitelistedAddress] = _totalRewardBalance;

        // OR

        // Directly send the rewards to the holder address (this address itself)
        if(_additionalRewardBalance>0) {
            // Mint new uTokens and send to the callers account
            _uTokens.mint(address(this), _additionalRewardBalance);
        }

        // find the simple schematic of transfer of value between SToken contract and holder contract, for whitelisted address
        // issue with separated holder logic:
        // 1. need to send rewardRate and rewardTimestamps dynamic array to holder contract func also
        // 2. holder contract need to execute mint function
        

        emit CalculateHolderRewards(address(this), _totalRewardBalance,  _additionalRewardBalance, block.timestamp);
        return true;

    } */

        /*
        * @dev Set 'contract address', called from admin
        * @param uTokenContract: utoken contract address
        *
        * Emits a {SetUTokensContract} event with '_contract' set to the utoken contract address.
        *
        */
    function setUTokensContract(address uTokenContract) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "HU1");
        _uTokens = IUTokens(uTokenContract);
        emit SetUTokensContract(uTokenContract);
    }

    /* function getLPTimeShares(address whitelistedAddress, address userAddress, uint256 lpTokenBalance, uint256 lpTokenSupply) public view returns (uint256 lpBalanceTimeShare, uint256 lpTotalSupplyTimeShare){
        uint256 _lpNewSupplyTimeShare;
        uint256 _lastLPBalanceShareTimeInterval = block.timestamp.sub(_holderContractLPBalanceTimestamps[whitelistedAddress][userAddress]);
        // calculate the time share of balance of user
        // (dont use _calculatePendingRewards since reward rate is irrelevant here)
        if(lpTokenBalance != 0 &&  _lastLPBalanceShareTimeInterval != 0) {
            lpBalanceTimeShare = lpTokenBalance.mul(_lastLPBalanceShareTimeInterval);
        }

        // CALCULATE LPTIMESHARE OF LP TOTAL SUPPLY OF CONTRACT::
        // get the LP total Supply's last timestamp for LPTimeShare calculation
        // uint256 _lastLPSupplyShareTimestamp = _holderContractLPSupplyTimestamp[whitelistedAddress];
        uint256 _lastLPSupplyShareTimeInterval = block.timestamp.sub(_holderContractLPSupplyTimestamp[whitelistedAddress]);
        // calculate the new incoming time share of total supply of contract
        // (dont use _calculatePendingRewards since reward rate is irrelevant here)
        if(lpTokenSupply != 0 &&  _lastLPSupplyShareTimeInterval != 0) {
            _lpNewSupplyTimeShare = lpTokenSupply.mul(_lastLPSupplyShareTimeInterval);
        }

        // calculate the total time share of total supply of contract
        lpTotalSupplyTimeShare = _holderContractTotalLPTimeShare[whitelistedAddress].add(_lpNewSupplyTimeShare);
        assert(lpTotalSupplyTimeShare != 0);

    } */

    /* function getHolderAttributes(address whitelistedAddress, address userAddress) public view returns (uint256 lpBalance, uint256 lpSupply, uint256 sTokenSupply){
        // copy all holder logic attributes to local variables
        address _lpTokenERC20ContractAddress = _holderContractAddresses[whitelistedAddress][1];
        address _sTokenReserveContractAddress = _holderContractAddresses[whitelistedAddress][2];

        bytes4 _lpTokenBalanceFuncSig = _holderContractFuncSigs[whitelistedAddress][0];
        bytes4 _lpTokenSupplyFuncSig = _holderContractFuncSigs[whitelistedAddress][1];
        bytes4 _sTokenSupplyFuncSig = _holderContractFuncSigs[whitelistedAddress][2];

        // get the SToken Reserve Supply
        (bool success, bytes memory data) =
        _sTokenReserveContractAddress.staticcall(abi.encodeWithSelector(_sTokenSupplyFuncSig, whitelistedAddress));
        require(success && data.length >= 32, "ST7");
        sTokenSupply =  abi.decode(data, (uint256));

        // get the LP Token balance of user
        if(userAddress != address(0)) {
            (bool success2, bytes memory data2) =
            _lpTokenERC20ContractAddress.staticcall(abi.encodeWithSelector(_lpTokenBalanceFuncSig, userAddress));
            require(success2 && data2.length >= 32, "ST8");
            lpBalance =  abi.decode(data2, (uint256));
        }
        else
            lpBalance = 0;

        // get the LP Token total supply of ERC20-LP-Contract
        if(userAddress != address(0)) {

            (bool success3, bytes memory data3) =
            _lpTokenERC20ContractAddress.staticcall(abi.encodeWithSelector(_lpTokenSupplyFuncSig));
            require(success3 && data3.length >= 32, "ST9");
            lpSupply =  abi.decode(data3, (uint256));
        }
        else
            lpSupply = 0;

    } */

}