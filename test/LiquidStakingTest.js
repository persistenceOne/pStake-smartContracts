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
const LiquidStaking = contract.fromArtifact("liquidStaking");
const sTokens = contract.fromArtifact("sTokens");
const uTokens = contract.fromArtifact("uTokens");
let to = accounts[3];
let from = accounts[1];

describe("Liquid Staking", function () {
    describe("Staking", function () {
        let liquidStaking;
        let utokens;
        let stokens;
        let amt = new BN(50);
        let amount = new BN(100);
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
        it('generate uTokens', async function () {
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
        });

        it('Number of staked tokens should be greater than 0', async function () {
            let val = new BN(0);
            expectRevert(liquidStaking.stake(to,val,{from: from,}),"revert");
        });

        it('Staking can only be done by Staker', async function () {
            expectRevert(liquidStaking.stake(to,amount,{from: from,}),"Staking can only be done by Staker");
        });

        it('Current uToken balance should be greater than staked amount', async function () {
            await liquidStaking.generateUTokens(to,amt,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amt)
            await expectRevert(liquidStaking.stake(to, amount, {from: from,}), "revert");
        });

        it('Stake', async function () {
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            expectEvent(stake, "Staking", {
                _from:to,
                _value: amt,
            });
        });
    })

    describe("Set Reward Rate", function () {
        let utokens;
        let stokens;
        let liquidStaking;
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

        it('Non-Owner cannot call setRewardRate()', async function () {
            await expectRevert(stokens.setRewardRate(rate,{from: to,}), "revert");
        },200000);

        it('Only owner can call setRewardRate()', async function () {
            await stokens.setRewardRate(rate,{from: from,});
        },200000);
    })

    describe("Calculate Reward", function () {
        let utokens;
        let stokens;
        let liquidStaking;
        let amt = new BN(100);
        let amount = new BN(200);
        let val = new BN(50);
        let rate = 5;
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
            await stokens.setRewardRate(rate,{from: from,});
        });

        it('CalculateRewards with double minting', async function () {
            let stake;
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            stake = await liquidStaking.stake(to,amt,{from: to,});
            expectEvent(stake, "Staking", {
                _from:to,
                _value: amt,
            });
            stake = await liquidStaking.stake(to,val,{from: to,});
            expectEvent(stake, "Staking", {
                _from:to,
                _value: val,
            });
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
        },200000);

        it('Call CalculateRewards()', async function () {
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            expectEvent(stake, "Staking", {
                _from:to,
                _value: amt,
            });
            let reward = await stokens.calculateRewards(to);
            expect(reward >= stokens.balanceOf(to));
        },200000);

        it('Verify CalculateRewards() in Staking', async function () {
            let stake;
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            stake = await liquidStaking.stake(to,amt,{from: to,});
            expectEvent(stake, "Staking", {
                _from:to,
                _value: amt,
            });

            stake = await liquidStaking.stake(to,val,{from: to,});
            expectEvent(stake, "Staking", {
                _from:to,
                _value: val,
            });
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
        },200000);

        it('Verify CalculateRewards() in Unstaking', async function () {
            let stake;
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            stake = await liquidStaking.stake(to,amt,{from: to,});
            expectEvent(stake, "Staking", {
                _from:to,
                _value: amt,
            });

            let unStake = await liquidStaking.unStake(to,val,{from: to,});
            expectEvent(unStake, "Unstaking", {
                _from:to,
                _value: val,
            });
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
        },200000);
    });

    describe("Transfer", function () {
        let to = accounts[3];
        let anotherAccount = accounts[4];
        let from = accounts[1];
        let utokens;
        let stokens;
        let liquidStaking;
        let amt = new BN(50);
        let amount = new BN(100);
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

            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            await liquidStaking.stake(to,amt,{from: to,});
        });

        it('Transfer amount exceeds balance', async function () {
            await expectRevert(stokens.transfer(anotherAccount,amount,{from: to,}), "revert");
        },200000);

        it('Transfer', async function () {
            let transferTokens = await stokens.transfer(anotherAccount,amt,{from: to,});
            expectEvent(transferTokens, "Transfer", {
                to:anotherAccount,
                value: amt,
            });
        },200000);
    });

    describe("UnStaking", function () {
        let amount = new BN(150);
        let amt = new BN(100);
        let val = new BN(50)
        let utokens;
        let stokens;
        let liquidStaking;
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

        it('Number of unstaked tokens should be greater than 0', async function () {
            let val = new BN(0);
            await expectRevert(liquidStaking.unStake(to, val, {from: from,}), "revert");
        });

        it('Unstaking can only be done by Staker', async function () {
            expectRevert(liquidStaking.unStake(to,amount,{from: from,}),"Unstaking can only be done by Staker");
        });

        it('Current sToken balance should be greater than unstaked amount', async function () {
            await liquidStaking.generateUTokens(to,amount,{from: from,});
           let stake = await liquidStaking.stake(to,amt,{from: to,});
            expectEvent(stake, "Staking", {
                _from:to,
                _value: amt,
            });
            await expectRevert(liquidStaking.unStake(to, amt, {from: from,}), "revert");
        });

        it('UnStake', async function () {
           await liquidStaking.generateUTokens(to,amount,{from: from,});
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            expectEvent(stake, "Staking", {
                _from:to,
                _value: amt,
            });
            let unStake = await liquidStaking.unStake(to,val,{from: to,});

            expectEvent(unStake, "Unstaking", {
                _from:to,
                _value: val,
            });
        });

        it('Withdraw UnStake token before locking period', async function () {
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            expectEvent(stake, "Staking", {
                _from:to,
                _value: amt,
            });
            console.log("stokens bal: " + await stokens.balanceOf(to))
           let unStake = await liquidStaking.unStake(to,val,{from: to,});
            expectEvent(unStake, "Unstaking", {
                _from:to,
                _value: val,
            });
            await expectRevert(liquidStaking.withdrawUnstakedTokens({from: to,}), "revert");
        });
    })
}); // DESCRIBE END