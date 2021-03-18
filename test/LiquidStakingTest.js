//UNIT TEST

/* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
which we will be using for our unit testing. */

const {web3} = require("@openzeppelin/test-helpers/src/setup");
const {
    deployProxy,
} = require("@openzeppelin/truffle-upgrades");

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
const { TestHelper } = require('zos');
const { Contracts, ZWeb3 } = require('zos-lib');

ZWeb3.initialize(web3.currentProvider);
const { expect } = require("chai");
const LiquidStaking = artifacts.require('LiquidStaking');
const sTokens = artifacts.require('STokens');
const uTokens = artifacts.require('UTokens');
/*const LiquidStaking = Contracts.getFromLocal("LiquidStaking");
const sTokens = Contracts.getFromLocal("STokens");
const uTokens = Contracts.getFromLocal("UTokens");*/
const toAtomAddress = "toAtomAddress"
let to = accounts[3];
let from = accounts[1];
let anotherAccount = accounts[4];

describe("Liquid Staking", function () {
    this.timeout(0);
    let liquidStaking;
    let utokens;
    let stokens;
    let amt = new BN(150);
    let amount = new BN(200);
    let val = new BN(50);
    let rate = 2;
    beforeEach(async function (){
        this.project = await TestHelper()

        utokens = await deployProxy(uTokens, [], { initializer: 'initialize' });

        stokens = await deployProxy(sTokens, [utokens.address], { initializer: 'initialize' });

        liquidStaking = await deployProxy(LiquidStaking, [utokens.address, stokens.address], { initializer: 'initialize' });

        /*utokens = await this.project.createProxy(uTokens, {
            initMethod: 'initialize',
            initArgs: [],
            from: from,
        });
        console.log("utokens" + utokens)

        stokens = await this.project.createProxy(sTokens, {
            initMethod: 'initialize',
            initArgs: [utokens.address],
            from: from,
        });

        liquidStaking = await this.project.createProxy(LiquidStaking, {
            initMethod: 'initialize',
            initArgs: [utokens.address, stokens.address],
            from: from,
        });*/
        //utokens = await uTokens.initialize({ from: from});
        /*stokens = await sTokens.initialize(utokens.address, {from: from,});
        liquidStaking = await LiquidStaking.initialize(utokens.address, stokens.address, {
            from: from,
        });*/
        console.log(utokens,"utokens")
        console.log(stokens,"stokens")
        console.log(liquidStaking,"liquidStaking")
        await utokens.methods.setSTokenContractAddress(stokens.address).send({from: from,});
        await utokens.methods.setLiquidStakingContractAddress(liquidStaking.address).send({from: from,});
        await stokens.methods.setUTokensContract(utokens.address).send({from: from,});
        await stokens.methods.setLiquidStakingContractAddress(liquidStaking.address).send({from: from,});
    });
    describe("uTokens", function () {
        it('Only owner can mint new uTokens for a user.', async function () {
            console.log(utokens+"utokens")
            console.log(stokens+"stokens")
            console.log(liquidStaking+"liquidStaking")
            let generate = await liquidStaking.methods.generateUTokens(to,amount).send({from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amount,
            });
        });

        it('Number of tokens should be greater than 0', async function () {
            let val = new BN(0);
            await expectRevert(liquidStaking.generateUTokens(to,val,{from: from,}),"LiquidStaking: Number of tokens should be greater than 0");
        });

        it('Malicious/illegitimate actor cannot mint uTokens for a user', async function () {
            await expectRevert(liquidStaking.generateUTokens(to,amount,{from: anotherAccount,}),"LiquidStaking: Only owner can mint new tokens for a user");
        });
    });

    /*describe("sTokens", function () {
        it('Only Staker can mint new sTokens', async function () {
            let generate = await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: amt,
            });
        });

        it('Malicious/illegitimate actor cannot mint sTokens', async function () {
            await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            await expectRevert(liquidStaking.stake(to, amount, {from: anotherAccount,}), "LiquidStaking: Staking can only be done by Staker");
        });

        it('Get Reward Rate', async function () {
            await stokens.setRewardRate(rate,{from: from,});
            let rewardRate = await stokens.getRewardRate({from: from,});
            expect(rewardRate == rate);
        });

        it('Get Staked Block', async function () {
            let generate = await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: amt,
            });
            let stakedBlock = await stokens.getStakedBlock(to,{from: from,});
            expect(stakedBlock>0);
        });
    });

    describe("Staking", function () {
        it('Generate uTokens', async function () {
            let generate = await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amount,
            });
        });

        it('Number of staked tokens should be greater than 0', async function () {
            let val = new BN(0);
            expectRevert(liquidStaking.stake(to,val,{from: from,}),"LiquidStaking: Number of staked tokens should be greater than 0");
        });

        it('Insuffcient balance for account', async function () {
            let generate = await liquidStaking.generateUTokens(to,amt,{from: from,});
            let balance = await utokens.balanceOf(to);
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amt,
            });
            expect(balance == amt)
            await expectRevert(liquidStaking.stake(to, amount, {from: to,}), "LiquidStaking: Insuffcient balance for account");
        });

        it('Stake', async function () {
            let generate = await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: amt,
            });
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
        it('Only staker can initiate their own rewards calculation', async function () {
            expectRevert(stokens.calculateRewards(to, {from: anotherAccount,}), "STokens: only staker can initiate their own rewards calculation");
        },200000);

        it('Call CalculateRewards before staking any atom', async function () {
            let reward = await stokens.calculateRewards(to,{from: to,});
            expect(reward >= stokens.balanceOf(to));
            expectEvent(reward, "TriggeredCalculateRewards", {
                to:to,
                tokens:new BN(0),
            });
        },200000);

        it('Calculate Pending Rewards with double minting', async function () {
            let generate = await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: amt,
            });
            stake = await liquidStaking.stake(to,val,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>val)
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: val,
            });
            let reward = await stokens.calculatePendingRewards(to,{from: to,});
            expect(reward >= stokens.balanceOf(to));
        },200000);

        it('Calculate Rewards with double minting', async function () {
            let generate = await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: amt,
            });
            stake = await liquidStaking.stake(to,val,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>val)
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: val,
            });
            let reward = await stokens.calculateRewards(to,{from: to,});
            expect(reward >= stokens.balanceOf(to));
            expectEvent(reward, "CalculateRewards", {
                to:to,
            });
            expectEvent(reward, "TriggeredCalculateRewards", {
                to:to,
            });
        },200000);

        it('Call CalculateRewards()', async function () {
            let generate = await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: amt,
            });
            let reward = await stokens.calculateRewards(to,{from: to,});
            expect(reward >= stokens.balanceOf(to));
            expectEvent(reward, "CalculateRewards", {
                to:to,
            });
            expectEvent(reward, "TriggeredCalculateRewards", {
                to:to,
            });
        },200000);

        it('Verify CalculateRewards() in Staking', async function () {
           let generate = await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: amt,
            });

            stake = await liquidStaking.stake(to,val,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>val)
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: val,
            });
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
        },200000);

        it('Verify CalculateRewards() in Unstaking', async function () {
           let generate = await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: amt,
            });
            let unstake = await liquidStaking.unStake(to,val,{from: to,});
            expect(balance>amt)
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
            expectEvent(unstake, "UnstakeTokens", {
                staker:to,
                tokens: val,
            });
        },200000);
    });

    describe("Transfer", function () {
       it('Transfer amount exceeds balance', async function () {
            await expectRevert(stokens.transfer(anotherAccount,amount,{from: to,}), "revert");
        },200000);

        it('Transfer', async function () {
            let generate = await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await utokens.balanceOf(from);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: amt,
            });
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
        },200000);

        it('Non-staker cannot withdraw', async function () {
            await expectRevert(liquidStaking.unStake(to, amount, {from: anotherAccount,}), "Unstaking can only be done by Staker");
        },200000);

        it('Current sToken balance should be greater than unstaked amount', async function () {
            let generate = await liquidStaking.generateUTokens(to, amount, {from: from,});
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to, amt, {from: to,});
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: amt,
            });
            let balance = await stokens.balanceOf(to);
            expect(balance >= amt)
            await expectRevert(liquidStaking.unStake(to, amount, {from: to,}), "LiquidStaking: Insuffcient balance for account");
        },200000);

        it('UnStake', async function () {
            let generate = await liquidStaking.generateUTokens(to, amount, {from: from,});
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to, amt, {from: to,});
            let balance = await stokens.balanceOf(to);
            expect(balance >= amt)
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: amt,
            });
            let unstake = await liquidStaking.unStake(to, val, {from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance > amt)
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
            expectEvent(unstake, "UnstakeTokens", {
                staker:to,
                tokens: val,
            });
        },200000);

        it('Get unbonding tokens', async function () {
            let generate = await liquidStaking.generateUTokens(to, amount, {from: from,});
            expectEvent(generate, "GenerateUTokens", {
                to:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to, amt, {from: to,});
            let balance = await stokens.balanceOf(to);
            expect(balance >= amt)
            expectEvent(stake, "StakeTokens", {
                staker:to,
                tokens: amt,
            });
            let unstake = await liquidStaking.unStake(to, val, {from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance > amt)
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
            expectEvent(unstake, "UnstakeTokens", {
                staker:to,
                tokens: val,
            });
            unstake = await liquidStaking.unStake(to, val, {from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance > amt)
            totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
            expectEvent(unstake, "UnstakeTokens", {
                staker:to,
                tokens: val,
            });
            let unbondTokens = await liquidStaking.getTotalUnbondedTokens(to, {from: to,});
            expect(unbondTokens == val)
        },200000);
    });

    describe("Withdraw", function () {
        describe("Withdraw uTokens", function () {
            it('Number of utokens should be greater than 0', async function () {
                let _val = new BN(0);
                let generate = await liquidStaking.generateUTokens(to,amount,{from: from,});
                let balance = await utokens.balanceOf(to);
                expect(balance == amount)
                expectEvent(generate, "GenerateUTokens", {
                    to:to,
                    tokens: amount,
                });
                await expectRevert(liquidStaking.withdrawUTokens(to,_val,toAtomAddress,{from: to,}),"LiquidStaking: Number of unstaked tokens should be greater than 0");
            },200000);

            it('Current uToken balance should be greater than staked amount', async function () {
                let generate = await liquidStaking.generateUTokens(to,amt,{from: from,});
                let balance = await utokens.balanceOf(to);
                expect(balance == amt)
                expectEvent(generate, "GenerateUTokens", {
                    to:to,
                    tokens: amt,
                });
                await expectRevert(liquidStaking.withdrawUTokens(to, amount, toAtomAddress, {from: to,}), "LiquidStaking: Insuffcient balance for account");
            },200000);

            it('Only staker can withdraw', async function () {
                let generate = await liquidStaking.generateUTokens(to, amount, {from: from,});
                let balance = await utokens.balanceOf(to);
                expect(balance == amt);
                expectEvent(generate, "GenerateUTokens", {
                    to:to,
                    tokens: amount,
                });
                await expectRevert(liquidStaking.withdrawUTokens(to, amt, toAtomAddress, {from: anotherAccount,}), "LiquidStaking: Withdraw can only be done by Staker");
            },2000000);

            it('Withdraw uTokens', async function () {
                let generate = await liquidStaking.generateUTokens(to, amount, {from: from,});
                let balance = await utokens.balanceOf(to);
                expect(balance == amt)
                expectEvent(generate, "GenerateUTokens", {
                    to:to,
                    tokens: amount,
                });
                let withdraw = await liquidStaking.withdrawUTokens(to, amt, toAtomAddress, {from: to,});
                let _val = balance - amt;
                balance = await utokens.balanceOf(to);
                expect(balance == _val)
                expectEvent(withdraw, "WithdrawUTokens", {
                    from:to,
                    tokens: amt,
                    toAtomAddress: toAtomAddress,
                });
            },2000000);
        });

        describe("Withdraw unStaked tokens", function () {
            it('Only staker can withdraw', async function () {
                await expectRevert(liquidStaking.withdrawUnstakedTokens(to, {from: anotherAccount,}), "LiquidStaking: Only staker can withdraw");
            },200000);

            it('Cannot withdraw UnStake token before locking period', async function () {
                let generate = await liquidStaking.generateUTokens(to, amount, {from: from,});
                await expectEvent(generate, "GenerateUTokens", {
                    to:to,
                    tokens: amount,
                });
                let stake = await liquidStaking.stake(to, amt, {from: to,});
                await expectEvent(stake, "StakeTokens", {
                    staker:to,
                    tokens: amt,
                });
                let balance = await stokens.balanceOf(to);
                expect(balance >= amt)
                let unstake = await liquidStaking.unStake(to, val, {from: to,});
                await expectEvent(unstake, "UnstakeTokens", {
                    staker:to,
                    tokens: val,
                });
                await expectRevert(liquidStaking.withdrawUnstakedTokens(to, {from: to,}), "LiquidStaking: UnStaking period still pending");
            },2000000);

            it('Multi-lock for same user', async function () {
                let generate = await liquidStaking.generateUTokens(to, amount, {from: from,});
                await expectEvent(generate, "GenerateUTokens", {
                    to:to,
                    tokens: amount,
                });
                let stake = await liquidStaking.stake(to, amt, {from: to,});
                let balance = await stokens.balanceOf(to);
                expect(balance >= amt)
                await expectEvent(stake, "StakeTokens", {
                    staker:to,
                    tokens: amt,
                });
                let unstake = await liquidStaking.unStake(to, val, {from: to,});
                await expectEvent(unstake, "UnstakeTokens", {
                    staker:to,
                    tokens: val,
                });
                unstake = await liquidStaking.unStake(to, val, {from: to,});
                balance = await stokens.balanceOf(to);
                expect(balance > amt)
                let _val = val+val
                let totalBalance = amt + _val
                expect(totalBalance > await utokens.balanceOf(to));
                await expectEvent(unstake, "UnstakeTokens", {
                    staker:to,
                    tokens: val,
                });
                await expectRevert(liquidStaking.withdrawUnstakedTokens(to, {from: to,}), "LiquidStaking: UnStaking period still pending");
            },2000000);
        });
    });*/
}); // DESCRIBE END