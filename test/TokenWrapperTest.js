/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

//UNIT TEST

/* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
which we will be using for our unit testing. */

const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const {
  accounts,
  defaultSender,
  contract,
} = require("@openzeppelin/test-environment");
const {
  BN,
  constants,
  ether,
  expectEvent,
  expectRevert,
  balance,
} = require("@openzeppelin/test-helpers");
const { TestHelper } = require("zos");
// const { Contracts, ZWeb3 } = require("zos-lib");

// ZWeb3.initialize(web3.currentProvider);
const { expect } = require("chai");
const LiquidStaking = artifacts.require("LiquidStakingV4");
const TokenWrapper = artifacts.require("TokenWrapperV6");
const Bech32 = artifacts.require("Bech32Validation");
const sTokens = artifacts.require("STokensV5");
const uTokens = artifacts.require("UTokensV2");

const toChainAddress = "cosmos1dgtl8dqky0cucr9rlllw9cer9ysrkjnjagz5zp";
let defaultAdmin = "0x8Ac7B40083a9935B1d28f78D17Dd86F47686B62B";
let bridgeAdmin = "0x8Ac7B40083a9935B1d28f78D17Dd86F47686B62B";
let pauseAdmin = "0x8Ac7B40083a9935B1d28f78D17Dd86F47686B62B";
let to = "0xdeC25B5f0fF67b7Bf2098e1b6951c60192a7F372";
let toAddresses = [
  "0xe865528ba2cD33dFeb7cC26b9a23b2c68F87a943",
  "0xe828F629976009892c708201098f2319aE5Dcc59",
];
let unknownAddress = "0x98EB5E11e8b587DA1E19E3173fFc3a7961943e12";

describe("Token Wrapper", function () {
  this.timeout(0);
  let liquidStaking;
  let tokenWrapper;
  let bech32;
  let utokens;
  let stokens;
  let amt = new BN(150);
  let amount = new BN(200);
  let amounts = [new BN(100), new BN(200)];
  let val = new BN(50);
  let rate = new BN(2000000);
  let _rewardRate = new BN(3000000);
  let rewardDivisor = new BN(1000000000);
  let epochInterval = "259200"; //3 days
  let unstakingLockTime = "1814400"; // 21 days
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
    await stokens.setRewardRate(rate, { from: defaultAdmin });
  });

  describe("Bech32 Validation", function () {
    it("Validating bech32 Address.", async function () {
      let generate = await tokenWrapper.generateUTokens(to, amount, {
        from: bridgeAdmin,
      });
      let balance = await utokens.balanceOf(to);
      expect(balance == amount);
      expectEvent(generate, "GenerateUTokens", {
        accountAddress: to,
        tokens: amount,
      });

      let withdraw = await tokenWrapper.withdrawUTokens(
        to,
        val,
        toChainAddress,
        { from: to }
      );
      const gasUsed = generate.receipt.gasUsed;
      console.log("gasUsed: ", gasUsed);
      console.log("withdraw: ", withdraw);
      expectEvent(withdraw, "WithdrawUTokens", {
        accountAddress: to,
        tokens: val,
      });
    });
  });

  describe("uTokens", function () {
    it("Only bridge admin can mint new uTokens for a user.", async function () {
      let generate = await tokenWrapper.generateUTokens(to, amount, {
        from: bridgeAdmin,
      });
      let balance = await utokens.balanceOf(to);
      expect(balance == amount);
      expectEvent(generate, "GenerateUTokens", {
        accountAddress: to,
        tokens: amount,
      });
    });

    it("Number of tokens should be greater than 0", async function () {
      let val = new BN(0);
      await expectRevert(
        tokenWrapper.generateUTokens(to, val, { from: bridgeAdmin }),
        "TW13"
      );
    });

    it("Non bridge admin cannot mint new tokens for a user", async function () {
      await expectRevert(
        tokenWrapper.generateUTokens(to, amount, { from: unknownAddress }),
        "TW10"
      );
    });
  });

  describe("Generate UTokens in Batch", function () {
    it("Bridge admin wont be able to deposit any ATOM", async function () {
      await tokenWrapper.revokeRole(
        "0x751b795d24b92e3d92d1d0d8f2885f4e9c9c269da350af36ae6b49069babf4bf",
        bridgeAdmin,
        { from: defaultAdmin }
      );
      await expectRevert(
        tokenWrapper.generateUTokensInBatch(toAddresses, amounts, {
          from: bridgeAdmin,
        }),
        "TW12"
      );
    }, 200000);
    it("Any other address calling this function", async function () {
      await expectRevert(
        tokenWrapper.generateUTokensInBatch(toAddresses, amounts, {
          from: unknownAddress,
        }),
        "TW12"
      );
    }, 200000);
    it("Address and token length mismatch", async function () {
      await expectRevert(
        tokenWrapper.generateUTokensInBatch(toAddresses, [new BN(100)], {
          from: bridgeAdmin,
        }),
        "TW11"
      );
    }, 200000);
  });

  describe("Pausable", function () {
    it("Only pauser admin can pause contracts", async function () {
      await tokenWrapper.pause({ from: pauseAdmin });
      let checkPause = await tokenWrapper.paused();
      expect(checkPause === true);
    });

    it("Non pauser admin cannot pause contracts", async function () {
      await expectRevert(tokenWrapper.pause({ from: unknownAddress }), "TW7");
    });

    // it("Transactions could not be sent to paused contracts", async function () {
    //   await tokenWrapper.pause({ from: pauseAdmin });
    //   let checkPause = await tokenWrapper.paused();
    //   expect(checkPause === true);
    //   console.log({ checkPause });
    //   await expectRevert.unspecified(
    //     tokenWrapper.generateUTokens(to, val, { from: bridgeAdmin })
    //   );
    // }, 200000);

    it("Only pauser admin can unpause contracts", async function () {
      await tokenWrapper.pause({ from: pauseAdmin });
      let checkPause = await tokenWrapper.paused();
      expect(checkPause === true);

      await tokenWrapper.unpause({ from: pauseAdmin });
      checkPause = await tokenWrapper.paused();
      expect(checkPause === false);
    });

    it("Non pauser admin cannot unpause contracts", async function () {
      await expectRevert(tokenWrapper.unpause({ from: unknownAddress }), "TW8");
    });
  });
});
