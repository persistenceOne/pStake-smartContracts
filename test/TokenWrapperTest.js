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

let toChainAddress = "cosmos1dgtl8dqky0cucr9rlllw9cer9ysrkjnjagz5zp";

let defaultAdmin = "0x5B6F3d90E21d86dc60d4c54B048C68C8cDD3C9f4";
let bridgeAdmin = "0x6Cac2100411d57c0Da91520B58fef6F72cE226Da";
let pauseAdmin = "0x2c472d2045033bd7911A1A2feC0dCd29350d22B8";
let to = "0xCe407Af69C9999245e78FB0e0C3c0C3668Bd47C2";
let unknownAddress = "0x3Ba4E408F357a0649A15aB97427Ee35B455F070E";


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

        bech32 = await deployProxy(Bech32, { initializer: 'initialize' });

        tokenWrapper = await deployProxy(TokenWrapper, [utokens.address, bech32.address, bridgeAdmin, pauseAdmin, rewardDivisor], { initializer: 'initialize' });

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