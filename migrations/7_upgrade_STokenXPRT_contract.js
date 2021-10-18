const STokensXPRTArtifactV2 = artifacts.require("STokensXPRTV2");
const STokensXPRTArtifact = artifacts.require("STokensXPRT");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var STokensXPRTInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeSTokensXPRT(
      gasPriceGanache,
      gasLimitGanache,
      deployer,
      accounts
    );
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await upgradeSTokensXPRT(
      gasPriceRopsten,
      gasLimitRopsten,
      deployer,
      accounts
    );
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeSTokensXPRT(
      gasPriceGoerli,
      gasLimitGoerli,
      deployer,
      accounts
    );
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await upgradeSTokensXPRT(
      gasPriceMainnet,
      gasLimitMainnet,
      deployer,
      accounts
    );
  }
};

async function upgradeSTokensXPRT(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeSTokensXPRT(),",
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

  STokensXPRTInstance = await upgradeProxy(
    STokensXPRTArtifact.address,
    STokensXPRTArtifactV2,
    { deployer }
  );

  let pTokenName = "pSTAKE Staked XPRT";

  console.log("STokensXPRT upgraded: ", STokensXPRTInstance.address);

  // set contract addresses in STokensXPRT Contract
  const txReceipt = await STokensXPRTInstance.upgradeVersionInitV2(pTokenName, {
    from: from_defaultAdmin,
    gasPrice: gasPrice,
    gas: gasLimit,
  });
  console.log("upgradeVersionInitV2() done");

  console.log("ALL DONE.");
}
