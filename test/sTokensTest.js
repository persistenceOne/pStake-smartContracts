//UNIT TEST

/* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
which we will be using for our unit testing. */

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
const uTokens = contract.fromArtifact("UTokens");
const sTokens = contract.fromArtifact("STokens");
const LiquidStaking = contract.fromArtifact("LiquidStaking");
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
        utokens = await uTokens.new({ from: from});
        stokens = await sTokens.new(utokens.address, {from: from,});
        liquidStaking = await LiquidStaking.new(utokens.address, stokens.address, {
            from: from,
        });
    });
    describe("Set smart contract address", function () {
        it("Non-Owner cannot set uToken contract address: ", async function () {
            await expectRevert(stokens.setUTokensContract(utokens.address,{from: to,}), "Ownable: caller is not the owner");
            // TEST SCENARIO END
        }, 200000);

        it("Non-Owner cannot set liquidStaking contract address: ", async function () {
            await expectRevert(stokens.setLiquidStakingContractAddress(liquidStaking.address,{from: to,}), "Ownable: caller is not the owner");
            // TEST SCENARIO END
        }, 200000);

        it("Set uToken contract address: ", async function () {
            await stokens.setUTokensContract(utokens.address,{from: from,});
            // TEST SCENARIO END
        }, 200000);

        it("Set liquidStaking contract address: ", async function () {
            await stokens.setLiquidStakingContractAddress(liquidStaking.address,{from: from,});
            // TEST SCENARIO END
        }, 200000);
    });
});