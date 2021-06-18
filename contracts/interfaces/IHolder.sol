// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.0;


/**
 * @dev Interface of the IHolder.
 */
interface IHolder {

    /**
     * @dev provides the three attributes that are required to calculate the user's UToken rewards from Holder Logic.
     *
     * Returns the three uint256 values - user's LP Token balance, Total supply of LP Tokens & total supply of SToken reserve.
     *
     * Emits an event.
     */
    function getHolderAttributes(address whitelistedAddress, address userAddress)  external view returns (uint256 lpBalance, uint256 lpSupply, uint256 sTokenSupply);



}