const StakeLPCoreArtifactV7 = artifacts.require("StakeLPCoreV7");
const StakeLPCoreArtifactV6 = artifacts.require("StakeLPCoreV6");

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
    StakeLPCoreArtifactV6.address,
    StakeLPCoreArtifactV7,
    { deployer }
  );

  console.log("StakeLPCore upgraded to StakeLPCoreV7: ", StakeLPCoreInstance.address);

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
