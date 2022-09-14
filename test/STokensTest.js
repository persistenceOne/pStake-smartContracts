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
const {
  BN,
  constants,
  expectEvent,
  expectRevert,
} = require("@openzeppelin/test-helpers");
const { expect } = require("chai");

const LiquidStaking = artifacts.require("LiquidStakingV4");
const TokenWrapper = artifacts.require("TokenWrapperV6");
/*const sTokens = artifacts.require('STokens');
const uTokens = artifacts.require('UTokens');*/

const sTokens = artifacts.require("STokensV5");
const uTokens = artifacts.require("UTokensV2");

let defaultAdmin = "0xc997A90252c829c8B66a9b26d84C0356c13fcE2E";
let bridgeAdmin = "0xc997A90252c829c8B66a9b26d84C0356c13fcE2E";
let pauseAdmin = "0xc997A90252c829c8B66a9b26d84C0356c13fcE2E";
let to = "0x8Ce9260b463D82bE50Febed422f09F413d5BE13e";
let unknownAddress = "0x98EB5E11e8b587DA1E19E3173fFc3a7961943e12";

describe("STokens", () => {
  let amount = new BN(200);
  let rewardRate = new BN(3000000);
  let _rewardRate = new BN(3000000);
  let rewardDivisor = new BN(1000000000);
  let epochInterval = "259200"; //3 days
  let unstakingLockTime = "1814400"; // 21 days
  let utokens;
  let stokens;
  let liquidStaking;
  let tokenWrapper;
  beforeEach(async function () {
    // this.project = await TestHelper()

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
  describe("Set smart contract address", function () {
    it("Set uToken contract address: ", async function () {
      await stokens.setUTokensContract(utokens.address, { from: defaultAdmin });
      // TEST SCENARIO END
    }, 200000);

    it("Set liquidStaking contract address: ", async function () {
      await stokens.setLiquidStakingContract(liquidStaking.address, {
        from: defaultAdmin,
      });
      // TEST SCENARIO END
    }, 200000);

    it("Non owner can set sToken contract address: ", async function () {
      await expectRevert(
        stokens.setUTokensContract(utokens.address, { from: unknownAddress }),
        "ST8"
      );
      // TEST SCENARIO END
    }, 200000);

    it("Non owner can set liquidStaking contract address: ", async function () {
      await expectRevert(
        stokens.setLiquidStakingContract(liquidStaking.address, {
          from: unknownAddress,
        }),
        "ST9"
      );
      // TEST SCENARIO END
    }, 200000);
  });

  describe("Calculate Pending Rewards", function () {
    it("Reward returned should be 0 after claiming rewards", async function () {
      let pendingRewards = await stokens.calculatePendingRewards(to, {
        from: defaultAdmin,
      });
      expect(pendingRewards == 0);
    }, 200000);
  });

  describe("Calculate Rewards", function () {
    it("Only user can call this function", async function () {
      await stokens.calculateRewards(to, {
        from: to,
      });
    }, 200000);

    it("Unauthorised user cannot call this function", async function () {
      await expectRevert(
        stokens.calculateRewards(to, {
          from: defaultAdmin,
        }),
        "ST5"
      );
    }, 200000);
  });

  describe("Pausable", function () {
    it("Only pauser admin can pause contracts", async function () {
      await stokens.pause({ from: pauseAdmin });
      let checkPause = await stokens.paused();
      expect(checkPause === true);
    });

    it("Non pauser admin cannot pause contracts", async function () {
      await expectRevert(stokens.pause({ from: unknownAddress }), "ST16");
    });

    it("Transactions could not be sent to paused contracts", async function () {
      await stokens.pause({ from: pauseAdmin });
      let checkPause = await stokens.paused();
      expect(checkPause === false);
      await expectRevert(
        stokens.calculateRewards(liquidStaking.address, { from: defaultAdmin }),
        "Pausable: paused"
      );
    });

    it("Only pauser admin can unpause contracts", async function () {
      await stokens.pause({ from: pauseAdmin });
      let checkPause = await stokens.paused();
      expect(checkPause === true);

      await stokens.unpause({ from: pauseAdmin });
      checkPause = await stokens.paused();
      expect(checkPause === false);
    });

    it("Non pauser admin cannot unpause contracts", async function () {
      await expectRevert(stokens.unpause({ from: unknownAddress }), "ST17");
    });
  });
});
