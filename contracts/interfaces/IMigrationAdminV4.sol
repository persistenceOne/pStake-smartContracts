/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

pragma solidity >=0.7.0;

/**
 * @dev Interface of the ITokenWrapper.
 */
interface IMigrationAdminV4 {

    /**
     * @dev Set UTokens smart contract.
	 * Emits a {SetUTokensContract} event.
	 */
    function setUTokensContract(address uAddress) external;

    /**
     * @dev Emitted when contract addresses are set
	 */
    event SetUTokensContract(address indexed _contract);

    /**
     * @dev Set STokens smart contract.
	 * Emits a {SetSTokensContract} event.
	 */
    function setSTokensContract(address sAddress) external;

    /**
     * @dev Emitted when contract addresses are set
	 */
    event SetSTokensContract(address indexed _contract);

    /**
     * @dev Set Token Wrapper smart contract.
	 * Emits a {SetTokenWrapperContract} event.
	 */
    function setTokenWrapperContract(address tokenWrapper) external;

    /**
     * @dev Emitted when contract addresses are set
	 */
    event SetTokenWrapperContract(address indexed _contract);

    /**
     * @dev Set liquid staking smart contract.
	 * Emits a {SetLiquidStakingContract} event.
	 */
    function setLiquidStakingContract(address liquidStaking) external;

    /**
     * @dev Emitted when contract addresses are set
	 */
    event SetLiquidStakingContract(address indexed _contract);

    /**
     * @dev Call SToken, TokenWrapper, LiquidStaking contract function.
	 * Emits a {ClaimPendingRewardsEvent} event.
	 * Emits a {ClaimUnbondedRewardsEvent} event.
	 * Emits a {BurnSTokensEvent} event.
	 */
    function Migrate(address accountAddress, string memory toCosmosChainAddress) external returns (bool success);

    /**
     * @dev Emitted when contract addresses are set
	 */
    event ClaimPendingRewardsEvent(address indexed accountAddress);

    /**
     * @dev Emitted when contract addresses are set
	 */
    event ClaimUnbondedRewardsEvent(address indexed accountAddress);

    /**
     * @dev Emitted when contract addresses are set
	 */
    event WithdrawUTokensEvent(address indexed accountAddress, uint256 currentUTokenBalance, string toCosmosChainAddress);

    /**
     * @dev Emitted when contract addresses are set
	 */
    event BurnSTokensEvent(address indexed accountAddress, uint256 currentSTokenBalance);

    /**
     * @dev Emitted when contract addresses are set
	 */
    event SetMigrationCompleteEvent(address indexed accountAddress, uint256 currentUTokenBalance, string toCosmosChainAddress);

    /**
     * @dev Triggers stopped state.
	 *
	 * Requirements:
	 *
	 * - The contract must not be paused.
	 */
    function pause() external returns (bool success);

    /**
     * @dev Returns to normal state.
	 *
	 * Requirements:
	 *
	 * - The contract must be paused.
	 */
    function unpause() external returns (bool success);

    /**
     * @dev Add hrp bytes
	 *
	 * Requirements:
	 *
	 * Can be called by admin only
	 */
    function setHRPBytes(bytes memory hrpBytes) external returns (bool success);

    /**
     * @dev Add hrp bytes
	 *
	 * Requirements:
	 *
	 * Can be called by admin only
	 */
    function setCosmosHRPBytes(bytes memory hrpBytes) external returns (bool success);

    // liquid staking contract address
    function _liquidStakingContract() external returns (address);
}
