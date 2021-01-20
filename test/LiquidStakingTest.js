//UNIT TEST

/* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
which we will be using for our unit testing. */

/* consider accounts[0] as LiquidStaking contract owner address, accounts[1] as uTokens contract owner address,
and accounts[2] as sTokens contract owner address, rest 6 accounts you can use as legitimate stakers or malicious user address */

/* You will have to create the following 'default test scenarios' which applies for every smart contract function,
then some 'custom test scenarios' that applies for those specific smart contract functions as per their routine:
@ All contract functions need their 'require statements' tested
@ All contract functions need their modifiers tested by calling the function using - owner address, staker address,
and malicious user address
@ All contract functions need all the events generated tested using expectEvent (example given below)
@ Apart from all this, every contract function needs to be tested for the result of its routine seperately
*/

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

/* each smart contract function will have one 'describe' test function defined ,
and multiple 'it' test functions which checks multiple test scenario */

// tests pertaining to all Constructor() calls
describe("Liquid Staking", function () {
    describe("Staking", function () {
        let to = accounts[3];
        let from = accounts[1];
        let liquidStaking;
        let amt = new BN(50);
        let amount = new BN(100);
        beforeEach(async function () {
            let utokens = await uTokens.new({ from: from});
            let stokens = await sTokens.new(utokens.address, {from: from,});

            // DEPLOY CONTRACT
            liquidStaking = await LiquidStaking.new(utokens.address, stokens.address, {
                from: from,
            });
        });
        it('generate uTokens', async function () {
            await liquidStaking.generateUTokens(from,amount,{from: from,});
            let balance = await liquidStaking.getUtokenBalance(from);
            expect(balance == amount)
        });

        it('Number of staked tokens should be greater than 0', async function () {
            let val = new BN(0);
            expectRevert(liquidStaking.stake(to,val,{from: from,}),"revert");
        });

        it('Current uToken balance should be greater than staked amount', async function () {
            await liquidStaking.generateUTokens(to,amt,{from: from,});
            let balance = await liquidStaking.getUtokenBalance(from);
            expect(balance == amt)
            await expectRevert(liquidStaking.stake(to, amount, {from: from,}), "revert");
        });

        it('Stake', async function () {
            let generateUToken = await liquidStaking.generateUTokens(to,amount,{from: from,});
            let balance = await liquidStaking.getUtokenBalance(to);
            console.log("generateUToken: " + JSON.stringify(generateUToken))
            console.log("bal: " + balance)
            expect(balance == amount)
            let stake = await liquidStaking.stake(to,amt,{from: from,});
            // expectEvent(generateUToken, "Transfer", {
            //     to:from,
            //     value: amount,
            // });
            // expectEvent(stake, "Transfer", {
            //     to:to,
            //     value: amt,
            // });
            expectEvent(stake, "Staking", {
                _from:to,
                _value: amt,
            });
        });
    })

    describe("UnStaking", function () {
        let to = accounts[3];
        let from = accounts[1];
        let amount = new BN(100);
        let amt = new BN(50);
        let liquidStaking;
        beforeEach(async function () {
            let utokens = await uTokens.new({ from: from});
            let stokens = await sTokens.new(utokens.address, {from: from,});
            // DEPLOY CONTRACT
            liquidStaking = await LiquidStaking.new(utokens.address, stokens.address, {
                from: from,
            });
        });

        it('Number of unstaked tokens should be greater than 0', async function () {
            let val = new BN(0);
            await expectRevert(liquidStaking.unStake(to, val, {from: from,}), "revert");
        });

        it('Current stoken balance should be greater than unstaked amount', async function () {
            let generateUToken = await liquidStaking.generateUTokens(to,amt,{from: from,});
            let stake = await liquidStaking.stake(to,amount,{from: from,});
            expectEvent(generateUToken, "Transfer", {
                to:to,
                value: amt,
            });
            expectEvent(stake, "Transfer", {
                to:to,
                value: amount,
            });
            expectEvent(stake, "Staking", {
                _from:to,
                _value: amount,
            });
            await expectRevert(liquidStaking.unStake(to, amount, {from: from,}), "revert");
        });

        it('UnStake', async function () {
           let generateUToken = await liquidStaking.generateUTokens(to,amount,{from: from,});
            let stake = await liquidStaking.stake(to,amt,{from: from,});
            expectEvent(generateUToken, "Transfer", {
                to:to,
                value: amount,
            });
            expectEvent(stake, "Transfer", {
                to:to,
                value: amt,
            });
            expectEvent(stake, "Staking", {
                _from:to,
                _value: amt,
            });
            let unStake = await liquidStaking.unStake(to,amt,{from: from,});
            expectEvent(unStake, "Transfer", {
                to:to,
                value: amt,
            });
            expectEvent(unStake, "Unstaking", {
                _from:to,
                _value: amt,
            });
        });

        it('Withdraw UnStake token before locking period', async function () {
            let generateUToken = await liquidStaking.generateUTokens(to,amount,{from: from,});
            let stake = await liquidStaking.stake(to,amt,{from: from,});
            expectEvent(generateUToken, "Transfer", {
                to:to,
                value: amount,
            });
            expectEvent(stake, "Transfer", {
                to:to,
                value: amt,
            });
            expectEvent(stake, "Staking", {
                _from:to,
                _value: amt,
            });
            let unStake = await liquidStaking.unStake(to,amount,{from: from,});
            expectEvent(unStake, "Transfer", {
                to:to,
                value: amt,
            });
            expectEvent(stake, "Unstaking", {
                _from:to,
                _value: amt,
            });
            await expectRevert(liquidStaking.withdrawUnstakedTokens({from: from,}), "revert");
        });
    })
}); // DESCRIBE END

/*
Other expect statements you can use to verify test scenarios:
  expect(someBigNumberVal).to.be.bignumber.equal(anotherBigNumberVal);
  expect(someBigNumberVal).to.be.bignumber.equal(new BN(-1));
  expect(someValue).to.not.equal(anotherValue);
  expect(someValue).to.equal(anotherValue);
  expect(await liquidStaking.someFunction(argumentVal)).to.equal(returnValue);
*/
