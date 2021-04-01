const VestingTimelock = artifacts.require("VestingTimelock");
const BN = web3.utils.BN;
const vestingBeneficiaries = require("./vestingBeneficiaries");
const BigNumber = require("bignumber.js");

const toFixedBigNumber2 = function (valueString) {
  const splitObject = valueString.toString().split(".");
  const firstSplitValue = splitObject[0];
  return new BN(firstSplitValue.toString());
};

const toFixedBigNumber = function (valueString) {
  const valueBigNumber = new BigNumber(valueString).toFixed(0);
  //console.log("valueBigNumber: ", valueBigNumber);
  return valueBigNumber;
};

module.exports = async function (callback) {
  let defaultAdmin = "0x466aF9ea44f2dEbbE4fd54a98CffA26A3674fBf7";
  let VestingTimelockInstance;

  let amounts = [];
  let startTimes = [];
  let cliffs = [];
  let beneficiaries = [];

  let consolidatedBeneficiariesWithNonZero = []
  let consolidatedAmountsWithNonZero = []


  for(let k = 0; k<vestingBeneficiaries.consolidatedDecimalAmounts.length; k++){
    if(vestingBeneficiaries.consolidatedDecimalAmounts[k].toString().split(".")[0] == "0"){
      //do nothing
    }else{
      consolidatedAmountsWithNonZero.push(vestingBeneficiaries.consolidatedDecimalAmounts[k])
      consolidatedBeneficiariesWithNonZero.push(vestingBeneficiaries.consolidatedBeneficiaries[k])
    }
  }
  console.log("consolidatedAmountsWithNonZero: " + consolidatedAmountsWithNonZero.length)
  console.log("consolidatedBeneficiariesWithNonZero: " + consolidatedBeneficiariesWithNonZero.length)

  let totalAmount = new BN("10000000000");
  let startIndex = 0;
  let startTime_ = parseInt(Date.now() / 1000);
  let cliff_ = parseInt(Date.now() / 1000) + 600;

  console.log("Inside Grant Script....");
  console.log("Before deploy...")
  let i = 0;
  let j = 0;

  for(i = 0; i<50; i++){
    amounts = []
    startTimes = []
    beneficiaries = []
    cliffs = []
    for(j = startIndex; j<startIndex+20; j++ ){
      amounts.push(
          toFixedBigNumber(
              consolidatedAmountsWithNonZero[j]
          )
      );
      startTimes.push(startTime_);
      beneficiaries.push(
          consolidatedBeneficiariesWithNonZero[j]
      );
      cliffs.push(cliff_);
    }

    startIndex = j;
    console.log("startIndex: " + startIndex)

    await VestingTimelock.deployed()
        .then((instance) => {
          VestingTimelockInstance = instance;
          // estimate gas value
          return VestingTimelockInstance.addGrants(
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
          return VestingTimelockInstance.getGrant(
              vestingBeneficiaries.consolidatedBeneficiaries[startIndex]
          );
        })
        .then((grant) => {
          console.log("Grant : ", grant);
        })
        //.then(() => callback())
        .catch((err) => callback(err));
  }
};
