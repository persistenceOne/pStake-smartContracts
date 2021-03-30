//UNIT TEST

/* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
which we will be using for our unit testing. */
const {web3} = require("@openzeppelin/test-helpers/src/setup");
const {
deployProxy,
} = require("@openzeppelin/truffle-upgrades");

const {
accounts,
contract,
} = require("@openzeppelin/test-environment");
const {
BN, expectEvent,
expectRevert,
} = require("@openzeppelin/test-helpers");
const { TestHelper } = require('zos');
const { Contracts, ZWeb3 } = require('zos-lib');

ZWeb3.initialize(web3.currentProvider);
const VestingTimeLock = artifacts.require('VestingTimelock');

let amount = new BN(200);
let zeroAmount = new BN(0);
let num = new BN(1);

let pauserAdmin = "0x54C9055d5D8fa3FF44776e8c78eFfadCDbaA85C2";
let vestingProvider = "0x4e3816DfA5a64811a95dA2dA9723b2a8938daD59";
let from = "0x16B1fEd555F4e6264E4829543309Eb923711Ad98";
let ustkXPRTContractAddress = "0x04AE194386F89Abf5Fe91a3521353ea92D0EAbf8";
let unknownAddress = "0xb05CCF5775343A2576a852c534Cf55E24E283882";
let receipientUnique = ["0x4e3816DfA5a64811a95dA2dA9723b2a8938daD59", "0x2a6FA0465ea77199f72B5638e970b2F30B3572d1", "0x1F6bbB4f5A16F85E118d9538C81819a882731Cf2"]
let receipientNotUnique = ["0x4e3816DfA5a64811a95dA2dA9723b2a8938daD59", "0x2a6FA0465ea77199f72B5638e970b2F30B3572d1", "0x4e3816DfA5a64811a95dA2dA9723b2a8938daD59"]
let startTime = [1617088748, 1617088748, 1617088748]
let cliff = [1627775999, 1627775999, 1627775999]
let amountArray = [amount, amount, amount]

