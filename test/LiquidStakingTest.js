//UNIT TEST

/* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
which we will be using for our unit testing. */

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
const { expect } = require("chai");
const LiquidStaking = contract.fromArtifact("LiquidStaking");
const sTokens = contract.fromArtifact("STokens");
const uTokens = contract.fromArtifact("UTokens");
const toAtomAddress = "0x7465737400000000000000000000000000000000000000000000000000000000"
let to = accounts[3];
let from = accounts[1];
let anotherAccount = accounts[4];

describe("Liquid Staking", function () {
    let liquidStaking;
    let utokens;
    let stokens;
    let amt = new BN(150);
    let amount = new BN(200);
    let val = new BN(50);
    let rate = 2;
    beforeEach(async function () {
        utokens = await uTokens.new({ from: from});
        stokens = await sTokens.new(utokens.address, {from: from,});
        liquidStaking = await LiquidStaking.new(utokens.address, stokens.address, {
            from: from,
        });
        await utokens.setSTokenContractAddress(stokens.address,{from: from,});
        await utokens.setLiquidStakingContractAddress(liquidStaking.address,{from: from,});
        await stokens.setUTokensContract(utokens.address,{from: from,});
        await stokens.setLiquidStakingContractAddress(liquidStaking.address,{from: from,});
    });
    describe("uTokens", function () {
        it('Only owner can mint new uTokens for a user.', async function () {
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
        });

        it('Number of tokens should be greater than 0', async function () {
            let val = new BN(0);
            await expectRevert(liquidStaking.generateUTokens(to,val,{from: from,}),"LiquidStaking: Number of tokens should be greater than 0");
        });

        it('Malicious/illegitimate actor cannot mint uTokens for a user', async function () {
            await expectRevert(liquidStaking.generateUTokens(to,amount,{from: anotherAccount,}),"LiquidStaking: Only owner can mint new tokens for a user");
        });
    });

    describe("sTokens", function () {
        it('Only Staker can mint new sTokens', async function () {
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
        });

        it('Malicious/illegitimate actor cannot mint sTokens', async function () {
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            await expectRevert(liquidStaking.stake(to, amount, {from: anotherAccount,}), "LiquidStaking: Staking can only be done by Staker");
        });
    });

    describe("Staking", function () {
        it('Generate uTokens', async function () {
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
        });

        it('Number of staked tokens should be greater than 0', async function () {
            let val = new BN(0);
            expectRevert(liquidStaking.stake(to,val,{from: from,}),"LiquidStaking: Number of staked tokens should be greater than 0");
        });

        it('Insuffcient balance for account', async function () {
            await liquidStaking.generateUTokens(to,amt,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amt)
            await expectRevert(liquidStaking.stake(to, amount, {from: to,}), "LiquidStaking: Insuffcient balance for account");
        });

        it('Stake', async function () {
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
        });
    })

    describe("Set Reward Rate", function () {
        it('Non-Owner cannot call setRewardRate()', async function () {
            await expectRevert(stokens.setRewardRate(rate,{from: to,}), "revert");
        },200000);

        it('Only owner can call setRewardRate()', async function () {
            await stokens.setRewardRate(rate,{from: from,});
        },200000);
    })

    describe("Calculate Reward", function () {
        it('CalculateRewards with double minting', async function () {
            let stake;
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            await liquidStaking.stake(to,val,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>val)
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
        },200000);

        it('Call CalculateRewards()', async function () {
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            let reward = await stokens.calculateRewards(to,{from: to,});
            expect(reward >= stokens.balanceOf(to));
        },200000);

        it('Verify CalculateRewards() in Staking', async function () {
           await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)

            stake = await liquidStaking.stake(to,val,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>val)
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
        },200000);

        it('Verify CalculateRewards() in Unstaking', async function () {
           await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            await liquidStaking.unStake(to,val,{from: to,});
            expect(balance>amt)
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
        },200000);
    });

    describe("Transfer", function () {
       it('Transfer amount exceeds balance', async function () {
            await expectRevert(stokens.transfer(anotherAccount,amount,{from: to,}), "revert");
        },200000);

        it('Transfer', async function () {
            let stake;
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            let transferTokens = await stokens.transfer(anotherAccount,val,{from: to,});
            expectEvent(transferTokens, "Transfer", {
                to:anotherAccount,
                value: val,
            });
        },200000);
    });

    describe("UnStaking", function () {
        it('Number of unstaked tokens should be greater than 0', async function () {
            let val = new BN(0);
            await expectRevert(liquidStaking.unStake(to, val, {from: to,}), "LiquidStaking: Number of unstaked tokens should be greater than 0");
        });

        it('Non-staker cannot withdraw', async function () {
            expectRevert(liquidStaking.unStake(to, amount, {from: anotherAccount,}), "Unstaking can only be done by Staker");
        });

        it('Current sToken balance should be greater than unstaked amount', async function () {
            await liquidStaking.generateUTokens(to, amount, {from: from,});
            await liquidStaking.stake(to, amt, {from: to,});
            let balance = await stokens.balanceOf(to);
            expect(balance >= amt)
            await expectRevert(liquidStaking.unStake(to, amount, {from: to,}), "LiquidStaking: Insuffcient balance for account");
        });

        it('UnStake', async function () {
            await liquidStaking.generateUTokens(to, amount, {from: from,});
            await liquidStaking.stake(to, amt, {from: to,});
            let balance = await stokens.balanceOf(to);
            expect(balance >= amt)
            await liquidStaking.unStake(to, val, {from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance > amt)
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
        });
    });

    describe("Withdraw", function () {
        describe("Withdraw unStaked tokens", function () {
            it('Only staker can withdraw', async function () {
                await liquidStaking.generateUTokens(to, amount, {from: from,});
                await liquidStaking.stake(to, amt, {from: to,});
                let balance = await stokens.balanceOf(to);
                expect(balance >= amt)
                await liquidStaking.unStake(to, val, {from: to,});
                balance = await stokens.balanceOf(to);
                expect(balance > amt)
                let totalBalance = amt + val
                expect(totalBalance > await utokens.balanceOf(to));
                await expectRevert(liquidStaking.withdrawUnstakedTokens(to, {from: anotherAccount,}), "LiquidStaking: Only staker can withdraw");
            });

            it('Cannot withdraw UnStake token before locking period', async function () {
                await liquidStaking.generateUTokens(to, amount, {from: from,});
                await liquidStaking.stake(to, amt, {from: to,});
                let balance = await stokens.balanceOf(to);
                expect(balance >= amt)
                await liquidStaking.unStake(to, val, {from: to,});
                balance = await stokens.balanceOf(to);
                expect(balance > amt)
                let totalBalance = amt + val
                expect(totalBalance > await utokens.balanceOf(to));
                await expectRevert(liquidStaking.withdrawUnstakedTokens(to, {from: to,}), "LiquidStaking: UnStaking period still pending");
            });

            it('Multi-lock for same user', async function () {
                await liquidStaking.generateUTokens(to, amount, {from: from,});
                await liquidStaking.stake(to, amt, {from: to,});
                let balance = await stokens.balanceOf(to);
                expect(balance >= amt)
                await liquidStaking.unStake(to, val, {from: to,});
                await liquidStaking.unStake(to, val, {from: to,});
                balance = await stokens.balanceOf(to);
                expect(balance > amt)
                let _val = val+val
                let totalBalance = amt + _val
                expect(totalBalance > await utokens.balanceOf(to));
                await expectRevert(liquidStaking.withdrawUnstakedTokens(to, {from: to,}), "LiquidStaking: UnStaking period still pending");
            });
        });

        describe("Withdraw uTokens", function () {

            it('Number of utokens should be greater than 0', async function () {
                let _val = new BN(0);
                await liquidStaking.generateUTokens(to,amount,{from: from,});
                let balance = await utokens.balanceOf(to);
                expect(balance == amount)
                expectRevert(liquidStaking.withdrawUTokens(to,_val,toAtomAddress,{from: to,}),"LiquidStaking: Number of unstaked tokens should be greater than 0");
            });

            it('Current uToken balance should be greater than staked amount', async function () {
                await liquidStaking.generateUTokens(to,amt,{from: from,});
                let balance = await utokens.balanceOf(to);
                expect(balance == amt)
                await expectRevert(liquidStaking.withdrawUTokens(to, amount, toAtomAddress, {from: to,}), "LiquidStaking: Insuffcient balance for account");
            });

            it('Only staker can withdraw', async function () {
                await liquidStaking.generateUTokens(to, amount, {from: from,});
                let balance = await utokens.balanceOf(to);
                expect(balance == amt)
                await expectRevert(liquidStaking.withdrawUTokens(to, amt, toAtomAddress, {from: anotherAccount,}), "LiquidStaking: Withdraw can only be done by Staker");
            });

            it('Withdraw uTokens', async function () {
                await liquidStaking.generateUTokens(to, amount, {from: from,});
                let balance = await utokens.balanceOf(to);
                expect(balance == amt)
                await liquidStaking.withdrawUTokens(to, amt, toAtomAddress, {from: to,});
                let _val = balance - amt;
                balance = await utokens.balanceOf(to);
                expect(balance == _val)
            });
        });
    });
}); // DESCRIBE END