// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @dev Interface of the IUTokens.
 */
interface ILiquidStaking {

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
    function withdrawUTokens(address from, uint256 tokens, string memory toAtomAddress) external;

    /**
     *  @dev Stake utokens over the platform with address 'to' for desired 'utok'(Burn uTokens and Mint sTokens)
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {StakeTokens} event.
     */
    function stake(address to, uint256 utok) external returns (bool);

    /**
     *  @dev UnStake stokens over the platform with address 'to' for desired 'stok' (Burn sTokens and Mint uTokens with 21 days locking period)
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {UnstakeTokens} event.
     */
    function unStake(address to, uint256 stok) external returns (bool);

    /**
    * @dev Lock the unstaked tokens for 21 days, user can withdraw the same (Mint uTokens with 21 days locking period)
    *
    * Emits a {WithdrawUnstakeTokens} event.
    */
    function withdrawUnstakedTokens(address staker) external;

    /**
    * @dev Returns the unbonded tokens.
    */
    function getTotalUnbondedTokens(address staker) external view returns (uint256);

    /**
    * @dev Set UTokens smart contract.
    * Emits a {SetContract} event.
    */
    function setUTokensContract(address uAddress) external;

    /**
     * @dev Set STokens smart contract.
     *
     *
     * Emits a {SetContract} event.
     */
    function setSTokensContract(address sAddress) external;

    /**
     * @dev Pause smart contracts
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {pause} event.
     */
    function pause() external returns (bool);

    /**
     * @dev Pause smart contracts
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Unpaused} event.
     */
    function unpause() external returns (bool);

    /**
    * @dev Emitted when contract addresses are set
    */
    event SetContract( address indexed _contract );

    /**
    * @dev Emitted when uTokens are generated
    */
    event GenerateUTokens(address indexed to, uint256 tokens, uint256 timestamp);

    /**
    * @dev Emitted when UTokens are withdrawn
    */
    event WithdrawUTokens(address indexed from, uint256 tokens, string toAtomAddress, uint256 timestamp);

    /**
    * @dev Emitted when uTokens are staked
    */
    event StakeTokens(address indexed staker, uint256 tokens, uint256 timestamp);

    /**
    * @dev Emitted when sTokens are unstaked
    */
    event UnstakeTokens(address indexed staker, uint256 tokens, uint256 timestamp);

    /**
    * @dev Emitted when unstaked tokens are withdrawn
    */
    event WithdrawUnstakeTokens(address indexed staker, uint256 tokens, uint256 timestamp);
}