describe('VestingTimeLock', () => {
    let timeLock;

    beforeEach(async function () {
        this.project = await TestHelper();

        timeLock = await deployProxy(VestingTimeLock, [ustkXPRTContractAddress, pauserAdmin], { initializer: 'initialize' });
    });

    describe("Token", function () {
        it("Returns the token being held", async function () {
            let token = await timeLock.token();
            expect(token === ustkXPRTContractAddress)
            // TEST SCENARIO END
        }, 200000);

    })
    describe("Pausable", function () {
        it('Only pauser admin can pause contracts', async function () {
            await timeLock.pause({from: pauserAdmin,});
            let checkPause = await timeLock.paused();
            expect(checkPause === true)
        });

        it('Non pauser admin cannot pause contracts', async function () {
            await expectRevert(timeLock.pause({from: unknownAddress,}), "VestingTimelock: User not authorised to pause contracts");
        });

        it('Only pauser admin can unpause contracts', async function () {
            await timeLock.pause({from: pauserAdmin,});
            let checkPause = await timeLock.paused();
            expect(checkPause === true)

            await timeLock.unpause({from: pauserAdmin,});
            checkPause = await timeLock.paused();
            expect(checkPause === false)
        });

        it('Non pauser admin cannot unpause contracts', async function () {
            await expectRevert(timeLock.unpause({from: unknownAddress,}), "VestingTimelock: User not authorised to unpause contracts");
        });
    });

    describe("Add grant", function () {
        it("Unauthorized User", async function () {
            await expectRevert(timeLock.addGrant(1617088748, amount, 1627775999, from, {from: unknownAddress,}), "VestingTimelock: Unauthorized User");
        }, 200000);

        it("Amount cannot be zero", async function () {
            await expectRevert(timeLock.addGrant(1617088748, zeroAmount, 1627775999, from, {from: from,}), "VestingTimelock: amount is zero");
        }, 200000);

        it("cliff before start time", async function () {
            await expectRevert(timeLock.addGrant(1617235199, amount, 1614556800, from, {from: from,}), "VestingTimelock: cliff before start time");
        }, 200000);

        it("Grant already active", async function () {
            let add = await timeLock.addGrant(1617088748, amount, 1627775999, from, {from: from,});
            expectEvent(add, "GrantAdded", {
                recipient:from,
                grantNumber: num,
            });

            await expectRevert(timeLock.addGrant(1617088748, amount, 1627775999, from, {from: from,}), "VestingTimelock: grant already active");
        }, 200000);

        it("Only default admin can add grant", async function () {
            let add = await timeLock.addGrant(1617088748, amount, 1627775999, from, {from: from,});

            expectEvent(add, "GrantAdded", {
                recipient:from,
                grantNumber: num,
            });
        }, 200000);

        it("Get grant", async function () {
            let add = await timeLock.addGrant(1617088748, amount, 1627775999, from, {from: from,});
            expectEvent(add, "GrantAdded", {
                recipient:from,
                grantNumber: num,
            });
            let get = await timeLock.getGrant(from, {from: from,});
            expect(get.isActive === true)

        }, 200000);

        describe("Add grants to multiple recipients", function () {
            it("Unauthorized User", async function () {
                await expectRevert(timeLock.addGrants(startTime, amountArray, cliff, receipientUnique, {from: unknownAddress,}), "VestingTimelock: Unauthorized User");
            }, 200000);

            it("Invalid array size", async function () {
                await expectRevert(timeLock.addGrants(startTime, [amount], cliff, receipientUnique, {from: from,}), "VestingTimelock: invalid array size");
            }, 200000);

            it("Cliff before start time", async function () {
                await expectRevert(timeLock.addGrants(cliff, amountArray, startTime, receipientUnique, {from: from,}), "VestingTimelock: cliff before start time");
            }, 200000);

            it("Only default admin can add grants with unique recipients name", async function () {
                let add = await timeLock.addGrants(startTime, amountArray, cliff, receipientUnique, {from: from,});
            }, 200000);

            it("Add grants with non-=unique recipients name", async function () {
                await expectRevert(timeLock.addGrants(startTime, amountArray, cliff, receipientNotUnique, {from: from,}), "VestingTimelock: grant already active");
            }, 200000);
        })
    })

    describe("Claim grant", function () {
        it("Unauthorized User", async function () {
            await expectRevert(timeLock.claimGrant(from, {from: unknownAddress,}), "VestingTimelock: Unauthorized User");
        }, 200000);

        it("Grant is not active", async function () {
            await expectRevert(timeLock.claimGrant(from, {from: from,}), "VestingTimelock: Grant is not active");
        }, 200000);

        /*it("No tokens to release", async function () {
            let add = await timeLock.addGrant(1617088748, amount, 1627775999, from, {from: from,});
            expectEvent(add, "GrantAdded", {
                recipient:from,
                grantNumber: num,
            });
            //await expectRevert(timeLock.claimGrant(from, {from: from,}), "VestingTimelock: No tokens to release");
        }, 200000);*/

        it("Grant still vesting", async function () {
            let add = await timeLock.addGrant(1617088748, amount, 1627775999, from, {from: from,});
            expectEvent(add, "GrantAdded", {
                recipient:from,
                grantNumber: num,
            });
            await expectRevert(timeLock.claimGrant(from, {from: from,}), "VestingTimelock: Grant still vesting");
        }, 200000);

        /*it("Claim grant", async function () {
            let add = await timeLock.addGrant(1617088748, amount, 1617088748, from, {from: from,});
            expectEvent(add, "GrantAdded", {
                recipient:from,
                grantNumber: num,
            });
            let claim = await timeLock.claimGrant(from, {from: from,})
            console.log("claim + " + JSON.stringify(claim))
        }, 200000);*/
    })

    describe("Revoke grant", function () {
        it("Unauthorized User", async function () {
            await expectRevert(timeLock.revokeGrant(from, vestingProvider, {from: unknownAddress,}), "VestingTimelock: Unauthorized User");
        }, 200000);

        it("Grant is not active", async function () {
            await expectRevert(timeLock.revokeGrant(from, vestingProvider, {from: from,}), "VestingTimelock: Grant is not active");
        }, 200000);

        /*it("No tokens to revoke", async function () {
            let add = await timeLock.addGrant(1617088748, amount, 1627775999, from, {from: from,});
            expectEvent(add, "GrantAdded", {
                recipient:from,
                grantNumber: num,
            });
            //await expectRevert(timeLock.revokeGrant(from, vestingProvider, {from: from,}), "VestingTimelock: No tokens to release");
        }, 200000);*/

        it("Revoke grant", async function () {
            let add = await timeLock.addGrant(1617088748, amount, 1627775999, from, {from: from,});
            expectEvent(add, "GrantAdded", {
                recipient:from,
                grantNumber: num,
            });
            let revoke = await timeLock.revokeGrant(from, vestingProvider, {from: from,});
            expectEvent(revoke, "GrantRevoked", {
                recipient:from,
                vestingProvider: vestingProvider,
            });

        }, 200000);
    })
})