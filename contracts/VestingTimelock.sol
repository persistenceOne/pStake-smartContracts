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
 * after 1 year"
 */
contract VestingTimelock is ReentrancyGuardUpgradeable, PausableUpgradeable, AccessControlUpgradeable{
    
    // including libraries
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // ERC20 basic token contract being held
    IERC20Upgradeable _token;
    
    // Struct to hold vesting grant
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


    function __VestingTimelock_init(IERC20Upgradeable token_, address pauserAddress_) internal initializer {
        __VestingTimelock_init_unchained(token_, pauserAddress_);
    }

    function __VestingTimelock_init_unchained(IERC20Upgradeable token_, address pauserAddress_) internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, pauserAddress_);
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
     function getGrant(address beneficiary_) public view returns (uint256 startTime,
        uint256 amount,
        uint256 vestingCliff,    
        address recipient, bool isActive)
    {
        Grant memory _grant = vestingGrants[beneficiary_];
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

         // check whether the grant is active
        require(_grant.isActive, "VestingTimelock: Grant is not active");

        // check whether the amount is not zero
        uint256 _amount = _grant.amount;
        require(_amount > 0, "VestingTimelock: no tokens to release");

        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _grant.vestingCliff, "VestingTimelock: Grant still vesting");

        // reset all the grant detail variables to zero
        delete vestingGrants[beneficiary_];
        totalVestingAmount = totalVestingAmount.sub(_amount);
        GrantClaimed(beneficiary_, _amount, block.timestamp);

        token().safeTransfer(beneficiary_, _amount);
    }

    /**
     * @notice Transfers tokens held by beneficiary to timelock.
     */
    function _addGrant(
        uint256 startTime_,
        uint256 amount_,
        uint256 vestingCliff_,    
        address recipient_
    ) 
        internal
    {
        require(amount_ > 0, "VestingTimelock: amount is zero");
        require(startTime_ <= vestingCliff_, "VestingTimelock: cliff before start time");

        // allow adding grants whose vesting schedule is already realized, so commented below line
        // require(vestingCliff_ >= block.timestamp, "VestingTimelock: vesting cliff is in the past");

        Grant memory _grant = vestingGrants[recipient_];
        require(!_grant.isActive, "VestingTimelock: grant already active");

        Grant memory grant = Grant({
            startTime: startTime_,
            amount: amount_,
            vestingCliff: vestingCliff_,
            recipient: recipient_,
            isActive: true
        });

        totalVestedHistory = totalVestedHistory.add(1);
        totalVestingAmount = totalVestingAmount.add(amount_);
        vestingGrants[recipient_] = grant;
    }

    /**
     * @notice Transfers tokens held by beneficiary to timelock.
     */
    function addGrant(
        uint256 startTime_,
        uint256 amount_,
        uint256 vestingCliff_,    
        address recipient_
    ) 
        public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "VestingTimelock: Unauthorized User");
        _addGrant(
         startTime_,
         amount_,
         vestingCliff_,    
         recipient_
    );
        emit GrantAdded(recipient_, totalVestedHistory, block.timestamp);

    }

    /**
     * @notice Transfers tokens held by beneficiary to timelock.
     */
    function addGrants(
        uint256[] calldata startTimes_,
        uint256[] calldata amounts_,
        uint256[] calldata vestingCliffs_,    
        address[] calldata recipients_
    ) 
        public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "VestingTimelock: Unauthorized User");
        require(recipients_.length > 0 && recipients_.length == amounts_.length && startTimes_.length == amounts_.length && startTimes_.length == vestingCliffs_.length, "VestingTimelock: invalid array size");

        // allocate the grants to the respective addresses
        uint256 i;
        for (i=0; i<recipients_.length; i++) {
            _addGrant(
                    startTimes_[i],
                    amounts_[i],
                    vestingCliffs_[i],    
                    recipients_[i]
            );
            
        }

        // emit the data of last grant that was added
        emit GrantAdded(recipients_[i.sub(1)], totalVestedHistory, block.timestamp);

    }

    /**
     * @notice revokeGrant tokens held by timelock to beneficiary.
     */
    function revokeGrant(address beneficiary_, address vestingProvider_) external nonReentrant {
        // revoke currently doesnt return the ERC20 tokens sent to this contract
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "VestingTimelock: Unauthorized User");

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
