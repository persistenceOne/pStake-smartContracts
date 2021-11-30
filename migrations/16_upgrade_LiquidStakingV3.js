const LiquidStakingArtifactV3 = artifacts.require("LiquidStakingV3");
const LiquidStakingArtifactV2 = artifacts.require("LiquidStakingV2");
const TokenWrapperArtifactV3 = artifacts.require("TokenWrapperV3");

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
    let gasPriceMainnet = 15e10;
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

  LiquidStakingInstance = await upgradeProxy(
    LiquidStakingArtifactV2.address,
    LiquidStakingArtifactV3,
    { deployer }
  );

  console.log("LiquidStakingV3 upgraded: ", LiquidStakingInstance.address);

  // set contract addresses in LiquidStaking Contract
  const txReceipt = await LiquidStakingInstance.setTokenWrapperContract(
    TokenWrapperArtifactV3.address,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setTokenWrapperContract() done");

  console.log("ALL DONE.");
}
