// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.0;

import "../interfaces/IHolder.sol";
import "../interfaces/ISTokens.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract HolderUniswap is IHolder, Initializable, AccessControlUpgradeable{

    ISTokens private sTokenContract;

    // value divisor to make weight factor a fraction if need be
    uint256 private _valueDivisor;

    //Private instances of contracts to handle Utokens and Stokens
    ISTokens private _sTokens;

    /**
   * @dev Constructor for initializing the Holder Uniswap contract.
   * @param _sTokenContractAddress - address of the SToken contract.
   * @param valueDivisor - valueDivisor set to 10^9.
   */
    function initialize(address _sTokenContractAddress, uint256 valueDivisor) public virtual initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        sTokenContract = ISTokens(_sTokenContractAddress);
        _valueDivisor = valueDivisor;
    }

    /**
     * @dev get SToken reserve supply of the whitelisted contract 
     *
     */
    function getSTokenSupply(address to, address from, uint256 amount) public override view returns (uint256 sTokenSupply){
        sTokenSupply = sTokenContract.balanceOf(to);
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
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LP10");
        _sTokens = ISTokens(sAddress);
        emit SetSTokensContract(sAddress);
    }


    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) public virtual override {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }


}