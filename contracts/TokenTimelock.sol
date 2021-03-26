// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/TokenTimelockUpgradeable.sol";

contract TimeLock is ERC20Upgradeable, PausableUpgradeable, TokenTimelockUpgradeable {

    using SafeMathUpgradeable for uint256;

    mapping(address => uint256) supply;

    uint256 public _totalSupply = 100000000;
    //uint256 releaseTime = now + 6 months;

    address constant public address1 = 0x3F5fdb1c4B40b04f54082482DCBF9732c1199eB6;
    address constant public address2 = 0x528B19d24426C4A78D0fDC0933c3F91C87102adA;
    address constant public address3 = 0xe3355d5AD5f8dCdca879230e85eF0AaeE6f28d0B;
    address constant public address4 = 0x768D4C50C9D4Db6f12Bb47581E4c1823Ad9eCB49;
    address constant public address5 = 0x7019943Ca5E81d10EFA8ACdd68B0B67Eb4B0a9f6;


    /**
   * @dev Constructor for initializing the TimeLock contract.
   */
    function initialize() public virtual initializer {
        supply[address1] = 50000000;
        supply[address2] = 10000000;
        supply[address3] = 10000000;
        supply[address4] = 10000000;
        supply[address5] = 10000000;
        __ERC20_init("pSTAKE Staked ATOM", "stkATOM");
        __Pausable_init();
        // __TokenTimelock_init("", address2, (block.timestamp + 6 months));
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public virtual returns (bool success) {
        _pause();
        return true;
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public virtual returns (bool success) {
        _unpause();
        return true;
    }
}