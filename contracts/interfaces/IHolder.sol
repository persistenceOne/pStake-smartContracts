// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.0;


/**
 * @dev Interface of the IHolder.
 */
interface IHolder {

    /**
    * @dev Set UTokens smart contract.
    *
    *
    * Emits a {SetContract} event.
    */
    function setUTokensContract(address utokenContract) external;

    /**
    * @dev returns stoken supply
    */
    function getSTokenSupply(address to, address from, uint256 amount) external view returns (uint256);

    /**
     * @dev Emitted when contract addresses are set
     */
    event SetUTokensContract( address indexed _contract );

}