/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

//UNIT TEST

/* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
which we will be using for our unit testing. */
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const { accounts, contract } = require("@openzeppelin/test-environment");
const { BN, expectRevert } = require("@openzeppelin/test-helpers");
const { TestHelper } = require("zos");
// const { Contracts, ZWeb3 } = require("zos-lib");

// ZWeb3.initialize(web3.currentProvider);
const LiquidStaking = artifacts.require("LiquidStakingV3");
const TokenWrapper = artifacts.require("TokenWrapperV6");
const sTokens = artifacts.require("STokensV3");
const uTokens = artifacts.require("UTokensV2");
const MigrationAdmin = artifacts.require("MigrationAdminV4");

// let defaultAdmin = "0xD796aD3ADAf2809EDB36e7E215b54Fee663F4DA3";
let defaultAdmin = "0xF023fBe07cb9Bb5F9A307FDCdf34D88b325CadB5";
// 0x98E58Ab9647B9f394AD0b79A069eCa350FD3fD09
let bridgeAdmin = "0x76C5411eBcf4c3D9511AD0b3aeb2a06D2c4415dF";
let pauseAdmin = "0xF023fBe07cb9Bb5F9A307FDCdf34D88b325CadB5";

let userAddress = "0x23A065FCd2c176e0AefDB7b3c94fA2D9B9E3e915";
let persistenceAddress = "cosmos12zjl6nn5zuhdz2quhw3vm8pue2g085kvqy3lt8";
let cosmosAddress = "cosmos12zjl6nn5zuhdz2quhw3vm8pue2g085kvqy3lt8";
let unknownAddress = "0x98EB5E11e8b587DA1E19E3173fFc3a7961943e12";

