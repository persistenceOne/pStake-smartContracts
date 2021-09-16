const StakeLPArtifactV12 = artifacts.require("StakeLPCoreV12");
const StakeLPArtifactV11 = artifacts.require("StakeLPCoreV11");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var StakeLPInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeStakeLPCore(
      gasPriceGanache,
      gasLimitGanache,
      deployer,
      accounts
    );
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await upgradeStakeLPCore(
      gasPriceRopsten,
      gasLimitRopsten,
      deployer,
      accounts
    );
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeStakeLPCore(
      gasPriceGoerli,
      gasLimitGoerli,
      deployer,
      accounts
    );
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await upgradeStakeLPCore(
      gasPriceMainnet,
      gasLimitMainnet,
      deployer,
      accounts
    );
  }
};

async function upgradeStakeLPCore(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeStakeLPCore(),",
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

  StakeLPInstance = await upgradeProxy(
    StakeLPArtifactV11.address,
    StakeLPArtifactV12,
    { deployer }
  );

  console.log("StakeLP upgraded: ", StakeLPInstance.address);

  /*  // set contract addresses in UTokens Contract
  const txReceipt = await StakeLPInstance.upgradeToV8({
    from: from_defaultAdmin,
    gasPrice: gasPrice,
    gas: gasLimit,
  });
  console.log("upgradeToV8() done"); */

  console.log("ALL DONE.");
}
