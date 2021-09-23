const STokensArtifactV3 = artifacts.require("STokensV3");
const STokensArtifactV2 = artifacts.require("STokensV2");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var STokensInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await STokens(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await STokens(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await STokens(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await STokens(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function STokens(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside STokens(),",
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

  STokensInstance = await upgradeProxy(
    STokensArtifactV2.address,
    STokensArtifactV3,
    { deployer }
  );

  console.log("STokens upgraded to STokensV3: ", STokensInstance.address);

  // set contract addresses in STokens Contract
  /*  const txReceipt = await STokensInstance.setBatchingLimit(
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
