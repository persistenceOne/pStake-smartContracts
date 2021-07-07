// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IPSTAKE.sol";
import "./interfaces/IUTokens.sol";
import "./libraries/FullMath.sol";

contract PSTAKE is IPSTAKE, ERC20Upgradeable, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;
    using FullMath for uint256;


    // constants defining access control ROLES
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // variables capturing data of other contracts in the product
    address private _liquidStakingContract;
    address private _wrapperContract;
    address private _stakeLPCoreContract;
    // last timestamp when rewards were disbursed for a user
    mapping(address => uint256) private _lastUserRewardTimestamp;
    // LPTimeShare of total supply of PSTAKE
    uint256 private _pStakeLPTimeShare;
    // last timestamp when LPTimeShare was calculated for total supply
    uint256 private _lastLPTimeShareTimestamp;
    // define UToken contract object to 'transfer' reward from this to user
    IUTokens private _uTokens;

    /**
   * @dev Constructor for initializing the UToken contract.
   * @param pauserAddress - address of the pauser admin.
   */
    function initialize(address pauserAddress) public virtual initializer {
        __ERC20_init("pSTAKE Pegged ATOM", "pATOM");
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, pauserAddress);
        // PSTAKE IS A SIMPLE ERC20 TOKEN HENCE 18 DECIMAL PLACES
        _setupDecimals(18);
    }

    /**
     * @dev get rewards till timestamp
     * @param to: account address
     */
    function getLastUserRewardTimestamp(address to) public view virtual returns (uint256 lastUserRewardTimestamp) {
        lastUserRewardTimestamp = _lastUserRewardTimestamp[to];
    }

    /**
    * @dev Mint new PSTAKE for the provided 'address' and 'amount'
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
        require((_msgSender() == _stakeLPCoreContract), "UT1");  // minted by STokens contract

        _mint(to, tokens);
        return true;
    }

    /*
     * @dev Burn PSTAKE for the provided 'address' and 'amount'
     * @param from: account address, tokens: number of tokens
     *
     * Emits a {BurnTokens} event with 'from' set to address and 'tokens' set to amount of tokens.
     *
     * Requirements:
     *
     * - `amount` cannot be less than zero.
     *
     */
    /* function burn(address from, uint256 tokens) public virtual override returns (bool success) {
        require((tx.origin == from && _msgSender()==_liquidStakingContract) ||  (tx.origin == from && _msgSender() == _wrapperContract), "UT2");
        _burn(from, tokens);
        return true;
    } */

    /**
     * @dev Calculate pending rewards from the provided 'principal' & 'lastRewardTimestamp'. The rate is the moving reward rate.
     * @param principal: principal amount
     * @param lastRewardTimestamp: timestamp of last reward calculation performed
     */
    function _calculatePendingRewards(uint256 principal, uint256 lastRewardTimestamp) internal view returns (uint256 pendingRewards, uint256 updatedLPTimeShare){

        uint256 _pStakeTotalSupply = totalSupply();

       // uint256 _lastLPTimeShareTimestampLocal = _lastLPTimeShareTimestamp;

        uint256 _rewardPool = _uTokens.balanceOf(address(this));

        // get the total LPTimeShare of PSTAKE total supply, 
        // including the new LPTimeShare generated from _lastLPTimeShareTimestamp since now
        updatedLPTimeShare = _pStakeLPTimeShare.add(_pStakeTotalSupply.mul(block.timestamp.sub(_lastLPTimeShareTimestamp)));

        uint256 _userLPTimeShare = principal.mul(block.timestamp.sub(lastRewardTimestamp));

        // calculate pending rewards
        pendingRewards = _rewardPool.mulDiv(_userLPTimeShare, updatedLPTimeShare);
        updatedLPTimeShare = updatedLPTimeShare.sub(_userLPTimeShare);

        return (pendingRewards, updatedLPTimeShare);
    }

     /**
     * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
     * @param to: account address
     */
    function calculatePendingRewards(address to) public view virtual returns (uint256 pendingRewards, uint256 updatedLPTimeShare){
        // Get the time in number of blocks
        uint256 _lastRewardTimestamp = _lastUserRewardTimestamp[to];
        // Get the balance of the account
        uint256 _balance = balanceOf(to);
        // calculate pending rewards using _calculatePendingRewards
        (pendingRewards, updatedLPTimeShare) = _calculatePendingRewards(_balance, _lastRewardTimestamp);

        return (pendingRewards, updatedLPTimeShare);
    }

    /**
     * @dev Calculate rewards for the provided 'address'
     * @param to: account address
     */
    function _calculateRewards(address to) internal returns (uint256){
        // Calculate the rewards pending
        (uint256 _reward, uint256 _updatedLPTimeShare) = calculatePendingRewards(to);

        // Set the new stakedBlock to the current, 
        // as per Checks-Effects-Interactions pattern
        _lastUserRewardTimestamp[to] = block.timestamp;

        _pStakeLPTimeShare = _updatedLPTimeShare;

        _lastLPTimeShareTimestamp = block.timestamp;

        // mint uTokens only if reward is greater than zero
        if(_reward > 0) {
            // transfer the new rewards generated to the recipient's address
            _uTokens.transfer(to, _reward);
        }

        emit CalculateRewards(to, _reward, block.timestamp);
        return _reward;
    }

    /**
     * @dev Calculate rewards for the provided 'address'
     * @param to: account address
     *
     * Emits a {TriggeredCalculateRewards} event with 'to' set to address, 'reward' set to amount of tokens and 'timestamp'
     *
     */
    function calculateRewards(address to) public virtual whenNotPaused returns (bool success) {
        require(to == _msgSender(), "ST5");
        uint256 reward =  _calculateRewards(to);
        emit TriggeredCalculateRewards(to, reward, block.timestamp);
        return true;
    }

    /*
     * @dev Set 'contract address', called from constructor
     * @param liquidStakingContract: liquidStaking contract address
     *
     * Emits a {SetLiquidStakingContract} event with '_contract' set to the liquidStaking contract address.
     *
     */
    //This function need to be called after deployment, only admin can call the same
    function setLiquidStakingContract(address liquidStakingContract) public virtual{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ST15");
        _liquidStakingContract = liquidStakingContract;
        emit SetLiquidStakingContract(liquidStakingContract);
    }

    /*
     * @dev Set 'contract address', called from constructor
     * @param tokenWrapperContract: token wrapper contract address
     *
     * Emits a {SetTokenWrapperContract} event with '_contract' set to the token wrapper contract address.
     *
     */
    //This function need to be called after deployment, only admin can call the same
    function setTokenWrapperContract(address tokenWrapperContract) public virtual{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ST15");
        _wrapperContract = tokenWrapperContract;
        emit SetTokenWrapperContract(_wrapperContract);
    }

    /*
     * @dev Set 'contract address', for liquid staking smart contract
     * @param liquidStakingContract: liquidStaking contract address
     *
     * Emits a {SetLiquidStakingContract} event with '_contract' set to the liquidStaking contract address.
     *
     */
    function setStakeLPCoreContract(address stakeLPCoreContract) public virtual override{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "UT4");
        _stakeLPCoreContract = stakeLPCoreContract;
        emit SetStakeLPCoreContract(stakeLPCoreContract);
    }

    /*
    * @dev Set 'contract address', called from constructor
    * @param uTokenContract: utoken contract address
    *
    * Emits a {SetUTokensContract} event with '_contract' set to the utoken contract address.
    *
    */
    function setUTokensContract(address uTokenContract) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ST14");
        _uTokens = IUTokens(uTokenContract);
        emit SetUTokensContract(uTokenContract);
    }

    /**
      * @dev Triggers stopped state.
      *
      * Requirements:
      *
      * - The contract must not be paused.
      */
    function pause() public virtual returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "UT6");
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
        require(hasRole(PAUSER_ROLE, _msgSender()), "UT7");
        _unpause();
        return true;
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
        require(!paused(), "UT8");
        super._beforeTokenTransfer(from, to, amount);

        if(from != address(0)){
            _calculateRewards(from);
        }

         if(to != address(0)){
            _calculateRewards(from);
        }
    }
}