describe("Migration Admin", () => {
  let amount = new BN(200);
  let rewardRate = new BN(3000000);
  let _rewardRate = new BN(3000000);
  let rewardDivisor = new BN(1000000000);
  let epochInterval = "259200"; //3 days
  let unstakingLockTime = "1814400"; // 21 days
  let utokens;
  let stokens;
  let tokenWrapper;
  let liquidStaking;
  let migrationAdmin;
  beforeEach(async function () {
    // this.project = await TestHelper();

    utokens = await deployProxy(uTokens, [bridgeAdmin, pauseAdmin], {
      initializer: "initialize",
    });

    stokens = await deployProxy(
      sTokens,
      [utokens.address, pauseAdmin, _rewardRate, rewardDivisor],
      { initializer: "initialize" }
    );

    tokenWrapper = await deployProxy(
      TokenWrapper,
      [utokens.address, bridgeAdmin, pauseAdmin, rewardDivisor],
      { initializer: "initialize" }
    );

    liquidStaking = await deployProxy(
      LiquidStaking,
      [
        utokens.address,
        stokens.address,
        pauseAdmin,
        unstakingLockTime,
        epochInterval,
        rewardDivisor,
      ],
      { initializer: "initialize" }
    );

    migrationAdmin = await deployProxy(
      MigrationAdmin,
      [utokens.address, stokens.address, tokenWrapper.address, pauseAdmin],
      { initializer: "initialize" }
    );

    await utokens.setSTokenContract(stokens.address, { from: defaultAdmin });
    await utokens.setWrapperContract(tokenWrapper.address, {
      from: defaultAdmin,
    });
    await utokens.setLiquidStakingContract(liquidStaking.address, {
      from: defaultAdmin,
    });

    await stokens.setLiquidStakingContract(liquidStaking.address, {
      from: defaultAdmin,
    });
    await stokens.setRewardRate(rewardRate, { from: defaultAdmin });
  });

  describe("Migrate", function () {
    it("Only user can call this function", async function () {
      await migrationAdmin.Migrate(
        userAddress,
        persistenceAddress,
        cosmosAddress,
        { from: userAddress }
      );
    });
    it("Unauthorized user calling this function", async function () {
      await expectRevert(
        migrationAdmin.Migrate(userAddress, persistenceAddress, cosmosAddress, {
          from: unknownAddress,
        }),
        "MA5"
      );
    });
    it("Bech32 validation for persistence address", async function () {
      await expectRevert(
        migrationAdmin.Migrate(
          migrationAdmin.Migrate(userAddress, unknownAddress, cosmosAddress, {
            from: userAddress,
          }),
          "MA6"
        )
      );
    });
    it("Bech32 validation for cosmos address", async function () {
      await expectRevert(
        migrationAdmin.Migrate(
          migrationAdmin.Migrate(
            userAddress,
            persistenceAddress,
            unknownAddress,
            {
              from: userAddress,
            }
          ),
          "MA11"
        )
      );
    });
    it("After migration is successful, fetch balances and compare them with returned token amount", async function () {});
    it("Calling this function if all balances are 0", async function () {
      const sTokenBalance = await stokens.balanceOf(userAddress);
      const uTokenBalance = await utokens.balanceOf(userAddress);
      if (sTokenBalance === 0 && uTokenBalance === 0) {
        expectRevert.unspecified(
          migrationAdmin.Migrate(
            userAddress,
            persistenceAddress,
            cosmosAddress,
            { from: userAddress }
          )
        );
      }
    });
  });

  describe("Set smart contract address", function () {
    it("Only admin can set uToken contract address: ", async function () {
      await migrationAdmin.setUTokensContract(utokens.address, {
        from: defaultAdmin,
      });
      // TEST SCENARIO END
    }, 200000);

    it("Only admin can set sToken contract address: ", async function () {
      await migrationAdmin.setSTokensContract(stokens.address, {
        from: defaultAdmin,
      });
      // TEST SCENARIO END
    }, 200000);

    it("Only admin can set token wrapper contract address: ", async function () {
      await migrationAdmin.setTokenWrapperContract(tokenWrapper.address, {
        from: defaultAdmin,
      });
      // TEST SCENARIO END
    }, 200000);

    it("Non admin can set uToken contract address: ", async function () {
      await expectRevert(
        migrationAdmin.setUTokensContract(utokens.address, {
          from: unknownAddress,
        }),
        "MA1"
      );
      // TEST SCENARIO END
    }, 200000);

    it("Non admin can set sToken contract address: ", async function () {
      await expectRevert(
        migrationAdmin.setSTokensContract(stokens.address, {
          from: unknownAddress,
        }),
        "MA2"
      );
      // TEST SCENARIO END
    }, 200000);

    it("Non owner can set wrapper contract address: ", async function () {
      await expectRevert(
        migrationAdmin.setTokenWrapperContract(tokenWrapper.address, {
          from: unknownAddress,
        }),
        "MA3"
      );
      // TEST SCENARIO END
    }, 200000);
  });

  describe("Pausable", function () {
    it("Only pauser admin can pause contracts", async function () {
      await migrationAdmin.pause({ from: pauseAdmin });
      let checkPause = await migrationAdmin.paused();
      expect(checkPause === true);
    });

    it("Non pauser admin cannot pause contracts", async function () {
      await expectRevert(migrationAdmin.pause({ from: unknownAddress }), "MA7");
    });

    it("If already paused, and again calling pause function", async function () {
      await migrationAdmin.pause({ from: pauseAdmin });
      let checkPause = await migrationAdmin.paused();
      if (checkPause === true) {
        await expectRevert.unspecified(
          migrationAdmin.pause({ from: pauseAdmin })
        );
      }
    });

    it("Only pauser admin can unpause contracts", async function () {
      await migrationAdmin.pause({ from: pauseAdmin });
      let checkPause = await migrationAdmin.paused();
      expect(checkPause === true);

      await migrationAdmin.unpause({ from: pauseAdmin });
      checkPause = await migrationAdmin.paused();
      expect(checkPause === false);
    });

    it("Non pauser admin cannot unpause contracts", async function () {
      await expectRevert(
        migrationAdmin.unpause({ from: unknownAddress }),
        "MA8"
      );
    });
  });

  describe("Set HRP Bytes", function () {
    it("Only admin can call this function", async function () {
      await migrationAdmin.setHRPBytes(web3.utils.asciiToHex("cosmos"), {
        from: defaultAdmin,
      });
    });

    it("Unknown address calling this function", async function () {
      await expectRevert(
        migrationAdmin.setHRPBytes(web3.utils.asciiToHex("cosmos"), {
          from: unknownAddress,
        }),
        "MA9"
      );
    });
  });

  describe("Set CosmosHRP Bytes", function () {
    it("Only admin can call this function", async function () {
      await migrationAdmin.setCosmosHRPBytes(web3.utils.asciiToHex("cosmos"), {
        from: defaultAdmin,
      });
    });

    it("Unknown address calling this function", async function () {
      await expectRevert(
        migrationAdmin.setCosmosHRPBytes(web3.utils.asciiToHex("cosmos"), {
          from: unknownAddress,
        }),
        "MA10"
      );
    });
  });
});
