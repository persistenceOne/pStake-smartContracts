// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract VestingTimelock is ReentrancyGuardUpgradeable, PausableUpgradeable, AccessControlUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;


    // ERC20 basic token contract being held
    IERC20Upgradeable immutable _token;
    uint256 private totalVestingHistory;
    uint256 private totalVestingAmount;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    event GrantAdded(address indexed recipient, uint256 grantNumber, uint256 timestamp);
    event GrantClaimed(address indexed recipient, uint256 amount, uint256 timestamp);
    event GrantRevoked(address indexed recipient, uint256 timestamp);


    // Struct to hold vesting program
    struct Grant {
        uint256 startTime;
        uint256 amount;
        uint256 vestingCliff;
        address recipient;
        bool isActive;
    }

    mapping (address => Grant) public vestingGrants;

    function __VestingTimelock_init(IERC20Upgradeable token_, address pauserAddress) internal initializer {
        __VestingTimelock_init_unchained(token_, pauserAddress);
    }

    function __VestingTimelock_init_unchained(IERC20Upgradeable token_, address pauserAddress) internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, pauserAddress);
        // solhint-disable-next-line not-rely-on-time
        _token = token_;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20Upgradeable) {
        return _token;
    }

    /**
     * @return the time when the tokens are released.
     */
     function getGrant(address grantedAddress_) public view returns (uint256 startTime,
        uint256 amount,
        uint256 vestingDuration,    
        address recipient, bool isActive)
    {
        Grant memory _grant = vestingGrants[grantedAddress_];
        startTime = _grant.startTime;
        amount = _grant.amount;
        vestingDuration = _grant.vestingDuration;
        recipient = _grant.recipient;
        isActive = _grant.isActive;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function claimGrant(address beneficiary_) external nonReentrant whenNotPaused {
        require(beneficiary_ == _msgSender(), "VestingTimelock: Unauthorized User");

        Grant memory _grant = vestingGrants[beneficiary_];

        // check whether the amount is not zero
        uint256 _amount = _grant.amount;
        require(_amount > 0, "VestingTimelock: no tokens to release");

        // check whether the grant is active
        require(_grant.isActive, "VestingTimelock: Grant is not active");

        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _grant.vestingCliff, "VestingTimelock: Grant still vesting");

        // deduct the grant amount from the struct to avoid Redundancy attack and reset other variables
        delete vestingGrants[beneficiary_];
        totalVestingAmount = totalVestingAmount.sub(_amount);
        GrantClaimed(beneficiary_, _amount, block.timestamp);

        token().safeTransfer(token(), beneficiary_, _amount);
    }

    /**
     * @notice Transfers tokens held by beneficiary to timelock.
     */
    function addGrant(
        uint256 _startTime,
        uint256 _amount,
        uint256 _vestingDuration,    
        address _recipient
    ) 
        public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "VestingTimelock: User not authorised for this action");
        require(_amount > 0, "VestingTimelock: amount is zero");

        // allow adding grants whose vesting schedule is already realized, so commented below line
        // require(_startTime + _vestingDuration >= block.timestamp, "VestingTimelock: vesting cliff is in the past");

        Grant memory _grant = vestingGrants[_recipient];
        require(!_grant.isActive, "VestingTimelock: grant already active");

        Grant memory grant = Grant({
            startTime: _startTime < block.timestamp ? currentTime() : _startTime,
            amount: _amount,
            vestingCliff: _startTime + _vestingDuration,
            recipient: _recipient,
            isActive: true
        });

        totalVestingHistory = totalVestingHistory.add(1);
        emit GrantAdded(_recipient, totalVestingHistory, block.timestamp);
        totalVestingAmount = totalVestingAmount.add(_amount);
        vestingGrants[_recipient] = _grant;
    }

    /**
     * @notice Transfers tokens held by beneficiary to timelock.
     */
    function addGrants(
        uint256[] _startTimes,
        uint256[] _amounts,
        uint256[] _vestingDurations,    
        address[] _recipients
    ) 
        public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "VestingTimelock: User not authorised for this action");

        // allow adding grants whose vesting schedule is already realized, so commented below line
        // require(_startTime + _vestingDurations >= block.timestamp, "VestingTimelock: vesting cliff is in the past");

        require(_recipients.length > 0 && _recipients.length == _amounts.length && _startTimes.length == _amounts.length && _startTimes.length == _vestingDurations.length, "VestingTimelock: invalid array size");

        // allocate the grants to the respective addresses
        uint256 i;
        Grant memory grant;
        for (i=0; i<_recipients.length; i++) {

        Grant memory _grant = vestingGrants[_recipient];
        require(!_grant.isActive, "VestingTimelock: grant already active");
        require(_amounts[i] > 0, "VestingTimelock: amount is zero");

        grant = Grant({
            startTime: _startTimes[i] < block.timestamp ? currentTime() : _startTime,
            amount: _amounts[i],
            vestingCliff: _startTimes[i] + _vestingDurations[i],
            recipient: _recipient,
            isActive: true
        });

        totalVestingHistory = totalVestingHistory.add(1);
        totalVestingAmount = totalVestingAmount.add(_amount);
        vestingGrants[_recipient] = _grant;
        }

        emit GrantAdded(_recipients[_recipients.length-1], totalVestingHistory-1, block.timestamp);

    }

    /**
     * @notice revokeGrant tokens held by timelock to beneficiary.
     */
    function revokeGrant(address beneficiary_, address vestingProvider_) external nonReentrant {
        // revoke currently doesnt return the ERC20 tokens sent to this contract
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "VestingTimelock: User not authorised for this action");

        Grant memory _grant = vestingGrants[beneficiary_];

        // check whether the grant is active
        require(_grant.isActive, "VestingTimelock: Grant is not active");

        uint256 _amount = _grant.amount;
        require(_amount > 0, "VestingTimelock: no tokens to revoke");

        // reset the grant
        delete vestingGrants[beneficiary_];
        totalVestingAmount = totalVestingAmount.sub(_amount);
        totalVestingHistory = totalVestingHistory.sub(1);

        GrantRevoked(beneficiary_, block.timestamp);

        // transfer the erc20 token amount back to the vesting provider
        token().safeTransfer(token(), vestingProvider_, _amount);

    }

     /**
      * @dev Triggers stopped state.
      *
      * Requirements:
      *
      * - The contract must not be paused.
      */
    function pause() public returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "VestingTimelock: User not authorised to pause contracts.");
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
    function unpause() public returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "VestingTimelock: User not authorised to unpause contracts.");
        _unpause();
        return true;
    }


    uint256[47] private __gap;
}
