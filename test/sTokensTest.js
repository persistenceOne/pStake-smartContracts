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
const sTokens = contract.fromArtifact("sTokens");
const { expect } = require('chai');
const { ZERO_ADDRESS } = constants;

describe('sTokens', () => {
    describe("Minting", function () {
        let to = accounts[3];
        let from = accounts[1];
        let stokens;
        let amount = new BN(100);
        beforeEach(async function () {
            stokens = await sTokens.new({from: from});
        });

        it('Constructor rejects a null account', async function () {
            const amount = new BN(100);
            await expectRevert(
                stokens.mint(ZERO_ADDRESS, amount), 'ERC20: mint to the zero address',
            );
        });

        it("Mint sTokens: ", async function () {
            let mintSTokens = await stokens.mint(to,amount,{from: from,});
            // test if the event 'Transfer(sender, recipient, amount)' is emitted:
            await expectEvent(mintSTokens, "Transfer", {
                to: to,
                value: amount,
            });
            // TEST SCENARIO END
        }, 200000);

        it('Increments recipient balance', async function () {
            let mintSTokens = await stokens.mint(to,amount, {from: from,});
            await expectEvent(mintSTokens, "Transfer", {
                to: to,
                value: amount,
            });
            expect(await stokens.balanceOf(to)).to.be.bignumber.equal(amount);
        });
    });

    describe("Burning", function () {
        let to = accounts[3];
        let from = accounts[1];
        let stokens;
        let amt = new BN(50);
        let amount = new BN(100);
        beforeEach(async function () {
            stokens = await sTokens.new({from: from});
        });

        it('Burn amount exceeds balance', async function () {
           let mintSTokens = await stokens.mint(to,amt,{from: from,});
            expectEvent(mintSTokens, "Transfer", {
                to: to,
                value: amt,
            });
            await expectRevert(
                stokens.burn(to,amount), 'revert',
            );
        },200000);

        it("Burn", async function () {
            let mintSTokens = await stokens.mint(to,amount,{from: from,});
            expectEvent(mintSTokens, "Transfer", {
                to: to,
                value: amount,
            });
            let burnSTokens = await stokens.burn(to,amt,{from: from,});
            // test if the event 'Transfer(sender, recipient, amount)' is emitted:
            expectEvent(burnSTokens, "Transfer", {
                value: amt,
            });
            // TEST SCENARIO END
        }, 200000);
    });

    describe("Calculate Reward", function () {
        let to = accounts[3];
        let from = accounts[1];
        let stokens;
        let amt = new BN(50);
        let amount = new BN(100);
        beforeEach(async function () {
            stokens = await sTokens.new({from: from});
        });

        it('TEST: calculateRewards', async function () {
            let mintSTokens = await stokens.mint(to,amt,{from: from,});
            expectEvent(mintSTokens, "Transfer", {
                to:to,
                value: amt,
            });
            mintSTokens = await stokens.mint(to,amount,{from: from,});
            expectEvent(mintSTokens, "Transfer", {
                to:to,
                value: amt,
            });
        },200000);
    });
});