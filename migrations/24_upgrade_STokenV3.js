const STokensArtifactV3 = artifacts.require("STokensV3");
const STokensArtifactV2 = artifacts.require("STokensV2");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var STokensInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeContract(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await upgradeContract(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeContract(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await upgradeContract(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function upgradeContract(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeContract(),",
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
    STokensArtifactV2.address,
    STokensArtifactV3,
    { deployer }
  );

  console.log("STokensV2 upgraded to STokensV3: ", STokensInstance.address);

  console.log("ALL DONE.");
}