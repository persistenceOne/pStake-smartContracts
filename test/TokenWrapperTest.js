//UNIT TEST

/* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
which we will be using for our unit testing. */

const {web3} = require("@openzeppelin/test-helpers/src/setup");
const {
    deployProxy,
} = require("@openzeppelin/truffle-upgrades");

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
const { TestHelper } = require('zos');
const { Contracts, ZWeb3 } = require('zos-lib');

ZWeb3.initialize(web3.currentProvider);
const { expect } = require("chai");
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


describe("Token Wrapper", function () {
    this.timeout(0);
    let rewardRate = new BN(3000000);
    let liquidStaking;
    let tokenWrapper;
    let utokens;
    let stokens;
    let amt = new BN(150);
    let amount = new BN(200);
    let val = new BN(50);
    let rate = 2;
    beforeEach(async function () {
        this.project = await TestHelper()

        utokens = await deployProxy(uTokens, [bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        stokens = await deployProxy(sTokens, [utokens.address, pauseAdmin,rewardRate], { initializer: 'initialize' });

        tokenWrapper = await deployProxy(TokenWrapper, [utokens.address, bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        liquidStaking = await deployProxy(LiquidStaking, [utokens.address, stokens.address, tokenWrapper.address, bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        await utokens.setSTokenContract(stokens.address,{from: defaultAdmin})
        await utokens.setWrapperContract(tokenWrapper.address,{from: defaultAdmin})
        await utokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})

        await stokens.setWrapperContract(tokenWrapper.address,{from: defaultAdmin})
        await stokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})
    });

    describe("uTokens", function () {
        it('Only bridge admin can mint new uTokens for a user.', async function () {
            let generate = await tokenWrapper.generateUTokens(to, amount, {from: bridgeAdmin,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                accountAddress: to,
                tokens: amount,
            });
        });

        it('Number of tokens should be greater than 0', async function () {
            let val = new BN(0);
            await expectRevert(tokenWrapper.generateUTokens(to, val, {from: bridgeAdmin,}), "TokenWrapper: Number of tokens should be greater than 0");
        });

        it('Non bridge admin cannot mint new tokens for a user', async function () {
            await expectRevert(tokenWrapper.generateUTokens(to, amount, {from: unknownAddress,}), "TokenWrapper: Only bridge admin can mint new tokens for a user");
        });
    });

    describe("Pausable", function () {
        it('Only pauser admin can pause contracts', async function () {
            await tokenWrapper.pause({from: pauseAdmin,});
            let checkPause = await tokenWrapper.paused();
            expect(checkPause === true)
        });

        it('Non pauser admin cannot pause contracts', async function () {
            await expectRevert(tokenWrapper.pause({from: unknownAddress,}), "TokenWrapper: User not authorised to pause contracts");
        });

        it('Transactions could not be sent to paused contracts', async function () {
            await tokenWrapper.pause({from: pauseAdmin,});
            let checkPause = await tokenWrapper.paused();
            expect(checkPause === false)
            await expectRevert(tokenWrapper.generateUTokens(to, val, {from: bridgeAdmin,}), "Pausable: paused");
        });

        it('Only pauser admin can unpause contracts', async function () {
            await tokenWrapper.pause({from: pauseAdmin,});
            let checkPause = await tokenWrapper.paused();
            expect(checkPause === true)

            await tokenWrapper.unpause({from: pauseAdmin,});
            checkPause = await tokenWrapper.paused();
            expect(checkPause === false)
        });

        it('Non pauser admin cannot unpause contracts', async function () {
            await expectRevert(tokenWrapper.unpause({from: unknownAddress,}), "TokenWrapper: User not authorised to unpause contracts");
        });
    });
});