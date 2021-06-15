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
const Bech32 = artifacts.require("Bech32Validation");
const sTokens = artifacts.require('STokens');
const uTokens = artifacts.require('UTokens');

let toChainAddress = "cosmospub1addwnpepq272xswjqka4wm6x8nvuwshdquh0q8xrxlafz7lj32snvtg2jswl6x5ywwu";

let defaultAdmin = "0xd3ad2807FD92F641f68eBaA873510D57D29d7E8c";
let bridgeAdmin = "0xe7783704F01B64EEfA54F67AB13aD33167eff0E0";
let pauseAdmin = "0x518a0Ac0B7b58a0c3952B0BCed567e4459B65787";
let to = "0xB16584E4516859A8B49aCecD7E8d41f295182b1B";
let unknownAddress = "0x92dE6bAbF15168d7D42F74812a1a36eA02e5B093";


describe("Token Wrapper", function () {
    this.timeout(0);
    let _rewardRate = new BN(3000000);
    let rewardDivisor = new BN(1000000000)
    let liquidStaking;
    let tokenWrapper;
    let bech32;
    let utokens;
    let stokens;
    let amt = new BN(150);
    let amount = new BN(200);
    let val = new BN(50);
    let rate = new BN(2000000);
    beforeEach(async function () {
        this.project = await TestHelper()

        utokens = await deployProxy(uTokens, [bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        stokens = await deployProxy(sTokens, [utokens.address, pauseAdmin, _rewardRate, rewardDivisor], { initializer: 'initialize' });

        tokenWrapper = await deployProxy(TokenWrapper, [utokens.address, bridgeAdmin, pauseAdmin, rewardDivisor], { initializer: 'initialize' });

        liquidStaking = await deployProxy(LiquidStaking, [utokens.address, stokens.address, pauseAdmin, rewardDivisor], { initializer: 'initialize' });

        await utokens.setSTokenContract(stokens.address,{from: defaultAdmin})
        await utokens.setWrapperContract(tokenWrapper.address,{from: defaultAdmin})
        await utokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})

        await stokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})
        await stokens.setRewardRate(rate,{from: defaultAdmin,});
    });

    describe("Bech32 Validation", function () {
        it('Validating bech32 Address.', async function () {
            let generate = await tokenWrapper.generateUTokens(to, amount, {from: bridgeAdmin,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                accountAddress: to,
                tokens: amount,
            });

            let withdraw = await tokenWrapper.withdrawUTokens(to, val, toChainAddress, {from: to,});
            const gasUsed = generate.receipt.gasUsed;
            console.log("gasUsed: ", gasUsed)
            console.log("withdraw: ", withdraw)
            expectEvent(withdraw, "WithdrawUTokens", {
                accountAddress: to,
                tokens: val,
                toChainAddress: toChainAddress,
            });

        });
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
            await expectRevert(tokenWrapper.generateUTokens(to, val, {from: bridgeAdmin,}), "TokenWrapper: Requires a min deposit amount");
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