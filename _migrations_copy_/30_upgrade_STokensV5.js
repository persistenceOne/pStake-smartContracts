const STokensArtifactV5 = artifacts.require("STokensV5");
const STokensArtifactV4 = artifacts.require("STokensV4");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var STokensInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeSTokens(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await upgradeSTokens(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeSTokens(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await upgradeSTokens(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function upgradeSTokens(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeSTokens(),",
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

  STokensInstance = await upgradeProxy(
    STokensArtifactV4.address,
    STokensArtifactV5,
    { deployer }
  );

  console.log("STokensV4 upgraded to STokensV5: ", STokensInstance.address);

  // set contract addresses in UTokens Contract
  /* const txReceipt = await STokensInstance.setBatchingLimit(20, {
    from: from_defaultAdmin,
    gasPrice: gasPrice,
    gas: gasLimit,
  });
  console.log("setBatchingLimit() done"); */

  console.log("ALL DONE.");
}
