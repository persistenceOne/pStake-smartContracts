// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract VestingTimelock is ReentrancyGuardUpgradeable, PausableUpgradeable, AccessControlUpgradeable{
    
    // including libraries
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // ERC20 basic token contract being held
    IERC20Upgradeable _token;
    
    // Struct to hold vesting program
    struct Grant {
        uint256 startTime;
        uint256 amount;
        uint256 vestingCliff;
        address recipient;
        bool isActive;
    }

    mapping (address => Grant) public vestingGrants;
    uint256 public totalVestedHistory;
    uint256 public totalVestingAmount;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    event GrantAdded(address indexed recipient, uint256 grantNumber, uint256 timestamp);
    event GrantClaimed(address indexed recipient, uint256 amount, uint256 timestamp);
    event GrantRevoked(address indexed recipient, uint256 timestamp);


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
     * @dev get the details vesting program for a user
     */
     function getGrant(address grantedAddress_) public view returns (uint256 startTime,
        uint256 amount,
        uint256 vestingCliff,    
        address recipient, bool isActive)
    {
        Grant memory _grant = vestingGrants[grantedAddress_];
        startTime = _grant.startTime;
        amount = _grant.amount;
        vestingCliff = _grant.vestingCliff;
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

        token().safeTransfer(beneficiary_, _amount);
    }

    /**
     * @notice Transfers tokens held by beneficiary to timelock.
     */
    function _addGrant(
        uint256 _startTime,
        uint256 _amount,
        uint256 _vestingCliff,    
        address _recipient
    ) 
        internal
    {
        require(_amount > 0, "VestingTimelock: amount is zero");
        require(_startTime <= _vestingCliff, "VestingTimelock: cliff before start time");

        // allow adding grants whose vesting schedule is already realized, so commented below line
        // require(_vestingCliff >= block.timestamp, "VestingTimelock: vesting cliff is in the past");

        Grant memory _grant = vestingGrants[_recipient];
        require(!_grant.isActive, "VestingTimelock: grant already active");

        Grant memory grant = Grant({
            startTime: _startTime,
            amount: _amount,
            vestingCliff: _vestingCliff,
            recipient: _recipient,
            isActive: true
        });

        totalVestedHistory = totalVestedHistory.add(1);
        totalVestingAmount = totalVestingAmount.add(_amount);
        vestingGrants[_recipient] = grant;
    }

    /**
     * @notice Transfers tokens held by beneficiary to timelock.
     */
    function addGrant(
        uint256 _startTime,
        uint256 _amount,
        uint256 _vestingCliff,    
        address _recipient
    ) 
        public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "VestingTimelock: User not authorised for this action");
        _addGrant(
         _startTime,
         _amount,
         _vestingCliff,    
         _recipient
    );
        emit GrantAdded(_recipient, totalVestedHistory, block.timestamp);

    }

    /**
     * @notice Transfers tokens held by beneficiary to timelock.
     */
    function addGrants(
        uint256[] calldata _startTimes,
        uint256[] calldata _amounts,
        uint256[] calldata _vestingCliffs,    
        address[] calldata _recipients
    ) 
        public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "VestingTimelock: User not authorised for this action");
        require(_recipients.length > 0 && _recipients.length == _amounts.length && _startTimes.length == _amounts.length && _startTimes.length == _vestingCliffs.length, "VestingTimelock: invalid array size");

        // allocate the grants to the respective addresses
        uint256 i;
        for (i=0; i<_recipients.length; i++) {
            _addGrant(
                    _startTimes[i],
                    _amounts[i],
                    _vestingCliffs[i],    
                    _recipients[i]
            );
            
        }

        emit GrantAdded(_recipients[i.sub(1)], totalVestedHistory, block.timestamp);

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
        totalVestedHistory = totalVestedHistory.sub(1);

        GrantRevoked(beneficiary_, block.timestamp);

        // transfer the erc20 token amount back to the vesting provider
        token().safeTransfer(vestingProvider_, _amount);

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
