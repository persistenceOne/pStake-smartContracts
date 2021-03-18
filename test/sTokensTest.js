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

const uTokens = Contracts.getFromLocal("UTokens");
const sTokens = Contracts.getFromLocal("STokens");
const LiquidStaking = Contracts.getFromLocal("LiquidStaking");
const { expect } = require('chai');
const { ZERO_ADDRESS } = constants;

describe('STokens', () => {
    let to = accounts[3];
    let from = accounts[1];
    let amount = new BN(200);
    let utokens;
    let stokens;
    let liquidStaking;
    beforeEach(async function () {
        this.project = await TestHelper()

        utokens = await this.project.createProxy(uTokens, {
            initMethod: 'initialize',
            initArgs: [],
            from: from,
        });

        stokens = await this.project.createProxy(sTokens, {
            initMethod: 'initialize',
            initArgs: [utokens.address],
            from: from,
        });

        liquidStaking = await this.project.createProxy(LiquidStaking, {
            initMethod: 'initialize',
            initArgs: [utokens.address, stokens.address],
            from: from,
        });
        console.log(utokens,"utokens")
        console.log(stokens,"stokens")
        console.log(liquidStaking,"liquidStaking")
    });
    describe("Set smart contract address", function () {
        it("Non-Owner cannot set uToken contract address: ", async function () {
            await expectRevert(stokens.methods.setUTokensContract(utokens.address).send({from: to,}), "Ownable: caller is not the owner");
            // TEST SCENARIO END
        }, 200000);

        it("Non-Owner cannot set liquidStaking contract address: ", async function () {
            await expectRevert(stokens.methods.setLiquidStakingContractAddress(liquidStaking.address).send({from: to}), "Ownable: caller is not the owner");
            // TEST SCENARIO END
        }, 200000);

        it("Set uToken contract address: ", async function () {
            await stokens.methods.setUTokensContract(utokens.address).send({from: from,});
            // TEST SCENARIO END
        }, 200000);

        it("Set liquidStaking contract address: ", async function () {
            await stokens.methods.setLiquidStakingContractAddress(liquidStaking.address).send({from: from,});
            // TEST SCENARIO END
        }, 200000);
    });
});