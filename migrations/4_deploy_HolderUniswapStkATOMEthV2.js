const HolderUniswapSTKATOMEthV2Artifact = artifacts.require(
  "HolderUniswapStkATOMEthV2"
);

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
var HolderUniswapInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await deployHolderUniswapV2(
      gasPriceGanache,
      gasLimitGanache,
      deployer,
      accounts
    );
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 6000000;
    await deployHolderUniswapV2(
      gasPriceRopsten,
      gasLimitRopsten,
      deployer,
      accounts
    );
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await deployHolderUniswapV2(
      gasPriceGoerli,
      gasLimitGoerli,
      deployer,
      accounts
    );
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await deployHolderUniswapV2(
      gasPriceMainnet,
      gasLimitMainnet,
      deployer,
      accounts
    );
  }
};

async function deployHolderUniswapV2(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside deployHolderUniswapV2(),",
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

  HolderUniswapInstance = await deployProxy(
    HolderUniswapSTKATOMEthV2Artifact,
    [sTokenContract, stakeLPContract],
    { deployer, initializer: "initialize" }
  );

  console.log(
    "HolderUniswapInstance V2 deployed: ",
    HolderUniswapInstance.address
  );

  console.log("ALL DONE.");
}
