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
import "./interfaces/IMigrationAdminV3.sol";
import "./libraries/Bech32.sol";

contract MigrationAdminV4 is
IMigrationAdminV3,
PausableUpgradeable,
AccessControlUpgradeable
{
    using Bech32 for string;

    //Private instances of contracts to handle Utokens
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

    /*
     * @dev Constructor for initializing the TokenWrapper contract.
	 * @param uAddress - address of the UToken contract.
	 * @param bridgeAdminAddress - address of the bridge admin.
	 * @param pauserAddress - address of the pauser admin.
	 * @param valueDivisor - valueDivisor set to 10^9.
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
    function setUTokensContract(address uAddress) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MA1");
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
    function setSTokensContract(address sAddress) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MA2");
        _sTokens = ISTokensV3(sAddress);
        emit SetSTokensContract(sAddress);
    }

    /*
     * @dev Set 'contract address', called for tokenWrapper smart contract
	 * @param sAddress: tokenWrapper contract address
	 *
	 * Emits a {SetTokenWrapperContract} event with '_contract' set to the tokenWrapper contract address.
	 *
	 */
    function setTokenWrapperContract(address tokenWrapperAddress) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MA3");
        _tokenWrapper = ITokenWrapperV5(tokenWrapperAddress);
        emit SetTokenWrapperContract(tokenWrapperAddress);
    }

    /**
	 * @dev Migrating tokens
	 * @param accountAddress: users address
	 * @param toChainAddress: cosmos address
	 *
	 * Emits a {SetFees} event with 'fee' set to the withdraw.
	 *
	 */
    function Migrate(address accountAddress, string memory toChainAddress, string memory toCosmosChainAddress)
    public
    virtual
    override
    returns (bool success)
    {
        require(accountAddress == _msgSender(), "MA5");
        //check if toChainAddress is valid address as per Bech32 Validation
        bool isAddressValid = toChainAddress.isBech32AddressValid(
            hrpBytes,
            controlDigitBytes,
            dataBytesSize
        );
        require(isAddressValid == true, "MA6");

        bool isCosmosAddressValid = toCosmosChainAddress.isBech32AddressValid(
            cosmosHrpBytes,
            controlDigitBytes,
            dataBytesSize
        );
        require(isAddressValid == true, "MA11");

        //claim pending rewards
        _sTokens.calculateRewards(accountAddress);
        emit ClaimPendingRewardsEvent(accountAddress);

        //withdraw uTokens
        // require user to hold enough UTokens balance
        uint256 currentUTokenBalance = _uTokens.balanceOf(accountAddress);
        _tokenWrapper.withdrawUTokens(accountAddress, currentUTokenBalance, toCosmosChainAddress);
        emit WithdrawUTokensEvent(accountAddress, currentUTokenBalance, toChainAddress);
        return true;
    }

    /**
     * @dev Triggers stopped state.
	 *
	 */
    function pause() public virtual override returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "MA7");
        _pause();
        return true;
    }

    /**
     * @dev Returns to normal state.
	 *
	 */
    function unpause() public virtual override returns (bool success) {
        require(hasRole(PAUSER_ROLE, _msgSender()), "MA8");
        _unpause();
        return true;
    }

    /*
     * @dev Set 'hrp bytes', called to check bech32 address
	 * @param _hrpBytes: persistence bech32 prefix
	 */
    function setHRPBytes(bytes memory _hrpBytes) public virtual override returns (bool success) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MA9");
        hrpBytes = _hrpBytes;
        return true;
    }

    /*
     * @dev Set 'hrp bytes', called to check bech32 address
	 * @param _hrpBytes: bech32 prefix
	 */
    function setCosmosHRPBytes(bytes memory _hrpBytes) public virtual override returns (bool success) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MA10");
        cosmosHrpBytes = _hrpBytes;
        return true;
    }
}
