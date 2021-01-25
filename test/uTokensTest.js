//UNIT TEST

/* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
which we will be using for our unit testing. */

const {
    accounts,
    contract,
} = require("@openzeppelin/test-environment");
const {
    BN,
    expectRevert,
} = require("@openzeppelin/test-helpers");

const LiquidStaking = contract.fromArtifact("LiquidStaking");
const sTokens = contract.fromArtifact("STokens");
const uTokens = contract.fromArtifact("UTokens");
let from = accounts[1];
let to = accounts[2];

describe('UTokens', () => {
    let amount = new BN(200);
    let utokens;
    let stokens;
    let liquidStaking;
    beforeEach(async function () {
        utokens = await uTokens.new({from: from});
        stokens = await sTokens.new(utokens.address, {from: from,});
        liquidStaking = await LiquidStaking.new(utokens.address, stokens.address, {
            from: from,
        });
    });
    describe("Set smart contract address", function () {
        it("Non-Owner cannot set sToken contract address: ", async function () {
            await expectRevert(utokens.setSTokenContractAddress(liquidStaking.address,{from: to,}), "Ownable: caller is not the owner");
            // TEST SCENARIO END
        }, 200000);

        it("Non-Owner cannot set liquidStaking contract address: ", async function () {
            await expectRevert(utokens.setLiquidStakingContractAddress(liquidStaking.address,{from: to,}), "Ownable: caller is not the owner");
            // TEST SCENARIO END
        }, 200000);

        it("Set sToken contract address: ", async function () {
            await utokens.setSTokenContractAddress(stokens.address,{from: from,});
            // TEST SCENARIO END
        }, 200000);

        it("Set liquidStaking contract address: ", async function () {
            await utokens.setLiquidStakingContractAddress(liquidStaking.address,{from: from,});
            // TEST SCENARIO END
        }, 200000);
    });
});
