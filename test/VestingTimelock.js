//UNIT TEST

/* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
which we will be using for our unit testing. */
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const { accounts, contract } = require("@openzeppelin/test-environment");
const { BN, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { TestHelper } = require("zos");
const { Contracts, ZWeb3 } = require("zos-lib");

ZWeb3.initialize(web3.currentProvider);
const UstkXPRT = artifacts.require("UstkXPRT");
const VestingTimeLock = artifacts.require("VestingTimelock");

let amount = new BN(200);
let zeroAmount = new BN(0);
let num = new BN(1);

let bridgeAdmin = "0x0Af71f1Fc52E98704C34C260bc888628b6eC647A";
let pauserAdmin = "0x0eE5F1E11fEB686641536845118D97b8A8aAE08E";
let pstkTreasury = "0x7b481c7A3F3CB4bd0FDe74ac7E1C76656c661762";
let vestingProvider = "0x7b481c7A3F3CB4bd0FDe74ac7E1C76656c661762";
let from = "0xd8c10B62305DD79F96128Fe689C53a3528871CA1";
let ustkXPRTContractAddress = "0x04AE194386F89Abf5Fe91a3521353ea92D0EAbf8";
let unknownAddress = "0xf1DD002Aa88847e7fb5e5B9326C9d4f46E929bD6";
let receipientUnique = [
  "0x4e3816DfA5a64811a95dA2dA9723b2a8938daD59",
  "0x2a6FA0465ea77199f72B5638e970b2F30B3572d1",
  "0x1F6bbB4f5A16F85E118d9538C81819a882731Cf2",
];
let receipientNotUnique = [
  "0x4e3816DfA5a64811a95dA2dA9723b2a8938daD59",
  "0x2a6FA0465ea77199f72B5638e970b2F30B3572d1",
  "0x4e3816DfA5a64811a95dA2dA9723b2a8938daD59",
];
let startTime = [1617088748, 1617088748, 1617088748];
let cliff = [1627775999, 1627775999, 1627775999];
let amountArray = [amount, amount, amount];

describe("VestingTimeLock", () => {
  let timeLock, ustkXPRT;

  beforeEach(async function () {
    this.project = await TestHelper();

    ustkXPRT = await deployProxy(
      UstkXPRT,
      [bridgeAdmin, pauserAdmin, pstkTreasury],
      { initializer: "initialize" }
    );

    timeLock = await deployProxy(
      VestingTimeLock,
      [ustkXPRT.address, pauserAdmin],
      { initializer: "initialize" }
    );

    await ustkXPRT.transfer(timeLock.address, 60000, { from: pstkTreasury });
  });

  describe("Token", function () {
    it("Returns the token being held", async function () {
      let token = await timeLock.token();
      expect(token === ustkXPRTContractAddress);
      // TEST SCENARIO END
    }, 200000);
  });
  describe("Pausable", function () {
    it("Only pauser admin can pause contracts", async function () {
      await timeLock.pause({ from: pauserAdmin });
      let checkPause = await timeLock.paused();
      expect(checkPause === true);
    });

    it("Non pauser admin cannot pause contracts", async function () {
      await expectRevert(
        timeLock.pause({ from: unknownAddress }),
        "VestingTimelock: Unauthorized User"
      );
    });

    it("Only pauser admin can unpause contracts", async function () {
      await timeLock.pause({ from: pauserAdmin });
      let checkPause = await timeLock.paused();
      expect(checkPause === true);

      await timeLock.unpause({ from: pauserAdmin });
      checkPause = await timeLock.paused();
      expect(checkPause === false);
    });

    it("Non pauser admin cannot unpause contracts", async function () {
      await expectRevert(
        timeLock.unpause({ from: unknownAddress }),
        "VestingTimelock: Unauthorized User"
      );
    });
  });

  describe("Add grant", function () {
    it("Unauthorized User", async function () {
      await expectRevert(
        timeLock.addGrant(1617088748, amount, 1627775999, from, {
          from: unknownAddress,
        }),
        "VestingTimelock: Unauthorized User"
      );
    }, 200000);

    it("Amount cannot be zero", async function () {
      await expectRevert(
        timeLock.addGrant(1617088748, zeroAmount, 1627775999, from, {
          from: from,
        }),
        "VestingTimelock: No tokens to add"
      );
    }, 200000);

    it("cliff before start time", async function () {
      await expectRevert(
        timeLock.addGrant(1617235199, amount, 1614556800, from, { from: from }),
        "VestingTimelock: cliff before start time"
      );
    }, 200000);

    it("Grant already active", async function () {
      let add = await timeLock.addGrant(1617088748, amount, 1627775999, from, {
        from: from,
      });
      expectEvent(add, "GrantAdded", {
        benificiary: from,
        grantNumber: num,
      });

      await expectRevert(
        timeLock.addGrant(1617088748, amount, 1627775999, from, { from: from }),
        "VestingTimelock: grant already active"
      );
    }, 200000);

    it("Only default admin can add grant", async function () {
      let add = await timeLock.addGrant(1617088748, amount, 1627775999, from, {
        from: from,
      });

      expectEvent(add, "GrantAdded", {
        benificiary: from,
        grantNumber: num,
      });
    }, 200000);

    it("Get grant", async function () {
      let add = await timeLock.addGrant(1617088748, amount, 1627775999, from, {
        from: from,
      });
      expectEvent(add, "GrantAdded", {
        benificiary: from,
        grantNumber: num,
      });
      let get = await timeLock.getGrant(from, { from: from });
      expect(get.isActive === true);
    }, 200000);

    describe("Add grants to multiple recipients", function () {
      it("Unauthorized User", async function () {
        await expectRevert(
          timeLock.addGrants(startTime, amountArray, cliff, receipientUnique, {
            from: unknownAddress,
          }),
          "VestingTimelock: Unauthorized User"
        );
      }, 200000);

      it("Invalid array size", async function () {
        await expectRevert(
          timeLock.addGrants(startTime, [amount], cliff, receipientUnique, {
            from: from,
          }),
          "VestingTimelock: invalid array size"
        );
      }, 200000);

      it("Cliff before start time", async function () {
        await expectRevert(
          timeLock.addGrants(cliff, amountArray, startTime, receipientUnique, {
            from: from,
          }),
          "VestingTimelock: cliff before start time"
        );
      }, 200000);

      it("Only default admin can add grants with unique recipients name", async function () {
        let add = await timeLock.addGrants(
          startTime,
          amountArray,
          cliff,
          receipientUnique,
          { from: from }
        );
      }, 200000);

      it("Add grants with non-unique recipients name", async function () {
        await expectRevert(
          timeLock.addGrants(
            startTime,
            amountArray,
            cliff,
            receipientNotUnique,
            { from: from }
          ),
          "VestingTimelock: grant already active"
        );
      }, 200000);
    });
  });

  describe("Claim grant", function () {
    it("Unauthorized User", async function () {
      await expectRevert(
        timeLock.claimGrant(from, { from: unknownAddress }),
        "VestingTimelock: Unauthorized User"
      );
    }, 200000);

    it("Grant is not active", async function () {
      await expectRevert(
        timeLock.claimGrant(from, { from: from }),
        "VestingTimelock: Grant is not active"
      );
    }, 200000);

    it("Grant still vesting", async function () {
      let add = await timeLock.addGrant(1617088748, amount, 1627775999, from, {
        from: from,
      });
      expectEvent(add, "GrantAdded", {
        benificiary: from,
        grantNumber: num,
      });
      await expectRevert(
        timeLock.claimGrant(from, { from: from }),
        "VestingTimelock: Grant still vesting"
      );
    }, 200000);
  });

  describe("Revoke grant", function () {
    it("Unauthorized User", async function () {
      await expectRevert(
        timeLock.revokeGrant(from, vestingProvider, { from: unknownAddress }),
        "VestingTimelock: Unauthorized User"
      );
    }, 200000);

    it("Grant is not active", async function () {
      await expectRevert(
        timeLock.revokeGrant(from, vestingProvider, { from: from }),
        "VestingTimelock: Grant is not active"
      );
    }, 200000);

    it("Revoke grant", async function () {
      let add = await timeLock.addGrant(1617088748, amount, 1627775999, from, {
        from: from,
      });
      expectEvent(add, "GrantAdded", {
        benificiary: from,
        grantNumber: num,
      });
      let revoke = await timeLock.revokeGrant(from, vestingProvider, {
        from: from,
      });
      expectEvent(revoke, "GrantRevoked", {
        benificiary: from,
        vestingProvider: vestingProvider,
      });
    }, 200000);

    describe("Revoke grants for multiple recipients", function () {
      it("Unauthorized User", async function () {
        await expectRevert(
          timeLock.revokeGrants(receipientUnique, vestingProvider, {
            from: unknownAddress,
          }),
          "VestingTimelock: Unauthorized User"
        );
      }, 200000);

      it("Invalid array size", async function () {
        await expectRevert(
          timeLock.revokeGrants([], vestingProvider, { from: from }),
          "VestingTimelock: invalid array size"
        );
      }, 200000);

      it("Grant is not active", async function () {
        await expectRevert(
          timeLock.revokeGrants(receipientUnique, vestingProvider, {
            from: from,
          }),
          "VestingTimelock: Grant is not active"
        );
      }, 200000);

      it("Revoke grants", async function () {
        await timeLock.addGrants(
          startTime,
          amountArray,
          cliff,
          receipientUnique,
          { from: from }
        );
        await timeLock.revokeGrants(receipientUnique, vestingProvider, {
          from: from,
        });
      }, 200000);
    });
  });
});
