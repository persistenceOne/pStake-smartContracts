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
const sTokens = artifacts.require('STokens');
const uTokens = artifacts.require('UTokens');
const toAtomAddress = "toAtomAddress"
let to = "0x648c7358aF9d5208168a62571089aBb0DBc64B07";
//let from = accounts[0];
let from = "0x64D7AD9B8b450c1De16e7cD822283Dae5970e97A";
let anotherAccount = "0x3c452EC096F015569E7E75BE7D68C46AD271591C";
let owner = accounts[0]

describe("Token Wrapper", function () {
    this.timeout(0);
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

        utokens = await deployProxy(uTokens, [from, from], {initializer: 'initialize'});

        stokens = await deployProxy(sTokens, [utokens.address, from], {initializer: 'initialize'});

        tokenWrapper = await deployProxy(TokenWrapper, [utokens.address, stokens.address, from, from], {initializer: 'initialize'});

        liquidStaking = await deployProxy(LiquidStaking, [utokens.address, stokens.address, tokenWrapper.address, from, from], {initializer: 'initialize'});

        await utokens.setSTokenContract(stokens.address, {from: from})
        await utokens.setWrapperContract(tokenWrapper.address, {from: from})
        await utokens.setLiquidStakingContract(liquidStaking.address, {from: from})

        await stokens.setWrapperContract(tokenWrapper.address, {from: from})
        await stokens.setLiquidStakingContract(liquidStaking.address, {from: from})

        await tokenWrapper.setLiquidStakingContract(liquidStaking.address, {from: from})
    });

    describe("Set smart contract address", function () {

        it("Set liquidStaking contract address: ", async function () {
            await stokens.setLiquidStakingContract(liquidStaking.address,{from: from,});
            // TEST SCENARIO END
        }, 200000);

        it("Non owner can set liquidStaking contract address: ", async function () {
            await expectRevert(stokens.setLiquidStakingContract(liquidStaking.address,{from: to,}), "TokenWrapper: User not authorised to set LiquidStaking contract");
            // TEST SCENARIO END
        }, 200000);
    });

    describe("uTokens", function () {
        it('Only bridge admin can mint new uTokens for a user.', async function () {
            let generate = await tokenWrapper.generateUTokens(to, amount, {from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                to: to,
                tokens: amount,
            });
        });

        it('Number of tokens should be greater than 0', async function () {
            let val = new BN(0);
            await expectRevert(tokenWrapper.generateUTokens(to, val, {from: from,}), "TokenWrapper: Number of tokens should be greater than 0");
        });

        it('Non bridge admin cannot mint new tokens for a user', async function () {
            await expectRevert(tokenWrapper.generateUTokens(to, amount, {from: anotherAccount,}), "TokenWrapper: Only bridge admin can mint new tokens for a user");
        });
    });

    describe("Pausable", function () {
        it('Only pauser admin can pause contracts', async function () {
            await tokenWrapper.pause({from: from,});
            let checkPause = await tokenWrapper.paused();
            expect(checkPause === true)
        });

        it('Non pauser admin cannot pause contracts', async function () {
            await expectRevert(tokenWrapper.pause({from: to,}), "TokenWrapper: User not authorised to pause contracts");
        });

        it('Transactions could not be sent to paused contracts', async function () {
            await tokenWrapper.pause({from: from,});
            let checkPause = await tokenWrapper.paused();
            expect(checkPause === false)
            await expectRevert(tokenWrapper.generateUTokens(to, val, {from: from,}), "Pausable: paused");
        });

        it('Only pauser admin can unpause contracts', async function () {
            await tokenWrapper.pause({from: from,});
            let checkPause = await tokenWrapper.paused();
            expect(checkPause === true)

            await tokenWrapper.unpause({from: from,});
            checkPause = await tokenWrapper.paused();
            expect(checkPause === false)
        });

        it('Non pauser admin cannot unpause contracts', async function () {
            await expectRevert(tokenWrapper.unpause({from: to,}), "TokenWrapper: User not authorised to unpause contracts");
        });
    });
});