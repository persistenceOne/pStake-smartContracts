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
const TokenWrapper = artifacts.require('TokenWrapper');
const sTokens = artifacts.require('STokens');
const uTokens = artifacts.require('UTokens');

const toAtomAddress = "toAtomAddress"
let defaultAdmin = "0x45fD163832c0F3Bb67f17685A291697d08C9c252";
let bridgeAdmin = "0x65aa7409C43f8361440B2EC0dA4e1cc0670C9de8";
let pauseAdmin = "0x26229886F35D551745C227D663F58284D6E082e6";
let to = "0x4DB38b4a13Cc484965e1EEA8AF597427A44f8145";
let unknownAddress = "0xb05CCF5775343A2576a852c534Cf55E24E283882";

describe("Liquid Staking", function () {
    this.timeout(0);
    let liquidStaking;
    let tokenWrapper;
    let utokens;
    let stokens;
    let value = new BN(20000000);
    let amt = new BN(150);
    let amount = new BN(200);
    let val = new BN(50);
    let rate = 2;
    beforeEach(async function (){
        this.project = await TestHelper()

        utokens = await deployProxy(uTokens, [bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        stokens = await deployProxy(sTokens, [utokens.address, pauseAdmin], { initializer: 'initialize' });

        tokenWrapper = await deployProxy(TokenWrapper, [utokens.address, stokens.address, bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        liquidStaking = await deployProxy(LiquidStaking, [utokens.address, stokens.address, tokenWrapper.address, bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        await utokens.setSTokenContract(stokens.address,{from: defaultAdmin})
        await utokens.setWrapperContract(tokenWrapper.address,{from: defaultAdmin})
        await utokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})

        await stokens.setWrapperContract(tokenWrapper.address,{from: defaultAdmin})
        await stokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})

        await tokenWrapper.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})
    });

    describe("sTokens", function () {
        it('Only Staker can mint new sTokens', async function () {
            let generate = await tokenWrapper.generateUTokens(to,amount,{from: bridgeAdmin,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: amt,
            });
        });

        it('Malicious/illegitimate actor cannot mint sTokens', async function () {
            await tokenWrapper.generateUTokens(to,amount,{from: bridgeAdmin,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            await expectRevert(liquidStaking.stake(to, amount, {from: unknownAddress,}), "LiquidStaking: Staking can only be done by Staker");
        });

        it('Get Reward Rate', async function () {
            await stokens.setRewardRate(rate,{from: defaultAdmin,});
            let rewardRate = await stokens.getRewardRate({from: defaultAdmin,});
            expect(rewardRate == rate);
        });

        it('Get Staked Block', async function () {
            let generate = await tokenWrapper.generateUTokens(to,amount,{from: bridgeAdmin,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: amt,
            });
            let stakedBlock = await stokens.getStakedBlock(to,{from: defaultAdmin,});
            expect(stakedBlock>0);
        });
    });

    describe("Staking", function () {
        it('Generate uTokens', async function () {
            let generate = await tokenWrapper.generateUTokens(to,amount,{from: bridgeAdmin,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: amount,
            });
        });

        it('Number of staked tokens should be greater than 0', async function () {
            let val = new BN(0);
            expectRevert(liquidStaking.stake(to,val,{from: to,}),"LiquidStaking: Number of staked tokens should be greater than 0");
        });

        it('Insuffcient balance for account', async function () {
            let generate = await tokenWrapper.generateUTokens(to,amt,{from: bridgeAdmin,});
            let balance = await utokens.balanceOf(to);
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: amt,
            });
            expect(balance == amt)
            await expectRevert(liquidStaking.stake(to, amount, {from: to,}), "LiquidStaking: Insuffcient balance for account");
        });

        it('Stake', async function () {
            let generate = await tokenWrapper.generateUTokens(to,amount,{from: bridgeAdmin,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: amt,
            });
        });
    })
    describe("Set Reward Rate", function () {
        it('Non-Owner cannot call setRewardRate()', async function () {
            await expectRevert(stokens.setRewardRate(rate,{from: unknownAddress,}), "STokens: User not authorised to set reward rate");
        },200000);

        it('Only owner can call setRewardRate()', async function () {
            await stokens.setRewardRate(rate,{from: defaultAdmin,});
        },200000);
    })

    describe("Calculate Reward", function () {
        it('Only staker can initiate their own rewards calculation', async function () {
            expectRevert(stokens.calculateRewards(to, {from: unknownAddress,}), "STokens: only staker can initiate their own rewards calculation");
        },200000);

        it('Call CalculateRewards before staking any atom', async function () {
            let reward = await stokens.calculateRewards(to,{from: to,});
            expect(reward >= stokens.balanceOf(to));
            expectEvent(reward, "TriggeredCalculateRewards", {
                accountAddress:to,
                tokens:new BN(0),
            });
        },200000);

        it('Calculate Pending Rewards with double minting', async function () {
            let generate = await tokenWrapper.generateUTokens(to,amount,{from: bridgeAdmin,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: amt,
            });
            stake = await liquidStaking.stake(to,val,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>val)
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: val,
            });
            let reward = await stokens.calculatePendingRewards(to,{from: to,});
            expect(reward >= stokens.balanceOf(to));
        },200000);

        it('Calculate Rewards with double minting', async function () {
            let generate = await tokenWrapper.generateUTokens(to,amount,{from: bridgeAdmin,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: amt,
            });
            stake = await liquidStaking.stake(to,val,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>val)
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: val,
            });
            let reward = await stokens.calculateRewards(to,{from: to,});
            expect(reward >= stokens.balanceOf(to));
            expectEvent(reward, "CalculateRewards", {
                accountAddress:to,
            });
            expectEvent(reward, "TriggeredCalculateRewards", {
                accountAddress:to,
            });
        },200000);

        it('Call CalculateRewards()', async function () {
            let generate = await tokenWrapper.generateUTokens(to,amount,{from: bridgeAdmin,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: amt,
            });
            let reward = await stokens.calculateRewards(to,{from: to,});
            expect(reward >= stokens.balanceOf(to));
            expectEvent(reward, "CalculateRewards", {
                accountAddress:to,
            });
            expectEvent(reward, "TriggeredCalculateRewards", {
                accountAddress:to,
            });
        },200000);

        it('Verify CalculateRewards() in Staking', async function () {
           let generate = await tokenWrapper.generateUTokens(to,amount,{from: bridgeAdmin,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: amt,
            });

            stake = await liquidStaking.stake(to,val,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>val)
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: val,
            });
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
        },200000);

        it('Verify CalculateRewards() in Unstaking', async function () {
           let generate = await tokenWrapper.generateUTokens(to,amount,{from: bridgeAdmin,});
            let balance = await utokens.balanceOf(to);
            expect(balance == amount)
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to,amt,{from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance>=amt)
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: amt,
            });
            let unstake = await liquidStaking.unStake(to,val,{from: to,});
            expect(balance>amt)
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
            expectEvent(unstake, "UnstakeTokens", {
                accountAddress:to,
                tokens: val,
            });
        },200000);
    });

    describe("Transfer", function () {
       it('Transfer amount exceeds balance', async function () {
            await expectRevert(stokens.transfer(unknownAddress,amount,{from: to,}), "revert");
        },200000);

        it('Transfer', async function () {
            let generate = await tokenWrapper.generateUTokens(to,amount,{from: bridgeAdmin,});
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
                to:to,
                tokens: amt,
            });
            let transferTokens = await stokens.transfer(unknownAddress,val,{from: to,});
            expectEvent(transferTokens, "Transfer", {
                to:unknownAddress,
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
            await expectRevert(liquidStaking.unStake(to, amount, {from: unknownAddress,}), "Unstaking can only be done by Staker");
        },200000);

        it('Current sToken balance should be greater than unstaked amount', async function () {
            let generate = await tokenWrapper.generateUTokens(to, amount, {from: bridgeAdmin,});
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to, amt, {from: to,});
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: amt,
            });
            let balance = await stokens.balanceOf(to);
            expect(balance >= amt)
            await expectRevert(liquidStaking.unStake(to, amount, {from: to,}), "LiquidStaking: Insuffcient balance for account");
        },200000);

        it('UnStake', async function () {
            let generate = await tokenWrapper.generateUTokens(to, amount, {from: bridgeAdmin,});
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to, amt, {from: to,});
            let balance = await stokens.balanceOf(to);
            expect(balance >= amt)
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: amt,
            });
            let unstake = await liquidStaking.unStake(to, val, {from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance > amt)
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
            expectEvent(unstake, "UnstakeTokens", {
                accountAddress:to,
                tokens: val,
            });
        },200000);

        it('Get unbonding tokens', async function () {
            let generate = await tokenWrapper.generateUTokens(to, amount, {from: bridgeAdmin,});
            expectEvent(generate, "GenerateUTokens", {
                accountAddress:to,
                tokens: amount,
            });
            let stake = await liquidStaking.stake(to, amt, {from: to,});
            let balance = await stokens.balanceOf(to);
            expect(balance >= amt)
            expectEvent(stake, "StakeTokens", {
                accountAddress:to,
                tokens: amt,
            });
            let unstake = await liquidStaking.unStake(to, val, {from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance > amt)
            let totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
            expectEvent(unstake, "UnstakeTokens", {
                accountAddress:to,
                tokens: val,
            });
            unstake = await liquidStaking.unStake(to, val, {from: to,});
            balance = await stokens.balanceOf(to);
            expect(balance > amt)
            totalBalance = amt + val
            expect(totalBalance > await utokens.balanceOf(to));
            expectEvent(unstake, "UnstakeTokens", {
                accountAddress:to,
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
                let generate = await tokenWrapper.generateUTokens(to,amount,{from: bridgeAdmin,});
                let balance = await utokens.balanceOf(to);
                expect(balance == amount)
                expectEvent(generate, "GenerateUTokens", {
                    accountAddress:to,
                    tokens: amount,
                });
                await expectRevert(tokenWrapper.withdrawUTokens(to,_val,toAtomAddress,{from: to,}),"TokenWrapper: Number of unstaked tokens should be greater than 0");
            },200000);

            it('Current uToken balance should be greater than staked amount', async function () {
                let generate = await tokenWrapper.generateUTokens(to,amt,{from: bridgeAdmin,});
                let balance = await utokens.balanceOf(to);
                expect(balance == amt)
                expectEvent(generate, "GenerateUTokens", {
                    accountAddress:to,
                    tokens: amt,
                });
                await expectRevert(tokenWrapper.withdrawUTokens(to, amount, toAtomAddress, {from: to,}), "TokenWrapper: Insuffcient balance for account");
            },200000);

            it('Only staker can withdraw', async function () {
                let generate = await tokenWrapper.generateUTokens(to, amount, {from: bridgeAdmin,});
                let balance = await utokens.balanceOf(to);
                expect(balance == amt);
                expectEvent(generate, "GenerateUTokens", {
                    accountAddress:to,
                    tokens: amount,
                });
                await expectRevert(tokenWrapper.withdrawUTokens(to, amt, toAtomAddress, {from: unknownAddress,}), "TokenWrapper: Withdraw can only be done by Staker");
            },2000000);

            it('Withdraw uTokens', async function () {
                let generate = await tokenWrapper.generateUTokens(to, amount, {from: bridgeAdmin,});
                let balance = await utokens.balanceOf(to);
                expect(balance == amt)
                expectEvent(generate, "GenerateUTokens", {
                    accountAddress:to,
                    tokens: amount,
                });
                let withdraw = await tokenWrapper.withdrawUTokens(to, amt, toAtomAddress, {from: to,});
                let _val = balance - amt;
                balance = await utokens.balanceOf(to);
                expect(balance == _val)
                expectEvent(withdraw, "WithdrawUTokens", {
                    accountAddress:to,
                    tokens: amt,
                    toAtomAddress: toAtomAddress,
                });
            },2000000);
        });

        describe("Withdraw unStaked tokens", function () {
            it('Only staker can withdraw', async function () {
                await expectRevert(liquidStaking.withdrawUnstakedTokens(to, {from: unknownAddress,}), "LiquidStaking: Only staker can withdraw");
            },200000);

            it('Cannot withdraw UnStake token before locking period', async function () {
                let generate = await tokenWrapper.generateUTokens(to, amount, {from: bridgeAdmin,});
                await expectEvent(generate, "GenerateUTokens", {
                    accountAddress:to,
                    tokens: amount,
                });
                let stake = await liquidStaking.stake(to, amt, {from: to,});
                await expectEvent(stake, "StakeTokens", {
                    accountAddress:to,
                    tokens: amt,
                });
                let balance = await stokens.balanceOf(to);
                expect(balance >= amt)
                let unstake = await liquidStaking.unStake(to, val, {from: to,});
                await expectEvent(unstake, "UnstakeTokens", {
                    accountAddress:to,
                    tokens: val,
                });
                await expectRevert(liquidStaking.withdrawUnstakedTokens(to, {from: to,}), "LiquidStaking: UnStaking period still pending");
            },2000000);

            it('Multi-lock for same user', async function () {
                let generate = await tokenWrapper.generateUTokens(to, amount, {from: bridgeAdmin,});
                await expectEvent(generate, "GenerateUTokens", {
                    accountAddress:to,
                    tokens: amount,
                });
                let stake = await liquidStaking.stake(to, amt, {from: to,});
                let balance = await stokens.balanceOf(to);
                expect(balance >= amt)
                await expectEvent(stake, "StakeTokens", {
                    accountAddress:to,
                    tokens: amt,
                });
                let unstake = await liquidStaking.unStake(to, val, {from: to,});
                await expectEvent(unstake, "UnstakeTokens", {
                    accountAddress:to,
                    tokens: val,
                });
                unstake = await liquidStaking.unStake(to, val, {from: to,});
                balance = await stokens.balanceOf(to);
                expect(balance > amt)
                let _val = val+val
                let totalBalance = amt + _val
                expect(totalBalance > await utokens.balanceOf(to));
                await expectEvent(unstake, "UnstakeTokens", {
                    accountAddress:to,
                    tokens: val,
                });
                await expectRevert(liquidStaking.withdrawUnstakedTokens(to, {from: to,}), "LiquidStaking: UnStaking period still pending");
            },2000000);
        });
    });

    describe("Pausable", function () {
        it('Only pauser admin can pause contracts', async function () {
            await liquidStaking.pause({from: pauseAdmin,});
            let checkPause = await liquidStaking.paused();
            expect(checkPause === true)
        });

        it('Non pauser admin cannot pause contracts', async function () {
            await expectRevert(liquidStaking.pause({from: to,}), "LiquidStaking: User not authorised to pause contracts");
        });

        it('Transactions could not be sent to paused contracts', async function () {
            await liquidStaking.pause({from: pauseAdmin,});
            let checkPause = await liquidStaking.paused();
            expect(checkPause === false)
            await expectRevert(liquidStaking.stake(to, amt, {from: to,}), "Pausable: paused");
        });

        it('Only pauser admin can unpause contracts', async function () {
            await liquidStaking.pause({from: pauseAdmin,});
            let checkPause = await liquidStaking.paused();
            expect(checkPause === true)

            await liquidStaking.unpause({from: pauseAdmin,});
            checkPause = await liquidStaking.paused();
            expect(checkPause === false)
        });

        it('Non pauser admin cannot unpause contracts', async function () {
            await expectRevert(liquidStaking.unpause({from: to,}), "LiquidStaking: User not authorised to unpause contracts");
        });
    });
}); // DESCRIBE END