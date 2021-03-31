//const VestingTimelockInstance = require('../build/contracts/VestingTimelock.json')
const VestingTimelock = artifacts.require("VestingTimelock");
//const contract = require('truffle-contract')
const BN = web3.utils.BN;

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

module.exports = function (callback) {
  let defaultAdmin = "0x466aF9ea44f2dEbbE4fd54a98CffA26A3674fBf7";
  let amount = [];
  let startTime = [];
  let cliff = [];
  let recipient = [];
  let totalAmount = new BN("10000000000");
  let numUsers = 4;
  let VestingTimelockInstance;

  console.log("Inside Grant Script....");
  for (let i = 0; i < numUsers; i++) {
    amount.push(totalAmount.div(new BN(numUsers)));
    startTime.push(parseInt(Date.now() / 1000));
    recipient.push(accounts[i]);
    cliff.push(parseInt(Date.now() / 1000) + 600);
  }
  console.log("Before deploy...");
  VestingTimelock.deployed()
    .then((instance) => {
      VestingTimelockInstance = instance;
      console.log(
        "VestinTimeLock deployed:  " + VestingTimelockInstance.address
      );
      console.log("startTime:  " + startTime);
      console.log("cliff:  " + cliff);
      console.log("recipient:  " + recipient);
      console.log("amount:  " + amount);
      return instance.getGrant(accounts[5]);
    })
    .then((grant) => {
      console.log("Grant: ", grant);
      console.log("VestingTimelockInstance: ", VestingTimelockInstance.address);

      return VestingTimelockInstance.addGrants(
        startTime,
        amount,
        cliff,
        recipient,
        { from: defaultAdmin }
      );
    })
    .then((receipt) => {
      return console.log("addGrants transaction sent: ");
      // return callback();
    })
    .then(() => callback())
    .catch((err) => callback(err));
};
