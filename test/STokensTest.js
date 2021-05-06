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
    BN,
    constants,
    expectEvent,
    expectRevert,
} = require("@openzeppelin/test-helpers");
const { TestHelper } = require('zos');
const { Contracts, ZWeb3 } = require('zos-lib');

ZWeb3.initialize(web3.currentProvider);

const LiquidStaking = artifacts.require('LiquidStaking');
const TokenWrapper = artifacts.require('TokenWrapper');
/*const sTokens = artifacts.require('STokens');
const uTokens = artifacts.require('UTokens');*/

const sTokens = artifacts.require('STokens');
const uTokens = artifacts.require('UTokens');

let defaultAdmin = "0xF45b7d1DF227887Da9E8C1dD7f39C5131A3c0C0A";
let bridgeAdmin = "0x4b6365B9A20bEdb0528989DE2b837E6fA9D53A04";
let pauseAdmin = "0x31B94bb5085AF4c60e2354A94c3E69912A26F082";
let to = "0x78Dc60A2d97eE1681A8Eb2d7651037f627929d8C";
let unknownAddress = "0xf9f06Cd23e1fb23e5e180De7Fd3A32dD216505F1";


describe('STokens', () => {
    let amount = new BN(200);
    let rewardRate = new BN(3000000);
    let utokens;
    let stokens;
    let liquidStaking;
    let tokenWrapper;
    beforeEach(async function () {
        this.project = await TestHelper()

        utokens = await deployProxy(uTokens, [bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        stokens = await deployProxy(sTokens, [utokens.address, pauseAdmin, rewardRate], { initializer: 'initialize' });

        tokenWrapper = await deployProxy(TokenWrapper, [utokens.address, bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        liquidStaking = await deployProxy(LiquidStaking, [utokens.address, stokens.address, tokenWrapper.address, bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        await utokens.setSTokenContract(stokens.address,{from: defaultAdmin})
        await utokens.setWrapperContract(tokenWrapper.address,{from: defaultAdmin})
        await utokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})

        await stokens.setWrapperContract(tokenWrapper.address,{from: defaultAdmin})
        await stokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})
    });
    describe("Set smart contract address", function () {

        it("Set uToken contract address: ", async function () {
            await stokens.setUTokensContract(utokens.address,{from: defaultAdmin,});
            // TEST SCENARIO END
        }, 200000);

        it("Set wrapper contract address: ", async function () {
            await stokens.setWrapperContract(tokenWrapper.address,{from: defaultAdmin,});
            // TEST SCENARIO END
        }, 200000);

        it("Set liquidStaking contract address: ", async function () {
            await stokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin,});
            // TEST SCENARIO END
        }, 200000);

        it("Non owner can set sToken contract address: ", async function () {
            await expectRevert(stokens.setUTokensContract(utokens.address,{from: unknownAddress,}), "STokens: User not authorised to set UToken contract");
            // TEST SCENARIO END
        }, 200000);

        it("Non owner can set wrapper contract address: ", async function () {
            await expectRevert(stokens.setWrapperContract(tokenWrapper.address,{from: unknownAddress,}), "STokens: User not authorised to set wrapper contract");
            // TEST SCENARIO END
        }, 200000);

        it("Non owner can set liquidStaking contract address: ", async function () {
            await expectRevert(stokens.setLiquidStakingContract(liquidStaking.address,{from: unknownAddress,}), "STokens: User not authorised to set liquidStaking contract");
            // TEST SCENARIO END
        }, 200000);
    });

    describe("Pausable", function () {
        it('Only pauser admin can pause contracts', async function () {
            await stokens.pause({from: pauseAdmin,});
            let checkPause = await stokens.paused();
            expect(checkPause === true)
        });

        it('Non pauser admin cannot pause contracts', async function () {
            await expectRevert(stokens.pause({from: unknownAddress,}), "STokens: User not authorised to pause contracts");
        });

        it('Transactions could not be sent to paused contracts', async function () {
            await stokens.pause({from: pauseAdmin,});
            let checkPause = await stokens.paused();
            expect(checkPause === false)
            await expectRevert(stokens.calculateRewards(liquidStaking.address,{from: defaultAdmin,}), "Pausable: paused");
        });

        it('Only pauser admin can unpause contracts', async function () {
            await stokens.pause({from: pauseAdmin,});
            let checkPause = await stokens.paused();
            expect(checkPause === true)

            await stokens.unpause({from: pauseAdmin,});
            checkPause = await stokens.paused();
            expect(checkPause === false)
        });

        it('Non pauser admin cannot unpause contracts', async function () {
            await expectRevert(stokens.unpause({from: unknownAddress,}), "STokens: User not authorised to unpause contracts");
        });
    });
});