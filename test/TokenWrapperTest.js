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

let defaultAdmin = "0x9ac68f077dd05cC8847cb2fF414B43D0e761aD1c";
let bridgeAdmin = "0xA7aB6D6AED3e755900d62701156BA180869EAD38";
let pauseAdmin = "0xC14DeB556AB620D8F56707bd01f5af018538Af8D";
let to = "0xD7E6Bbbed5e2B280c26016FDc4D9d818C544965D";
let unknownAddress = "0x1640cC05Cec99ceDcb82d0Fb58802BAbbbBcCD30";

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

        utokens = await deployProxy(uTokens, [bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        stokens = await deployProxy(sTokens, [utokens.address, pauseAdmin], { initializer: 'initialize' });

        tokenWrapper = await deployProxy(TokenWrapper, [utokens.address, stokens.address, bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        liquidStaking = await deployProxy(LiquidStaking, [utokens.address, stokens.address, bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        await utokens.setSTokenContract(stokens.address,{from: defaultAdmin})
        await utokens.setWrapperContract(tokenWrapper.address,{from: defaultAdmin})
        await utokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})

        await stokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})
    });

    describe("Set smart contract address", function () {

        it("Set liquidStaking contract address: ", async function () {
            await tokenWrapper.setSTokensContract(stokens.address,{from: defaultAdmin,});
            // TEST SCENARIO END
        }, 200000);

        it("Non owner cannot set liquidStaking contract address: ", async function () {
            await expectRevert(tokenWrapper.setSTokensContract(stokens.address,{from: unknownAddress,}), "TokenWrapper: User not authorised to set SToken contract");
            // TEST SCENARIO END
        }, 200000);
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