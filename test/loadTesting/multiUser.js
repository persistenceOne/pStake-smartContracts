/*
//UNIT TEST

/!* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
which we will be using for our unit testing. *!/

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
/!*const sTokens = artifacts.require('STokens');
const uTokens = artifacts.require('UTokens');*!/

const sTokens = artifacts.require('StkXPRT');
const uTokens = artifacts.require('UstkXPRT');

let defaultAdmin = "0x2ffa2B68baE6ec48548918b9eACCA83FF6C1B374";
let bridgeAdmin = "0x287527B6316e901f78B132f5905A26545503d2ce";
let pauseAdmin = "0x16D7EA42A603CE412684dc439F8345E9Bc681d7c";
let to = "0x0b49137EFF46d70F3cc0c99a264e8348E29f93Ed";

describe("Multi-user staking and unstaking", function () {
    this.timeout(0);
    let liquidStaking;
    let tokenWrapper;
    let utokens;
    let stokens;
    let value = new BN(20000000);
    let amt = new BN(150);
    let amount = new BN(200);
    let val = new BN(50);
    let rate = 2;
    beforeEach(async function () {
        this.project = await TestHelper()

        utokens = await deployProxy(uTokens, [bridgeAdmin, pauseAdmin], {initializer: 'initialize'});

        stokens = await deployProxy(sTokens, [utokens.address, pauseAdmin], {initializer: 'initialize'});

        tokenWrapper = await deployProxy(TokenWrapper, [utokens.address, bridgeAdmin, pauseAdmin], {initializer: 'initialize'});

        liquidStaking = await deployProxy(LiquidStaking, [utokens.address, stokens.address, tokenWrapper.address, bridgeAdmin, pauseAdmin], {initializer: 'initialize'});

        await utokens.setSTokenContract(stokens.address, {from: defaultAdmin})
        await utokens.setWrapperContract(tokenWrapper.address, {from: defaultAdmin})
        await utokens.setLiquidStakingContract(liquidStaking.address, {from: defaultAdmin})

        await stokens.setWrapperContract(tokenWrapper.address, {from: defaultAdmin})
        await stokens.setLiquidStakingContract(liquidStaking.address, {from: defaultAdmin})

        await tokenWrapper.setLiquidStakingContract(liquidStaking.address, {from: defaultAdmin})
    });

    describe("Multiple users staking", function () {
        it('Stake - 15000 user', async function () {
            let generate = await tokenWrapper.generateUTokens(to,value,{from: bridgeAdmin,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: value,
            });
            let stakeToken;
            let gasUsed = 0;
            for (let i = 0; i < 15000; i++) {
                stakeToken = await liquidStaking.stake(to, val, {from: to,});
                gasUsed = gasUsed + (stakeToken.receipt.gasUsed);
                balance = await stokens.balanceOf(to);
                expect(balance >= amt)
                expectEvent(stakeToken, "StakeTokens", {
                    accountAddress: to,
                    tokens: val,
                });
            }
            console.log(gasUsed + " gasUsed ")
        },200000);
    })

    describe("Multiple users unstaking", function () {
        it('UnStake - 10000 user', async function () {
            let generate = await tokenWrapper.generateUTokens(to, value, {from: bridgeAdmin,});
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: value,
            });
            let stake = await liquidStaking.stake(to, value, {from: to,});
            let balance = await stokens.balanceOf(to);
            expect(balance >= value)
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: value,
            });
            let unstake;
            let gasUsed = 0;
            for (let i = 0; i < 10000; i++) {
                unstake = await liquidStaking.unStake(to, val, {from: to,});
                gasUsed = gasUsed + (unstake.receipt.gasUsed);
                balance = await stokens.balanceOf(to);
                expect(balance > amt)
                let totalBalance = amt + val
                expect(totalBalance > await utokens.balanceOf(to));
                expectEvent(unstake, "UnstakeTokens", {
                    accountAddress:to,
                    tokens: val,
                });
            }
            console.log(gasUsed + " gasUsed ")
        },200000);

        it('UnStake - 10001 user', async function () {
            let generate = await tokenWrapper.generateUTokens(to, value, {from: bridgeAdmin,});
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: value,
            });
            let stake = await liquidStaking.stake(to, value, {from: to,});
            let balance = await stokens.balanceOf(to);
            expect(balance >= value)
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: value,
            });
            let unstake;
            let gasUsed = 0;
            for (let i = 0; i < 10001; i++) {
                unstake = await liquidStaking.unStake(to, val, {from: to,});
                gasUsed = gasUsed + (unstake.receipt.gasUsed);
                balance = await stokens.balanceOf(to);
                expect(balance > amt)
                let totalBalance = amt + val
                expect(totalBalance > await utokens.balanceOf(to));
                expectEvent(unstake, "UnstakeTokens", {
                    accountAddress:to,
                    tokens: val,
                });
            }
            console.log(gasUsed + " gasUsed ")
        },200000);
    })
});*/
