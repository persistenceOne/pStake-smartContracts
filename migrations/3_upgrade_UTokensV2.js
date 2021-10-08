const UTokensArtifactV2 = artifacts.require("UTokensV2");
const UTokensArtifact = artifacts.require("UTokens");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var UTokensInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeUTokens(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await upgradeUTokens(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeUTokens(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await upgradeUTokens(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function upgradeUTokens(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeUTokens(),",
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

  UTokensInstance = await upgradeProxy(
    UTokensArtifact.address,
    UTokensArtifactV2,
    { deployer }
  );

  console.log("UTokens upgraded: ", UTokensInstance.address);

  // set contract addresses in UTokens Contract
  /*  const txReceipt = await UTokensInstance.setWhitelistedEmissionContract(
    WhitelistedEmissionArtifactV2.address,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setWhitelistedEmissionContract() done"); */

  console.log("ALL DONE.");
}
