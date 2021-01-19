// //UNIT TEST
//
// /* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
// which we will be using for our unit testing. */

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
const sTokens = contract.fromArtifact("sTokens");
const { expect } = require('chai');
const { ZERO_ADDRESS } = constants;

describe('sTokens', () => {
    let to = accounts[3];
    let from = accounts[0];

    it('rejects a null account', async function () {
        const amount = new BN(100);
        // DEPLOY CONTRACT
        let stokens = await sTokens.new({ from: from});
        await expectRevert(
            stokens.mint(ZERO_ADDRESS, amount), 'ERC20: mint to the zero address',
        );
    });

    it("TEST: mintSTokens() successful execution scenario: ", async function () {
        const amount = new BN(100);
        // DEPLOY CONTRACT
        let stokens = await sTokens.new({ from: from});

        // DEPLOY END

        // TEST SCENARIO
        let mintSTokensTxnReceipt = await stokens.mint(to,amount,
            {
                from: from,
            }
        );
        // test if the event 'Transfer(sender, recipient, amount)' is emitted:
        await expectEvent(mintSTokensTxnReceipt, "Transfer", {
            to: to,
            value: amount,
        });
        // TEST SCENARIO END
    }, 200000);

    it('increments recipient balance', async function () {
        const amount = new BN(100);
        // DEPLOY CONTRACT
        let stokens = await sTokens.new({ from: from});

        // DEPLOY END

        // TEST SCENARIO
        let mintSTokensTxnReceipt = await stokens.mint(to,amount,
            {
                from: from,
            }
        );
        expect(await stokens.balanceOf(to)).to.be.bignumber.equal(amount);
    });

    it('TEST: burnUTokens() negative execution scenario: Balance exceeds', async function () {
        let amt = new BN(50);
        const amount = new BN(100);
        // DEPLOY CONTRACT
        let stokens = await sTokens.new({
            from: from,
        });
        let mintSTokensTxnReceipt = await stokens.mint(to,amt,
            {
                from: from,
            }
        );
        expectEvent(mintSTokensTxnReceipt, "Transfer", {
            value: amt,
        });
        await expectRevert(
            stokens.burn(to,amt), 'revert',
        );
    },200000);

    it("TEST: burnUTokens() successful execution scenario: ", async function () {
        let amount = new BN("100");
        let amt = new BN("50");
        // DEPLOY CONTRACT
        let stokens = await sTokens.new({
            from: from,
        });
        // DEPLOY END
        let mintSTokensTxnReceipt = await stokens.mint(to,amount,
            {
                from: from,
            }
        );
        expectEvent(mintSTokensTxnReceipt, "Transfer", {
            value: amount,
        });

        // TEST SCENARIO
        let burnSTokensTxnReceipt = await stokens.burn(to,amt,
            {
                from: from,
            }
        );

        // test if the event 'Burn(sender, recipient, amount)' is emitted:
        expectEvent(burnSTokensTxnReceipt, "Transfer", {
            value: amt,
        });
        // TEST SCENARIO END
    }, 200000);

    it('TEST: calculateRewards', async function () {
        let amt = new BN(50);
        let amount = new BN(100);
        // DEPLOY CONTRACT
        let stokens = await sTokens.new({
            from: from,
        });
        let mintSTokensTxnReceipt = await stokens.mint(to,amt,
            {
                from: from,
            }
        );
        expectEvent(mintSTokensTxnReceipt, "Transfer", {
            value: amt,
        });

        mintSTokensTxnReceipt = await stokens.mint(to,amount,
            {
                from: from,
            }
        );
        expectEvent(mintSTokensTxnReceipt, "Transfer", {
            value: amt,
        });
    },200000);
});