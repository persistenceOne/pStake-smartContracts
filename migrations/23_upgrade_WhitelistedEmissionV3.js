const WhitelistedEmissionArtifactV3 = artifacts.require("WhitelistedEmissionV3");
const WhitelistedEmissionArtifactV2 = artifacts.require("WhitelistedEmissionV2");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var WhitelistedEmissionInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await WhitelistedEmission(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await WhitelistedEmission(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await WhitelistedEmission(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await WhitelistedEmission(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function WhitelistedEmission(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside WhitelistedEmission(),",
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

  WhitelistedEmissionInstance = await upgradeProxy(
    WhitelistedEmissionArtifactV2.address,
    WhitelistedEmissionArtifactV3,
    { deployer }
  );

  console.log("WhitelistedEmission upgraded to WhitelistedEmissionV3: ", WhitelistedEmissionInstance.address);

  // set contract addresses in WhitelistedEmission Contract
  /*  const txReceipt = await WhitelistedEmissionInstance.setBatchingLimit(
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
