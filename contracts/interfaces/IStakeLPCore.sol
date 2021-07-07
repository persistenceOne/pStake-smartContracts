// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.0;


/**
 * @dev Interface of the IStakeLPCore.
 */
interface IStakeLPCore {

    /**
     * @dev Mints `amount` tokens to the caller's address `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function mint(address to, uint256 tokens) external returns (bool);

    /**
     * @dev Burns `amount` tokens to the caller's address `from`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function burn(address from, uint256 tokens) external returns (bool);


    /**
     * @dev Set UTokens smart contract.
     *
     *
     * Emits a {SetContract} event.
     */
    function setUTokensContract(address uAddress) external;

    /**
     * @dev Set UTokens smart contract.
     *
     *
     * Emits a {SetContract} event.
     */
    function setSTokensContract(address sAddress) external;


    /**
    * @dev Set LiquidStaking smart contract.
    */
    function setLiquidStakingContract(address liquidStakingContract) external;

    /**
     * @dev Emitted when contract addresses are set
     */
    event SetUTokensContract( address indexed _contract );

    /**
     * @dev Emitted when contract addresses are set
     */
    event SetLiquidStakingContract( address indexed _contract );

    /**
     * @dev Emitted when contract addresses are set
     */
    event SetStakeLPCoreContract( address indexed _contract );

    /**
    * @dev Emitted when a new whitelisted address is added
    *
    * Returns a boolean value indicating whether the operation succeeded.
    */
    event CalculateRewardsAndLiquidity(address indexed lpToken, uint256 amount, address indexed to, uint256 liquidity, uint256 reward);

    /**
    * @dev Emitted when a new whitelisted address is added
    *
    * Returns a boolean value indicating whether the operation succeeded.
    */
    event SetWhitelistedAddress(address indexed whitelistedAddress, address holderContractAddress, address lpContractAddress, uint256 timestamp);

    /**
    * @dev Emitted when a new whitelisted address is added
    *
    * Returns a boolean value indicating whether the operation succeeded.
    */
    // event AddWhitelistedAddress(address indexed whitelistedAddress, uint256 timestamp);

    /**
    * @dev Emitted when a new whitelisted address is removed
    *
    * Returns a boolean value indicating whether the operation succeeded.
    */
    event RemoveWhitelistedAddress(address indexed whitelistedAddress, address holderContractAddress, address lpContractAddress, uint256 timestamp);


    /**
    * @dev Emitted when a new whitelisted address is removed
    *
    * Returns a boolean value indicating whether the operation succeeded.
    */
    event GenerateHolderRewards(address indexed whitelistedAddress, address indexed accountAddress, uint256 timestamp);

    /**
     * @dev Emitted when `rewards` tokens are moved to account
     *
     * Note that `value` may be zero.
     */
    event CalculateRewards(address indexed accountAddress, uint256 tokens, uint256 finalTokens, uint256 timestamp);

    /**
     * @dev Emitted when `rewards` tokens are moved to holder account
     *
     * Note that `value` may be zero.
     */
    event CalculateHolderRewards(address indexed accountAddress, uint256 tokens, uint256 timestamp);

    /**
     * @dev Emitted when `rewards` tokens are moved to account
     *
     * Note that `value` may be zero.
     */
    event TriggeredCalculateRewards(address indexed accountAddress, uint256 tokens, uint256 timestamp);

    /**
    * @dev Emitted when fees are set
    */
    event SetFees( uint256 rewardFee );

}