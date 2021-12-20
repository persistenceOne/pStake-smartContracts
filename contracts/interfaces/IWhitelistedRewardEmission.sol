/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

pragma solidity >=0.7.0;

interface IWhitelistedRewardEmission {
	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function addRewards(
		address holderContractAddress,
		address rewardTokenContractAddress,
		address rewardSender,
		uint256 rewardAmount
	) external returns (bool success);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function setRewardEmission(
		address holderContractAddress,
		address rewardTokenContractAddress,
		uint256 rewardTokenEmission
	) external returns (bool success);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function getEmissionData(
		address holderContractAddress,
		address rewardTokenContractAddress
	)
		external
		view
		returns (
			uint256[] memory cummulativeRewardAmount,
			uint256[] memory rewardTokenEmission,
			uint256[] memory rewardEmissionTimestamp
		);

	/**
	 * @dev Set 'contract address', called from constructor
	 *
	 * Emits a {} event with '_contract' set to the stoken contract address.
	 *
	 */
	function setStakeLPContract(address stakeLPContract) external;

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function setRewardPoolUserTimestamp(
		address holderContractAddress,
		address rewardTokenContractAddress,
		address accountAddress,
		uint256 timestampValue
	) external returns (bool success);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function getRewardPoolUserTimestamp(
		address holderContractAddress,
		address rewardTokenContractAddress,
		address accountAddress
	) external view returns (uint256 rewardPoolUserTimestamp);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function setLastLPTimeShareTimestamp(
		address lpTokenAddress,
		uint256 timestampValue
	) external returns (bool success);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function getLastLPTimeShareTimestamp(address lpTokenAddress)
		external
		view
		returns (uint256 lastLPTimeShareTimestamp);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function setLastCummulativeSupplyLPTimeShare(
		address lpTokenAddress,
		uint256 newSupplyLPTimeShare
	) external returns (bool success);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function calculateUpdatedSupplyLPTimeShare(
		address holderAddress,
		address lpTokenAddress,
		address rewardTokenAddress,
		address accountAddress,
		uint256 newSupplyLPTimeShare
	) external view returns (uint256 updatedSupplyLPTimeShare);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function calculateUpdatedRewardPool(
		address holderAddress,
		address rewardTokenAddress,
		address accountAddress
	) external view returns (uint256 updatedRewardPool);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function calculateOtherPendingRewards(
		address holderAddress,
		address lpTokenAddress,
		address accountAddress,
		uint256 userLPTimeShare,
		uint256 newSupplyLPTimeShare
	)
		external
		view
		returns (
			uint256[] memory otherRewardAmounts,
			address[] memory otherRewardTokens
		);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function getCumulativeRewardValue(
		address holderContractAddress,
		address rewardTokenContractAddress,
		uint256 rewardTimestamp
	) external view returns (uint256 cumulativeRewardValue);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 */
	function getCumulativeSupplyValue(
		address lpTokenAddress,
		uint256 lpSupplyTimestamp
	) external view returns (uint256 cumulativeSupplyValue);

	/**
	 * @dev Calculate pending rewards for the provided 'address'. The rate is the moving reward rate.
	 * @param holderAddress: holder contract address
	 */
	function isHolderContractWhitelisted(address holderAddress)
		external
		view
		returns (bool result);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function setHolderAddressesForRewards(
		address[] memory holderContractAddresses,
		address[] memory rewardTokenContractAddresses
	) external returns (bool success);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function removeHolderAddressesForRewards(
		address[] memory holderContractAddresses
	) external returns (bool success);

	/*
	 * @dev calculate liquidity and reward tokens and disburse to user
	 * @param lpToken: lp token contract address
	 * @param amount: token amount
	 */
	function removeTokenContractsForRewards(
		address[] memory holderContractAddresses,
		address[] memory rewardTokenContractAddresses
	) external returns (bool success);

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
	 * @dev Emitted
	 */
	event AddRewards(
		address holderContractAddress,
		address rewardTokenContractAddress,
		address rewardSender,
		uint256 tokens,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event SetRewardEmission(
		address holderContractAddress,
		address rewardTokenContractAddress,
		uint256 rewardTokenEmission,
		uint256 valueDivisor,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetRewardPoolUserTimestamp(
		address indexed holderContractAddress,
		address indexed rewardTokenContractAddress,
		address indexed accountAddress,
		uint256 timestampValue,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetLastLPTimeShareTimestamp(
		address indexed lpTokenAddress,
		uint256 indexed timestampValue,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetLastCummulativeSupplyLPTimeShare(
		address indexed lpTokenAddress,
		uint256 indexed newSupplyLPTimeShare,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event SetHolderAddressesForRewards(
		address[] holderContractAddresses,
		address[] rewardTokenContractAddress,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event RemoveHolderAddressesForRewards(
		address[] holderContractAddresses,
		uint256 timestamp
	);

	/**
	 * @dev Emitted
	 */
	event RemoveTokenContractsForRewards(
		address[] holderContractAddresses,
		address[] rewardTokenContractAddress,
		uint256 timestamp
	);

	/**
	 * @dev Emitted when contract addresses are set
	 */
	event SetStakeLPContract(address indexed stakeLPContract);
}
