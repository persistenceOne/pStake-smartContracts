const STokensXPRTArtifact = artifacts.require("STokensXPRT");
const UTokensXPRTArtifact = artifacts.require("UTokensXPRT");

let networkID;

const { BN } = web3.utils.BN;
const { deployProxy } = require("@openzeppelin/truffle-upgrades");
let UTokensXPRTInstance,
  STokensXPRTInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    networkID = 5777;
    await deploySTokenXPRT(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 5000000;
    networkID = 3;
    await deploySTokenXPRT(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    networkID = 5;
    await deploySTokenXPRT(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 15e10;
    let gasLimitMainnet = 7000000;
    networkID = 1;
    await deploySTokenXPRT(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function deploySTokenXPRT(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside deploySTokenXPRT(),",
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
  let rewardRate = new BN(1046); // 1046 * 10^-9% per second equivalent to 33% apr
  let rewardDivisor = new BN("1000000000");

  // token name and symbol
  let stkTokenName = "Persistence Staked XPRT";
  let stkTokenSymbol = "stkXPRT";
  let WhitelistedPTokenEmissionAddress = "0x3EA53661B56DC93DfaC6A1a7E0895F2460B49Be7"

  UTokensXPRTInstance = await UTokensXPRTArtifact.deployed();
  console.log("UTokensXPRT address: ", UTokensXPRTInstance.address);

  STokensXPRTInstance = await deployProxy(
    STokensXPRTArtifact,
    [
      stkTokenName,
      stkTokenSymbol,
      UTokensXPRTInstance.address,
      pauseAdmin,
      rewardRate,
      rewardDivisor,
    ],
    { deployer, initializer: "initialize" }
  );
  console.log("STokensXPRT deployed: ", STokensXPRTInstance.address);

  // set contract addresses in UTokensXPRT Contract
  const txReceiptSetSTokenContract =
    await UTokensXPRTInstance.setSTokenContract(STokensXPRTInstance.address, {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    });
  console.log("setSTokenContract() set for UTokensXPRT contract.");

  // set contract addresses in STokens Contract
  const txReceiptSetWhitelistedPTokenEmissionContract = await STokensXPRTInstance.setWhitelistedPTokenEmissionContract(
    WhitelistedPTokenEmissionAddress,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setWhitelistedPTokenEmissionContract() set for STokensXPRT contract");

  console.log("ALL DONE for STokenXPRT contract");
}