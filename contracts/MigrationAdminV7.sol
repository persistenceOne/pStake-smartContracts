/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IUTokensV3.sol";
import "./interfaces/ISTokensV3.sol";
import "./interfaces/ITokenWrapperV5.sol";
import "./interfaces/IMigrationAdminV4.sol";
import "./interfaces/ILiquidStakingV4.sol";
import "./libraries/Bech32.sol";

contract MigrationAdminV7 is
IMigrationAdminV4,
PausableUpgradeable,
AccessControlUpgradeable
{
    using Bech32 for string;

    //Private instances of contracts
    IUTokensV3 public _uTokens;
    ISTokensV3 public _sTokens;
    ITokenWrapperV5 public _tokenWrapper;

    // constants defining access control ROLES
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    //variables defining bech32 validation attributes
    bytes public hrpBytes;
    bytes public controlDigitBytes;
    uint256 public dataBytesSize;
    bytes public cosmosHrpBytes;

    //modifier to check only admin can call this function
    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MigrationAdmin: Only admin can call this");
        _;
    }

    //modifier to check only pauser admin can call this function
    modifier onlyPauserAdmin {
        require(hasRole(PAUSER_ROLE, _msgSender()), "MigrationAdmin: Only admin can call this");
        _;
    }

    // Liquid staking contract address
    address public override _liquidStakingContract;

    /*
     * @dev Constructor for initializing the TokenWrapper contract.
	 * @param uAddress - address of the UToken contract.
	 * @param sAddress - address of the SToken contract.
	 * @param tokenWrapperAddress - address of the Token Wrapper contract.
	 * @param pauserAddress - address of the pauser admin.
	 */
    function initialize(
        address uAddress,
        address sAddress,
        address tokenWrapperAddress,
        address pauserAddress
    ) public virtual initializer {
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, pauserAddress);
        setUTokensContract(uAddress);
        setSTokensContract(sAddress);
        setTokenWrapperContract(tokenWrapperAddress);
        // setting bech32 validation attributes
        hrpBytes = "cosmos";
        controlDigitBytes = "1";
        dataBytesSize = 38;
    }

    /*
     * @dev Set 'contract address', called for utokens smart contract
	 * @param sAddress: utoken contract address
	 *
	 * Emits a {SetUTokensContract} event with '_contract' set to the utoken contract address.
	 *
	 */
    function setUTokensContract(address uAddress) public virtual override onlyAdmin {
        _uTokens = IUTokensV3(uAddress);
        emit SetUTokensContract(uAddress);
    }

    /*
     * @dev Set 'contract address', called for stokens smart contract
	 * @param sAddress: stoken contract address
	 *
	 * Emits a {SetSTokensContract} event with '_contract' set to the stoken contract address.
	 *
	 */
    function setSTokensContract(address sAddress) public virtual override onlyAdmin {
        _sTokens = ISTokensV3(sAddress);
        emit SetSTokensContract(sAddress);
    }

    /*
     * @dev Set 'contract address', called for tokenWrapper smart contract
	 * @param tokenWrapperAddress: tokenWrapper contract address
	 *
	 * Emits a {SetTokenWrapperContract} event with '_contract' set to the tokenWrapper contract address.
	 *
	 */
    function setTokenWrapperContract(address tokenWrapperAddress) public virtual override onlyAdmin {
        _tokenWrapper = ITokenWrapperV5(tokenWrapperAddress);
        emit SetTokenWrapperContract(tokenWrapperAddress);
    }

    /*
     * @dev Set 'contract address', called for liquid staking smart contract
	 * @param liquidStakingAddress: liquid staking contract address
	 *
	 * Emits a {SetLiquidStakingContract} event with '_contract' set to the liquid staking contract address.
	 *
	 */
    function setLiquidStakingContract(address liquidStakingAddress) public virtual override onlyAdmin {
        _liquidStakingContract = liquidStakingAddress;
        emit SetLiquidStakingContract(liquidStakingAddress);
    }

    /**
	 * @dev Migrating tokens
	 * @param accountAddress: users address
	 * @param toCosmosChainAddress: cosmos address
	 *
	 * Emits a {SetMigrationCompleteEvent} event.
	 *
	 */
    function Migrate(address accountAddress, string memory toCosmosChainAddress)
    public
    virtual
    override
    returns (bool success)
    {
        require(accountAddress == _msgSender(), "MigrationAdmin: Unauthorised user");

        bool isCosmosAddressValid = toCosmosChainAddress.isBech32AddressValid(
            cosmosHrpBytes,
            controlDigitBytes,
            dataBytesSize
        );
        require(isCosmosAddressValid == true, "MigrationAdmin: Invalid cosmos address");

        //claim pending rewards
        _sTokens.calculateRewards(accountAddress);
        emit ClaimPendingRewardsEvent(accountAddress);

        //claim unbonded tokens only when token amount is greater than 0
        uint256 currentUnbondedTokens = ILiquidStakingV4(_liquidStakingContract).getTotalUnbondedTokens(accountAddress);
        if(currentUnbondedTokens > 0){
            ILiquidStakingV4(_liquidStakingContract).withdrawUnstakedTokens(accountAddress);
            emit ClaimUnbondedRewardsEvent(accountAddress);
        }

        //withdraw uTokens
        // require user to hold enough UTokens balance
        uint256 currentUTokenBalance = _uTokens.balanceOf(accountAddress);

        //check if UToken balance is more than 0
        if(currentUTokenBalance > 0){
            _tokenWrapper.withdrawUTokens(accountAddress, currentUTokenBalance, toCosmosChainAddress);
            emit WithdrawUTokensEvent(accountAddress, currentUTokenBalance, toCosmosChainAddress);
        }
        emit SetMigrationCompleteEvent(accountAddress, currentUTokenBalance, toCosmosChainAddress);
        return true;
    }

    /**
     * @dev Triggers stopped state.
	 *
	 */
    function pause() public virtual override onlyPauserAdmin returns (bool success) {
        _pause();
        return true;
    }

    /**
     * @dev Returns to normal state.
	 *
	 */
    function unpause() public virtual override onlyPauserAdmin returns (bool success) {
        _unpause();
        return true;
    }

    /*
     * @dev Set 'hrp bytes', called to check bech32 persistence address
	 * @param _hrpBytes: persistence bech32 prefix
	 */
    function setHRPBytes(bytes memory _hrpBytes) public virtual override onlyAdmin returns (bool success) {
        hrpBytes = _hrpBytes;
        return true;
    }

    /*
     * @dev Set 'hrp bytes', called to check bech32 cosmos address
	 * @param _hrpBytes: cosmos bech32 prefix
	 */
    function setCosmosHRPBytes(bytes memory _hrpBytes) public virtual override onlyAdmin returns (bool success) {
        cosmosHrpBytes = _hrpBytes;
        return true;
    }
}
