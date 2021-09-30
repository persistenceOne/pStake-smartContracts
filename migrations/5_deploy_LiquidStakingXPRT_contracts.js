const LiquidStakingXPRTArtifact = artifacts.require("LiquidStakingXPRT");
const TokenWrapperXPRTArtifact = artifacts.require("TokenWrapperXPRT");
const STokensXPRTArtifact = artifacts.require("STokensXPRT");
const UTokensXPRTArtifact = artifacts.require("UTokensXPRT");

var networkID;

const { BN } = web3.utils.BN;
const { deployProxy } = require("@openzeppelin/truffle-upgrades");
var UTokensXPRTInstance,
  STokensXPRTInstance,
  TokenWrapperXPRTInstance,
  LiquidStakingXPRTInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    networkID = 5777;
    await deployLiquidStakingXPRT(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 5000000;
    networkID = 3;
    await deployLiquidStakingXPRT(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    networkID = 5;
    await deployLiquidStakingXPRT(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 75e9;
    let gasLimitMainnet = 4000000;
    networkID = 1;
    await deployLiquidStakingXPRT(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function deployLiquidStakingXPRT(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside deployLiquidStakingXPRT(),",
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
  let pauseAdmin = accounts[0];
  let from_defaultAdmin = accounts[0];
  let rewardDivisor = new BN("1000000000");
  let epochInterval = "259200"; //3 days
  let unstakingLockTime = "1814400"; // 21 days
  let batchingLimit = 20;

  UTokensXPRTInstance = await UTokensXPRTArtifact.deployed();
  console.log("UTokensXPRT address: ", UTokensXPRTInstance.address);

  STokensXPRTInstance = await STokensXPRTArtifact.deployed();
  console.log("STokensXPRT address: ", STokensXPRTInstance.address);

  TokenWrapperXPRTInstance = await TokenWrapperXPRTArtifact.deployed();
  console.log("TokenWrapperXPRT address: ", TokenWrapperXPRTInstance.address);

  LiquidStakingXPRTInstance = await deployProxy(
    LiquidStakingXPRTArtifact,
    [
      UTokensXPRTInstance.address,
      STokensXPRTInstance.address,
      pauseAdmin,
      unstakingLockTime,
      epochInterval,
      rewardDivisor,
    ],
    { deployer, initializer: "initialize" }
  );
  console.log(
    "LiquidStakingXPRT deployed: ",
    LiquidStakingXPRTInstance.address
  );

  const txReceiptSetLiquidStakingXPRTContract =
    await UTokensXPRTInstance.setLiquidStakingContract(
      LiquidStakingXPRTInstance.address,
      {
        from: from_defaultAdmin,
        gasPrice: gasPrice,
        gas: gasLimit,
      }
    );
  console.log("setLiquidStakingXPRTContract() set for UTokensXPRT contract.");

  const txReceiptSetLiquidStakingXPRTContract2 =
    await STokensXPRTInstance.setLiquidStakingContract(
      LiquidStakingXPRTInstance.address,
      {
        from: from_defaultAdmin,
        gasPrice: gasPrice,
        gas: gasLimit,
      }
    );
  console.log("setLiquidStakingXPRTContract() set for STokensXPRT contract.");

  // set contract addresses in LiquidStaking Contract
  const txReceipt = await LiquidStakingXPRTInstance.setBatchingLimit(
    batchingLimit,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setBatchingLimit() set for LiquidStaking contract");

  console.log("ALL DONE for LiquidStakingXPRT contract");
}