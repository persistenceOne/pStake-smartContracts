// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/**
 * @dev Interface of the IUTokens.
 */
interface ITokenWrapper {

    /**
    * @dev Set UTokens smart contract.
    * Emits a {SetContract} event.
    */
    function setUTokensContract(address uAddress) external;

    /**
    * @dev Set fees.
    * Emits a {SetFees} event.
    * Returns a boolean value indicating whether the operation succeeded.
    */
    function setFees(uint256 depositFee, uint256 withdrawFee) external returns (bool);

    /**
    * @dev Set minimum values.
    * Emits a {SetMinimumValues} event.
    * Returns a boolean value indicating whether the operation succeeded.
    */
    function setMinimumValues(uint256 minWithdraw) external returns (bool);

    /**
     * @dev Generates `amount` tokens to the caller's address `to`.
     *
     * Emits a {GenerateUTokens} event.
     */
    function generateUTokens(address to, uint256 amount) external;

    /**
    * @dev Generates `amount` tokens to the caller's address `to`.
    *
    * Emits a {GenerateUTokens} event.
    */
    function generateUTokensInBatch(address[] memory to, uint256[] memory amount) external;

    /**
     * @dev Withdraws `amount` tokens to the caller's address `to`.
     *
     * Emits a {WithdrawUTokens} event.
     */
    function withdrawUTokens(address from, uint256 tokens, string memory toAtomAddress) external;

    /**
    * @dev Emitted when fees are set
    */
    event SetFees( uint256 depositFee, uint256 withdrawFee );

    /**
    * @dev Emitted when minimum values are set
    */
    event SetMinimumValues( uint256 minWithdraw );

  /**
     * @dev Emitted when contract addresses are set
     */
    event SetUTokensContract( address indexed _contract );

    /**
    * @dev Emitted when uTokens are generated
    */
    event GenerateUTokens(address indexed accountAddress, uint256 tokens, uint256 timestamp);

    /**
    * @dev Emitted when UTokens are withdrawn
    */
    event WithdrawUTokens(address indexed accountAddress, uint256 tokens, string toAtomAddress, uint256 timestamp);
   
}