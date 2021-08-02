const StakeLPArtifact = artifacts.require("StakeLPCore");
const StakeLPArtifactV2 = artifacts.require("StakeLPCoreV2");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var StakeLPInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeStakeLP(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 5000000;
    await upgradeStakeLP(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeStakeLP(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await upgradeStakeLP(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function upgradeStakeLP(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeStakeLP(),",
    " gasPrice: ",
    gasPrice,
    " gasLimit: ",
    gasLimit,
    " deployer: ",
    deployer.network,
    " accounts: ",
    accounts
  );

  console.log("StakeLP address: ", StakeLPArtifact.address);

  /* StakeLPInstance = await upgradeProxy(
    "0x6532f1cc72F34523aB815d2A7f2754afec17c8B4",
    StakeLPArtifactV2,
    { deployer }
  ); */

  StakeLPInstance = await upgradeProxy(
    StakeLPArtifact.address,
    StakeLPArtifactV2,
    { deployer }
  );

  console.log("StakeLP upgraded: ", StakeLPInstance.address);

  console.log("ALL DONE.");
}
