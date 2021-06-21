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
    // maybe not required since this is not a critical function of Holder Logic
    // function getHolderAttributes(address whitelistedAddress, address userAddress)  external view returns (uint256 lpBalance, uint256 lpSupply, uint256 sTokenSupply);

    /**
     * @dev generates holder rewards
     *
     * Returns bool while generating holder rewards
     */
    function calculateHolderRewards(address whitelistedAddress, address userAddress, uint256[] calldata rewardRate, uint256[] calldata rewardBlockTimestamp)  external returns (bool);

    /**
    * @dev Set UTokens smart contract.
    *
    *
    * Emits a {SetContract} event.
    */
    function setUTokensContract(address utokenContract) external;

     /**
    * @dev Emitted when holder rewards are calculated and credited
    */
    event CalculateHolderRewards(address indexed holderAddress, uint256 tokens, uint256 timestamp);

    /**
     * @dev Emitted when contract addresses are set
     */
    event SetUTokensContract( address indexed _contract );

}