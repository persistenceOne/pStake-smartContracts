const HolderSushiswapStkATOMEthV2Artifact = artifacts.require(
  "HolderSushiswapStkATOMEthV2"
);
//const STokensV2Artifact2 = artifacts.require("STokensV2");
//const StakeLPCoreV8Artifact2 = artifacts.require("StakeLPCoreV8");

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
var HolderSushiswapInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await deployHolderSushiswapV2(
      gasPriceGanache,
      gasLimitGanache,
      deployer,
      accounts
    );
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await deployHolderSushiswapV2(
      gasPriceRopsten,
      gasLimitRopsten,
      deployer,
      accounts
    );
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await deployHolderSushiswapV2(
      gasPriceGoerli,
      gasLimitGoerli,
      deployer,
      accounts
    );
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await deployHolderSushiswapV2(
      gasPriceMainnet,
      gasLimitMainnet,
      deployer,
      accounts
    );
  }
};

async function deployHolderSushiswapV2(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside deployHolderSushiswapV2(),",
    " gasPrice: ",
    gasPrice,
    " gasLimit: ",
    gasLimit,
    " deployer: ",
    deployer.network,
    " accounts: ",
    accounts
  );

  const sTokenContract = "0x2f9104E4acd67A7105E953aFb7a546dA6Ea0f64C";
  const stakeLPContract = "0x6532f1cc72F34523aB815d2A7f2754afec17c8B4";

  HolderSushiswapInstance = await deployProxy(
    HolderSushiswapStkATOMEthV2Artifact,
    [sTokenContract, stakeLPContract],
    { deployer, initializer: "initialize" }
  );

  console.log(
    "HolderSushiswapInstance deployed: ",
    HolderSushiswapInstance.address
  );

  console.log("ALL DONE.");
}
