const StakeLPArtifactV7 = artifacts.require("StakeLPCoreV7");
const StakeLPArtifactV6 = artifacts.require("StakeLPCoreV6");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var StakeLPInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeStakeLPCoreV2(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 5000000;
    await upgradeStakeLPCoreV2(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeStakeLPCoreV2(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await upgradeStakeLPCoreV2(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function upgradeStakeLPCoreV2(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeStakeLPCoreV2(),",
    " gasPrice: ",
    gasPrice,
    " gasLimit: ",
    gasLimit,
    " deployer: ",
    deployer.network,
    " accounts: ",
    accounts
  );

  console.log("StakeLP address: ", StakeLPArtifactV6.address);

  /* StakeLPInstance = await upgradeProxy(
    "0x6532f1cc72F34523aB815d2A7f2754afec17c8B4",
    StakeLPArtifactV6,
    { deployer }
  ); */

  StakeLPInstance = await upgradeProxy(
    StakeLPArtifactV6.address,
    StakeLPArtifactV7,
    { deployer }
  );

  console.log("StakeLP upgraded: ", StakeLPInstance.address);

  console.log("ALL DONE.");
}
