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
var { expect } = require("chai");
const LiquidStaking = contract.fromArtifact("LiquidStaking");

/* each smart contract function will have one 'describe' test function defined , 
and multiple 'it' test functions which checks multiple test scenario */

// tests pertaining to all Constructor() calls
describe("## Constructor() when revert cases happen ##", function () {
  // VARIABLES USED IN TEST
  var liquidStaking;
  var _uaddress;
  var _saddress;
  it("TEST: Constructor() when _uaddress is address(0): ", async function () {
    _uaddress = address(0);
    _saddress = accounts[2];
    console.log(
      "_uaddress: ",
      _uaddress.toString(),
      " _saddress: ",
      _saddress.toString()
    );
    // DEPLOY CONTRACT
    expectRevert(
      LiquidStaking.new(_uaddress, _saddress, { from: accounts[0] }),
      "constructor#1"
    );
    // DEPLOY END
  }, 200000); // TEST END

  it("TEST: Constructor() when _saddress is address(0): ", async function () {
    _saddress = address(0);
    _uaddress = accounts[1];
    console.log(
      "_uaddress: ",
      _uaddress.toString(),
      " _saddress: ",
      _saddress.toString()
    );
    // DEPLOY CONTRACT
    expectRevert(
      LiquidStaking.new(_uaddress, _saddress, { from: accounts[0] }),
      "constructor#1"
    );
    // DEPLOY END
  }, 200000); // TEST END
}); // DESCRIBE END

// tests pertaining to all generateUTokens() calls
describe("## generateUTokens() txn function related tests ##", function () {
  // VARIABLES USED IN TEST
  var liquidStaking;
  var to;
  var amount;
  var _uaddress;
  var _saddress;

  it("TEST: generateUTokens() successful execution scenario: ", async function () {
    _saddress = accounts[2];
    _uaddress = accounts[1];
    to = accounts[3];
    amount = new BN("10000000000000000000");
    // DEPLOY CONTRACT
    liquidStaking = await LiquidStaking.new(_uaddress, _saddress, {
      from: accounts[0],
    });
    console.log("contract deployed successfully ");
    // DEPLOY END

    // TEST SCENARIO
    let generateUTokensTxnReceipt = await liquidStaking.generateUTokens(
      to,
      amount,
      {
        from: accounts[0],
      }
    );

    // test if the event 'Transfer(sender, recipient, amount)' is emitted:
    expectEvent(generateUTokensTxnReceipt, "Transfer", {
      sender: constants.ZERO_ADDRESS,
      recipient: accounts[3],
      amount: new BN("10000000000000000000"),
    });
    // TEST SCENARIO END
  }, 200000); // TEST END
}); // DESCRIBE END

/* 
Other expect statements you can use to verify test scenarios: 
  expect(someBigNumberVal).to.be.bignumber.equal(anotherBigNumberVal);
  expect(someBigNumberVal).to.be.bignumber.equal(new BN(-1));
  expect(someValue).to.not.equal(anotherValue);
  expect(someValue).to.equal(anotherValue);
  expect(await liquidStaking.someFunction(argumentVal)).to.equal(returnValue);
*/
