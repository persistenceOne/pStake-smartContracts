const STokensV2 = artifacts.require("STokensV2");
const STokens = artifacts.require("STokens");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var STokensV2Instance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeStakeLPCoreV2(
      gasPriceGanache,
      gasLimitGanache,
      deployer,
      accounts
    );
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7900000;
    await upgradeStakeLPCoreV2(
      gasPriceRopsten,
      gasLimitRopsten,
      deployer,
      accounts
    );
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeStakeLPCoreV2(
      gasPriceGoerli,
      gasLimitGoerli,
      deployer,
      accounts
    );
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await upgradeStakeLPCoreV2(
      gasPriceMainnet,
      gasLimitMainnet,
      deployer,
      accounts
    );
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

  let from_defaultAdmin = accounts[0];

  STokensV2Instance = await upgradeProxy(STokens.address, STokensV2, {
    deployer,
  });

  console.log("STokensV2 upgraded: ", STokensV2Instance.address);

  // set contract addresses in UTokens Contract
  /* const txReceipt = await STokensV2Instance.upgradeToV8({
    from: from_defaultAdmin,
    gasPrice: gasPrice,
    gas: gasLimit,
  });
  console.log("upgradeToV8() done"); */

  console.log("ALL DONE.");
}
