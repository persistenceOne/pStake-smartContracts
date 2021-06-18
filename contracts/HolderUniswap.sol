// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.0;

import "./interfaces/IHolder.sol";
// import "./interfaces/ISTokens.sol"
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/Uniswap/IUniswapV2ERC20.sol";
import "./interfaces/Uniswap/IUniswapV2Pair.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract HolderUniswap is IHolder, Initializable{

    using SafeMathUpgradeable for uint256;
    IERC20Upgradeable sTokenContract;

    function initialize(address _sTokenContractAddress) public virtual initializer {
        sTokenContract = IERC20Upgradeable(_sTokenContractAddress);
    }

    function getHolderAttributes(address whitelistedAddress, address userAddress) public view override returns (uint256 lpBalance, uint256 lpSupply, uint256 sTokenSupply){
        lpBalance = IUniswapV2ERC20(whitelistedAddress).balanceOf(userAddress);
        lpSupply = IUniswapV2ERC20(whitelistedAddress).totalSupply();
        sTokenSupply = sTokenContract.balanceOf(whitelistedAddress);
    }

}
