// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/**
 * @dev Interface of the IUTokens.
 */
interface ILiquidStaking {


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
    * @dev Set PegTokens smart contract.
    * Emits a {SetContract} event.
    */
    function setWrapperContract(address wrapperAddress) external;

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
    event SetUTokensContract( address indexed _contract );

    /**
    * @dev Emitted when contract addresses are set
    */
    event SetSTokensContract( address indexed _contract );

    /**
    * @dev Emitted when contract addresses are set
    */
    event SetWrapperContract( address indexed _contract );

    /**
    * @dev Emitted when uTokens are staked
    */
    event StakeTokens(address indexed accountAddress, uint256 tokens, uint256 timestamp);

    /**
    * @dev Emitted when sTokens are unstaked
    */
    event UnstakeTokens(address indexed accountAddress, uint256 tokens, uint256 timestamp);

    /**
    * @dev Emitted when unstaked tokens are withdrawn
    */
        event WithdrawUnstakeTokens(address indexed accountAddress, uint256 tokens, uint256 timestamp);
}