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
const sTokens = artifacts.require('STokens');
const uTokens = artifacts.require('UTokens');
const toAtomAddress = "toAtomAddress"
let to = "0x648c7358aF9d5208168a62571089aBb0DBc64B07";
//let from = accounts[0];
let from = "0x64D7AD9B8b450c1De16e7cD822283Dae5970e97A";
let anotherAccount = "0x3c452EC096F015569E7E75BE7D68C46AD271591C";
let owner = accounts[0]

describe('STokens', () => {
    let amount = new BN(200);
    let utokens;
    let stokens;
    let liquidStaking;
    let tokenWrapper;
    beforeEach(async function () {
        this.project = await TestHelper()

        utokens = await deployProxy(uTokens, [from, from], { initializer: 'initialize' });

        stokens = await deployProxy(sTokens, [utokens.address, from], { initializer: 'initialize' });

        tokenWrapper = await deployProxy(TokenWrapper, [utokens.address, stokens.address, from, from], { initializer: 'initialize' });

        liquidStaking = await deployProxy(LiquidStaking, [utokens.address, stokens.address, tokenWrapper.address, from, from], { initializer: 'initialize' });

        await utokens.setSTokenContract(stokens.address,{from: from})
        await utokens.setWrapperContract(tokenWrapper.address,{from: from})
        await utokens.setLiquidStakingContract(liquidStaking.address,{from: from})

        await stokens.setWrapperContract(tokenWrapper.address,{from: from})
        await stokens.setLiquidStakingContract(liquidStaking.address,{from: from})

        await tokenWrapper.setLiquidStakingContract(liquidStaking.address,{from: from})
    });
    describe("Set smart contract address", function () {

        it("Set uToken contract address: ", async function () {
            await stokens.setUTokensContract(utokens.address,{from: from,});
            // TEST SCENARIO END
        }, 200000);

        it("Set wrapper contract address: ", async function () {
            await stokens.setWrapperContract(tokenWrapper.address,{from: from,});
            // TEST SCENARIO END
        }, 200000);

        it("Set liquidStaking contract address: ", async function () {
            await stokens.setLiquidStakingContract(liquidStaking.address,{from: from,});
            // TEST SCENARIO END
        }, 200000);

        it("Non owner can set sToken contract address: ", async function () {
            await expectRevert(stokens.setUTokenContract(utokens.address,{from: to,}), "STokens: User not authorised to set UToken contract");
            // TEST SCENARIO END
        }, 200000);

        it("Non owner can set wrapper contract address: ", async function () {
            await expectRevert(stokens.setWrapperContract(tokenWrapper.address,{from: to,}), "STokens: User not authorised to set wrapper contract");
            // TEST SCENARIO END
        }, 200000);

        it("Non owner can set liquidStaking contract address: ", async function () {
            await expectRevert(stokens.setLiquidStakingContract(liquidStaking.address,{from: to,}), "STokens: User not authorised to set liquidStaking contract");
            // TEST SCENARIO END
        }, 200000);
    });

    describe("Pausable", function () {
        it('Only pauser admin can pause contracts', async function () {
            await stokens.pause({from: from,});
            let checkPause = await stokens.paused();
            expect(checkPause === true)
        });

        it('Non pauser admin cannot pause contracts', async function () {
            await expectRevert(stokens.pause({from: to,}), "STokens: User not authorised to pause contracts");
        });

        it('Transactions could not be sent to paused contracts', async function () {
            await stokens.pause({from: from,});
            let checkPause = await stokens.paused();
            expect(checkPause === false)
            await expectRevert(stokens.setLiquidStakingContract(liquidStaking.address,{from: from,}), "Pausable: paused");
        });

        it('Only pauser admin can unpause contracts', async function () {
            await stokens.pause({from: from,});
            let checkPause = await stokens.paused();
            expect(checkPause === true)

            await stokens.unpause({from: from,});
            checkPause = await stokens.paused();
            expect(checkPause === false)
        });

        it('Non pauser admin cannot unpause contracts', async function () {
            await expectRevert(stokens.unpause({from: to,}), "STokens: User not authorised to unpause contracts");
        });
    });
});