const LiquidStakingArtifactV3 = artifacts.require("LiquidStakingV3");
const LiquidStakingArtifactV2 = artifacts.require("LiquidStakingV2");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var LiquidStakingInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeLiquidStaking(
      gasPriceGanache,
      gasLimitGanache,
      deployer,
      accounts
    );
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await upgradeLiquidStaking(
      gasPriceRopsten,
      gasLimitRopsten,
      deployer,
      accounts
    );
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeLiquidStaking(
      gasPriceGoerli,
      gasLimitGoerli,
      deployer,
      accounts
    );
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await upgradeLiquidStaking(
      gasPriceMainnet,
      gasLimitMainnet,
      deployer,
      accounts
    );
  }
};

async function upgradeLiquidStaking(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeLiquidStaking(),",
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

  LiquidStakingInstance = await upgradeProxy(
    LiquidStakingArtifactV2.address,
    LiquidStakingArtifactV3,
    { deployer }
  );

  console.log(
    "LiquidStakingV2 upgraded to LiquidStakingV3: ",
    LiquidStakingInstance.address
  );

  // set contract addresses in UTokens Contract
  const txReceipt = await LiquidStakingInstance.setBatchingLimit(20, {
    from: from_defaultAdmin,
    gasPrice: gasPrice,
    gas: gasLimit,
  });
  console.log("setBatchingLimit() done");

  console.log("ALL DONE.");
}
