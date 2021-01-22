//UNIT TEST

/* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
which we will be using for our unit testing. */

const {
    accounts,
    contract,
} = require("@openzeppelin/test-environment");
const {
    expectRevert,
} = require("@openzeppelin/test-helpers");
const LiquidStaking = contract.fromArtifact("liquidStaking");
const sTokens = contract.fromArtifact("sTokens");
const uTokens = contract.fromArtifact("uTokens");
let from = accounts[1];
let to = accounts[2];

describe('uTokens', () => {
    describe("Set smart contract address", function () {
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
