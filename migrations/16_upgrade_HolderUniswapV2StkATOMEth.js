const HolderUniswapV2StkATOMEth = artifacts.require(
  "HolderUniswapV2StkATOMEth"
);
const HolderUniswap = artifacts.require("HolderUniswap");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var HolderUniswapV2StkATOMEthInstance;

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

  HolderUniswapV2StkATOMEthInstance = await upgradeProxy(
    HolderUniswap.address,
    HolderUniswapV2StkATOMEth,
    {
      deployer,
    }
  );

  console.log(
    "HolderUniswapV2StkATOMEth upgraded: ",
    HolderUniswapV2StkATOMEthInstance.address
  );

  // set contract addresses in HolderUniswap Contract
  /* const txReceipt = await HolderUniswapV2StkATOMEthInstance.upgradeToV8({
    from: from_defaultAdmin,
    gasPrice: gasPrice,
    gas: gasLimit,
  });
  console.log("upgradeToV8() done"); */

  console.log("ALL DONE.");
}