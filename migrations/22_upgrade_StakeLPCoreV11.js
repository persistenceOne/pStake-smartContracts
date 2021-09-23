const StakeLPCoreArtifactV11 = artifacts.require("StakeLPCoreV11");
const StakeLPCoreArtifactV10 = artifacts.require("StakeLPCoreV10");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var StakeLPCoreInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await StakeLPCore(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await StakeLPCore(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await StakeLPCore(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await StakeLPCore(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function StakeLPCore(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside StakeLPCore(),",
    " gasPrice: ",
    gasPrice,
    " gasLimit: ",
    gasLimit,
    " deployer: ",
    deployer.network,
    " accounts: ",
    accounts
  );

  let from_defaultAdmin = accounts[0];
  let batchingLimit = 20;

  StakeLPCoreInstance = await upgradeProxy(
    StakeLPCoreArtifactV10.address,
    StakeLPCoreArtifactV11,
    { deployer }
  );

  console.log("StakeLPCore upgraded to StakeLPCoreV8: ", StakeLPCoreInstance.address);

  // set contract addresses in StakeLPCore Contract
  /*  const txReceipt = await StakeLPCoreInstance.setBatchingLimit(
    batchingLimit,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setBatchingLimit() done"); */

  console.log("ALL DONE.");
}
