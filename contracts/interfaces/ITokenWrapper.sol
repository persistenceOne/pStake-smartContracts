// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.0;

/**
 * @dev Interface of the ITokenWrapper.
 */
interface ITokenWrapper {

    /**
    * @dev Set UTokens smart contract.
    * Emits a {SetUTokensContract} event.
    */
    function setUTokensContract(address uAddress) external;

    /**
     * @dev Generates `amount` tokens to the caller's address `to`.
     *
     * Emits a {GenerateUTokens} event.
     */
    function generateUTokens(address to, uint256 amount) external;

    /**
     * @dev Withdraws `amount` tokens to the caller's address `to`.
     *
     * Emits a {WithdrawUTokens} event.
     */
    function withdrawUTokens(address from, uint256 tokens, string memory toChainAddress) external;

    /**
    * @dev Emitted when fees are set
    */
    event SetFees( uint256 depositFee, uint256 withdrawFee );

    /**
    * @dev Emitted when minimum values are set
    */
    event SetMinimumValues( uint256 minDeposit, uint256 minWithdraw );

     /**
     * @dev Emitted when contract addresses are set
     */
    event SetUTokensContract( address indexed _contract );

    /**
    * @dev Emitted when uTokens are generated
    */
    event GenerateUTokens(address indexed accountAddress, uint256 indexed tokens, uint256 finalTokens, uint256 timestamp);

    /**
    * @dev Emitted when UTokens are withdrawn
    */
    event WithdrawUTokens(address indexed accountAddress, uint256 indexed tokens, uint256 finalTokens, string indexed toChainAddress, uint256 timestamp);
   
}