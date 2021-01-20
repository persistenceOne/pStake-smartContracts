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
const uTokens = contract.fromArtifact("uTokens");
const { ZERO_ADDRESS } = constants;

describe('uTokens', () => {
    describe("Minting", function () {
        let from = accounts[1];
        let utokens;
        let amount = new BN(100);
        beforeEach(async function () {
            utokens = await uTokens.new({from: from});
        });

        it("Mint uTokens: ", async function () {
            let mintUTokens = await utokens.mint(from,amount,{from: from, });
            // test if the event 'Transfer(sender, recipient, amount)' is emitted:
            await expectEvent(mintUTokens, "Transfer", {
                to: from,
                value: amount,
            });
            // TEST SCENARIO END
        }, 200000);
    });

    describe("Burning", function () {
        let from = accounts[1];
        let utokens;
        let amount = new BN("100");
        let amt = new BN("50");
        beforeEach(async function () {
            utokens = await uTokens.new({from: from});
        });
        it('Burn amount exceeds balance', async function () {
            await expectRevert(
                utokens.burn(from,amt), 'ERC20: burn amount exceeds balance',
            );
        },200000);

        it("Burn uTokens: ", async function () {
            let mintUTokens = await utokens.mint(from,amount,{from: from,});
            expectEvent(mintUTokens, "Transfer", {
                value: amount,
            });
            let burnUTokens = await utokens.burn(from,amt,{from: from,});
            // test if the event 'Transfer(sender, recipient, amount)' is emitted:
            expectEvent(burnUTokens, "Transfer", {
                value: amt,
            });
        }, 200000);
    });
});
