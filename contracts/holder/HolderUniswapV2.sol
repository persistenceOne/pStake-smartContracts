// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.0;

import "../interfaces/IHolder.sol";
import "../interfaces/ISTokens.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../libraries/TransferHelper.sol";


contract HolderUniswapV2 is IHolder, Initializable, AccessControlUpgradeable{

    // variables capturing data of other contracts in the product
    address private _stakeLPContract;
    ISTokens private _sTokens;


    // value divisor to make weight factor a fraction if need be
    uint256 private _valueDivisor;

    /**
   * @dev Constructor for initializing the Holder Uniswap contract.
   * @param sTokenContract - address of the SToken contract.
   * @param stakeLPContract - address of the StakeLPCore contract.
   * @param valueDivisor - valueDivisor set to 10^9.
   */
    function initialize(address sTokenContract, address stakeLPContract, uint256 valueDivisor) public virtual initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _sTokens = ISTokens(sTokenContract);
        _stakeLPContract = stakeLPContract;
        _valueDivisor = valueDivisor;
    }

    /**
     * @dev get SToken reserve supply of the whitelisted contract 
     *
     */
    function getSTokenSupply(address to, address from, uint256 amount) public override view returns (uint256 sTokenSupply){
        sTokenSupply = _sTokens.balanceOf(to);
        return sTokenSupply;
    }

    /**
     * @dev Set 'contract address', called from constructor
     * @param sAddress: stoken contract address
     *
     * Emits a {SetSTokensContract} event with '_contract' set to the stoken contract address.
     *
     */
    function setSTokensContract(address sAddress) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "HU1");
        _sTokens = ISTokens(sAddress);
        emit SetSTokensContract(sAddress);
    }

    /*
     * @dev Set 'contract address', called from constructor
     * @param liquidStakingContract: liquidStaking contract address
     *
     * Emits a {SetLiquidStakingContract} event with '_contract' set to the liquidStaking contract address.
     *
     */
    function setStakeLPContract(address stakeLPContract) public virtual override{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "HU2");
        _stakeLPContract = stakeLPContract;
        emit SetStakeLPContract(stakeLPContract);
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) public virtual override {
        require(_msgSender() == _stakeLPContract, "HU3");

        // finally transfer the new LP Tokens to the user address
        TransferHelper.safeTransfer(token, to, value);
    }

}