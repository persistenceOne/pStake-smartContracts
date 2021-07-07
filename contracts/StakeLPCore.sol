// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./interfaces/ISTokens.sol";
import "./interfaces/IUTokens.sol";
import "./interfaces/IPSTAKE.sol";
import "./interfaces/IStakeLPCore.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/FullMath.sol";

contract StakeLPCore is IStakeLPCore, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;
    using FullMath for uint256;

    // using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    // EnumerableSetUpgradeable.AddressSet private whitelistedAddresses;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // balance of user for an LP Token 
    mapping(address => mapping(address => uint256)) private _lpBalance;
    // supply for an LP Token
    mapping(address => uint256) private _lpSupply;
    // weight factor of an LP token which decides how many PSTAKE tokens will be disbursed
    mapping(address => uint256) private _liquidityWeightFactor;
    // weight factor of an LP token which decides how many reward tokens will be disbursed
    mapping(address => uint256) private _rewardWeightFactor;

    // value divisor to make weight factor a fraction if need be
    uint256 private _valueDivisor;

    // last recorded total LPTimeShare
    uint256 private _lastLPTimeShare;
    // last recorded timestamp when rewards were disbursed
    uint256 private _lastLPTimeShareTimestamp;
    // last recorded timestamp when PSTAKE tokens were disbursed
    mapping(address => mapping(address => uint256)) private _lastLiquidityTimestamp; 

    //Private instances of contracts to handle Utokens and Stokens
    IUTokens private _uTokens;
    ISTokens private _sTokens;
    IPSTAKE private _pstakeTokens;

    // modifier which acts like re-entrancy attack preverter
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'StakeLPCore: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /**
   * @dev Constructor for initializing the LiquidStaking contract.
   * @param uAddress - address of the UToken contract.
   * @param sAddress - address of the SToken contract.
   * @param pStakeAddress - address of the pStake contract address.
   * @param valueDivisor - valueDivisor set to 10^9.
   */
    function initialize(address uAddress, address sAddress, address pStakeAddress, uint256 valueDivisor) public virtual initializer  {
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        //_setupRole(PAUSER_ROLE, pauserAddress);
        setUTokensContract(uAddress);
        setSTokensContract(sAddress);
        setPSTAKEContract(pStakeAddress);
        _valueDivisor = valueDivisor;

    }

     function _calculateRewardsAndLiquidity(address lpToken, address to, uint256 amount) internal returns (uint256 liquidity, uint256 reward){
        // get the balance of user's LP token
        uint256 _lpBalanceUser = _lpBalance[lpToken][to];
        uint256 _lpSupplyContract = _lpSupply[lpToken];

        // CALCULATE THE LIQUIDITY TOKENS TO BE DISBURSED TO USER
        liquidity = (_lpBalanceUser.mul(block.timestamp.sub(_lastLiquidityTimestamp[lpToken][to]))).mul(_liquidityWeightFactor[lpToken]);

        // CALCULATE THE REWARD TOKENS TO BE DISBURSED TO USER
        // calculate the LPTimeShare of the user's LP Token
        uint256 _userLPTimeShare = (_lpBalanceUser.mul(block.timestamp.sub(_lastLiquidityTimestamp[lpToken][to]))).mul(_rewardWeightFactor[lpToken]);
        // calculate the LPTimeShare of the sum of supply of all LP Tokens
        uint256 _newSupplyLPTimeShare = (_lpSupplyContract.mul(block.timestamp.sub(_lastLPTimeShareTimestamp))).mul(_rewardWeightFactor[lpToken]);
        uint256 _totalSupplyLPTimeShare = _lastLPTimeShare.add(_newSupplyLPTimeShare);

        // calculate users new reward tokens
        uint256 _rewardPool = _uTokens.balanceOf(address(this));
        reward = _rewardPool.mulDiv(_userLPTimeShare, _totalSupplyLPTimeShare);

        // update last timestamps and LPTimeShares 
        _lastLiquidityTimestamp[lpToken][to] = block.timestamp;
        _lastLPTimeShareTimestamp = block.timestamp;
        _lastLPTimeShare = _totalSupplyLPTimeShare.sub(_userLPTimeShare);

        // DISBURSE THE LIQUIDITY TOKENS TO USER (mint)
        if(liquidity > 0)
        _pstakeTokens.mint(to, liquidity);

        // DISBURSE THE REWARD TOKENS TO USER (transfer)
        if(reward > 0)
        TransferHelper.safeTransfer(address(_uTokens), to, reward);
         emit CalculateRewardsAndLiquidity(to, liquidity, amount);
    }

    function calculateRewardsAndLiquidity(address lpToken, uint256 amount) internal returns (uint256 liquidity, uint256 reward){
        // check for validity of arguments
        require(amount > 0, "LP35");

        // check if lpToken contract of DeFi product address is whitelisted
       // address messageSender = _msgSender();
        ( , , address[] memory _lpAddresses) = _sTokens.getWhitelistedAddresses();
        uint256 i;

        for (i=0; i<_lpAddresses.length; i=i.add(1)) {
            if(lpToken == _lpAddresses[i]) {
                break;
            }
        }

        require(i < _lpAddresses.length, "LP36");

        (liquidity, reward) = _calculateRewardsAndLiquidity(lpToken, _msgSender(), amount);
        CalculateRewardsAndLiquidity(lpToken, amount, _msgSender(), liquidity, reward);
    }


    function addLiquidity(
        address lpToken,
        uint256 amount
    ) external virtual override returns (uint256 liquidity, uint256 rewards) {
        // check for validity of arguments
        require(amount > 0, "LP31");
        // check if to address is of message sender
        // require(to == _msgSender(), "LP32");
        // check if lpToken contract of DeFi product address is whitelisted
        address messageSender = _msgSender();
        ( , , address[] memory _lpAddresses) = _sTokens.getWhitelistedAddresses();
        uint256 i;

        for (i=0; i<_lpAddresses.length; i=i.add(1)) {
            if(lpToken == _lpAddresses[i]) {
                break;
            }
        }

        require(i < _lpAddresses.length, "LP30");
        _calculateRewardsAndLiquidity(lpToken, messageSender, amount);
        // finally transfer the new LP Tokens to the StakeLP contract
        TransferHelper.safeTransferFrom(lpToken, messageSender, address(this), amount);
        // update the user balance
        _lpBalance[lpToken][messageSender] = _lpBalance[lpToken][messageSender].add(amount);
        // update the supply of lp tokens for reward and liquidity calculation
        _lpSupply[lpToken] = _lpSupply[lpToken].add(amount);
        emit AddLiquidity(lpToken, amount, rewards, liquidity);
    }

    function removeLiquidity(
        address lpToken,
        uint256 amount
    ) external virtual override returns (uint256 liquidity, uint256 rewards) {
        // check for validity of arguments
        require(amount > 0, "LP34");
        // check if to address is of message sender
        // require(to == _msgSender(), "LP32");
        address messageSender = _msgSender();

        // check if lpToken contract of DeFi product address is whitelisted
        ( , , address[] memory _lpAddresses) = _sTokens.getWhitelistedAddresses();
        uint256 i;

        for (i=0; i<_lpAddresses.length; i=i.add(1)) {
            if(lpToken == _lpAddresses[i]) {
                break;
            }
        }

        require(i < _lpAddresses.length, "LP32");

        // check if suffecient balance is there
        require(_lpBalance[lpToken][messageSender] >= amount, "LP33");

        _calculateRewardsAndLiquidity(lpToken, messageSender, amount);
        // finally transfer the new LP Tokens to the StakeLP contract
        TransferHelper.safeTransferFrom(lpToken, address(this), messageSender, amount);
        // update the user balance
        _lpBalance[lpToken][messageSender] = _lpBalance[lpToken][messageSender].sub(amount);
        // update the supply of lp tokens for reward and liquidity calculation
        _lpSupply[lpToken] = _lpSupply[lpToken].sub(amount);
        emit RemoveLiquidity(lpToken, amount, rewards, liquidity);
    }

    /**
     * @dev Set 'contract address', called from constructor
     * @param uAddress: utoken contract address
     *
     * Emits a {SetUTokensContract} event with '_contract' set to the utoken contract address.
     *
     */
    function setUTokensContract(address uAddress) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ10");
        _uTokens = IUTokens(uAddress);
        emit SetUTokensContract(uAddress);
    }

    /**
     * @dev Set 'contract address', called from constructor
     * @param sAddress: stoken contract address
     *
     * Emits a {SetSTokensContract} event with '_contract' set to the stoken contract address.
     *
     */
    function setSTokensContract(address sAddress) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ11");
        _sTokens = ISTokens(sAddress);
        emit SetSTokensContract(sAddress);
    }

    /**
     * @dev Set 'contract address', called from constructor
     * @param sAddress: stoken contract address
     *
     * Emits a {SetPSTAKEContract} event with '_contract' set to the stoken contract address.
     *
     */
    function setPSTAKEContract(address sAddress) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ11");
        _sTokens = ISTokens(sAddress);
        emit SetPSTAKEContract(sAddress);
    }

    /**
      * @dev Triggers stopped state.
      *
      * Requirements:
      *
      * - The contract must not be paused.
      */
    function pause() public virtual returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "LQ22");
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
        require(hasRole(PAUSER_ROLE, _msgSender()), "LQ23");
        _unpause();
        return true;
    }
}