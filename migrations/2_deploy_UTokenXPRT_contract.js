const UTokensXPRTArtifact = artifacts.require("UTokensXPRT");
let networkID;
const { deployProxy } = require("@openzeppelin/truffle-upgrades");
let UTokensXPRTInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    networkID = 5777;
    await deployUTokenXPRT(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 5000000;
    networkID = 3;
    await deployUTokenXPRT(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    networkID = 5;
    await deployUTokenXPRT(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 15e10;
    let gasLimitMainnet = 7000000;
    networkID = 1;
    await deployUTokenXPRT(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function deployUTokenXPRT(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside deployUTokenXPRT(),",
    " gasPrice: ",
    gasPrice,
    " gasLimit: ",
    gasLimit,
    " deployer: ",
    deployer.network,
    " accounts: ",
    accounts
  );

  // PSTAKE ATTRIBUTES
  let bridgeAdmin = "0x9b3DefB46804BD74518A52dC0cf4FA7280E0B673";
  let pauseAdmin = accounts[0];
  // token name and symbol
  let pTokenName = "Persistence Pegged XPRT";
  let pTokenSymbol = "pXPRT";


  UTokensXPRTInstance = await deployProxy(
    UTokensXPRTArtifact,
    [pTokenName, pTokenSymbol, bridgeAdmin, pauseAdmin],
    { deployer, initializer: "initialize" }
  );
  console.log("UTokensXPRT deployed: ", UTokensXPRTInstance.address);

  console.log("ALL DONE for UTokenXPRT contract");
}