// //UNIT TEST
//
// /* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
// which we will be using for our unit testing. */

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

describe('uTokens', () => {
    let to = accounts[3];
    let from = accounts[0];
    it("TEST: mintUTokens() successful execution scenario: ", async function () {
        const amount = new BN(100);
        // DEPLOY CONTRACT
        let utokens = await uTokens.new({ from: from});

        // DEPLOY END

        // TEST SCENARIO
        let mintUTokensTxnReceipt = await utokens.mint(from,amount,
            {
                from: from,
            }
        );
        // test if the event 'Transfer(sender, recipient, amount)' is emitted:
        await expectEvent(mintUTokensTxnReceipt, "Transfer", {
            to: from,
            value: amount,
        });
        // TEST SCENARIO END
    }, 200000);

    it('TEST: burnUTokens() negative execution scenario: Balance exceeds', async function () {
        let amt = new BN("50");
        // DEPLOY CONTRACT
        let utokens = await uTokens.new({
            from: from,
        });
        await expectRevert(
            utokens.burn(from,amt), 'ERC20: burn amount exceeds balance',
        );
    },200000);

    it("TEST: burnUTokens() successful execution scenario: ", async function () {
        let amount = new BN("100");
        let amt = new BN("50");
        // DEPLOY CONTRACT
        let utokens = await uTokens.new({
            from: from,
        });
        // DEPLOY END
        let mintUTokensTxnReceipt = await utokens.mint(from,amount,
            {
                from: from,
            }
        );
        expectEvent(mintUTokensTxnReceipt, "Transfer", {
            value: amount,
        });

        // TEST SCENARIO
        let burnUTokensTxnReceipt = await utokens.burn(from,amt,
            {
                from: from,
            }
        );

        // test if the event 'Burn(sender, recipient, amount)' is emitted:
        expectEvent(burnUTokensTxnReceipt, "Transfer", {
            value: amt,
        });
        // TEST SCENARIO END
    }, 200000);
});
