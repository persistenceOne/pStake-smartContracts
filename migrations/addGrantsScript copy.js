//const VestingTimelockInstance = require('../build/contracts/VestingTimelock.json')
const VestingTimelock = artifacts.require("VestingTimelock");
//const contract = require('truffle-contract')
const BN = web3.utils.BN;
const vestingBeneficiaries = require("./vestingBeneficiaries");
const BigNumber = require("bignumber.js");

const accounts = [
  "0x466aF9ea44f2dEbbE4fd54a98CffA26A3674fBf7",
  "0x51caF3f0E53BAAF12F8B0B6d98350CBA53e8DB7B",
  "0xCC6F6821F903b1FC3C0c9597b26C84E31AC98B36",
  "0xa69dE4538Fd5384FfB4e415B861dBc7eAED75dF2",
  "0x609d344A04245104C312925D2F5aE04F643A10CB",
  "0x7019943Ca5E81d10EFA8ACdd68B0B67Eb4B0a9f6",
  "0x768D4C50C9D4Db6f12Bb47581E4c1823Ad9eCB49",
  "0xe3355d5AD5f8dCdca879230e85eF0AaeE6f28d0B",
  "0x528B19d24426C4A78D0fDC0933c3F91C87102adA",
  "0x3F5fdb1c4B40b04f54082482DCBF9732c1199eB6",
];

const toFixedBigNumber2 = function (valueString) {
  const splitObject = valueString.toString().split(".");
  const firstSplitValue = splitObject[0];
  return new BN(firstSplitValue.toString());
};

const toFixedBigNumber = function (valueString) {
  const valueBigNumber = new BigNumber(valueString.toFixed());
  return valueBigNumber;
};

module.exports = function (callback) {
  let defaultAdmin = "0x466aF9ea44f2dEbbE4fd54a98CffA26A3674fBf7";
  let VestingTimelockInstance;

  let amounts = [];
  let startTimes = [];
  let cliffs = [];
  let beneficiaries = [];

  let totalAmount = new BN("10000000000");
  let startIndex = 631;
  let numUsers = 640;
  let startTime_ = parseInt(Date.now() / 1000);
  let cliff_ = parseInt(Date.now() / 1000) + 600;

  console.log("Inside Grant Script....");

  // create array of grants
  /*  for (let i = 0; i < numUsers; i++) {
    amounts.push(totalAmount.div(new BN(numUsers)));
    startTimes.push(parseInt(Date.now() / 1000));
    beneficiaries.push(accounts[i]);
    cliffs.push(parseInt(Date.now() / 1000) + 600);
  } */

  for (let i = 0; i < numUsers - startIndex; i++) {
    amounts.push(
      toFixedBigNumber(vestingBeneficiaries.consolidatedAmounts[i + startIndex])
    );
    startTimes.push(startTime_);
    beneficiaries.push(
      vestingBeneficiaries.consolidatedBeneficiaries[i + startIndex]
    );
    cliffs.push(cliff_);
  }

  console.log("Before deploy...");
  VestingTimelock.deployed()
    .then((instance) => {
      VestingTimelockInstance = instance;
      console.log(
        "VestinTimeLock deployed:  " + VestingTimelockInstance.address
      );
      console.log(
        "Vesting Beneficiaries: %d",
        vestingBeneficiaries.beneficiaries.length
      );
      console.log("startTimes Size:  ", startTimes);
      console.log("cliffs Size:  ", cliffs.length);
      console.log("beneficiaries Size:  ", beneficiaries.length);
      console.log("amounts Size:  ", amounts.length.toString());
      // estimate gas value
      return VestingTimelockInstance.addGrants.estimateGas(
        startTimes,
        amounts,
        cliffs,
        beneficiaries,
        { from: defaultAdmin }
      );
      // return true;
    })
    .then((receipt) => {
      console.log("addGrants Transaction Executed: ", receipt);
      return instance.getGrant(accounts[4]);
    })
    .then((grant) => {
      console.log("Beneficiary : ", accounts[4]);
      console.log("Grant : ", grant);
    })
    .then(() => callback())
    .catch((err) => callback(err));
};
