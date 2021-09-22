const LiquidStakingArtifactV2 = artifacts.require("LiquidStakingV2");
const LiquidStakingArtifact = artifacts.require("LiquidStaking");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var LiquidStakingInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await LiquidStaking(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await LiquidStaking(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await LiquidStaking(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await LiquidStaking(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function LiquidStaking(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside LiquidStaking(),",
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

  LiquidStakingInstance = await upgradeProxy(
    LiquidStakingArtifact.address,
    LiquidStakingArtifactV2,
    { deployer }
  );

  console.log("LiquidStaking upgraded: ", LiquidStakingInstance.address);

  // set contract addresses in LiquidStaking Contract
  const txReceipt = await LiquidStakingInstance.setBatchingLimit(
    batchingLimit,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setBatchingLimit() done");

  console.log("ALL DONE.");
}
