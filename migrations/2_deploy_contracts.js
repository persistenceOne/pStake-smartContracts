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

// STEP1: copy contracts and create four new contracts, rename the contract names to respective token eg. LiquidStakingXPRT.sol
// a. command for compilation of SCs: npx truffle compile
// b. Test in Ganache: command to deploy ganache is..
// ganache-cli -m "baby year rocket october what surprise lab bag report swap game unveil" -p 8545 -b 10 -l 8000000 –callGasLimit “0x61a80” –-networkId 5777 –-chainId 5777

// STEP2: in 2_deploy_contracts.js, input the PSTAKE ATTRIBUTES
// a. command for migration to ganache (development): npx truffle migrate
// b. command for migration to ropsten (testnet): npx truffle migrate --network ropsten

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    networkID = 5777;
    await deployAll(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 5000000;
    networkID = 3;
    await deployAll(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    networkID = 5;
    await deployAll(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 15e10;
    let gasLimitMainnet = 7000000;
    networkID = 1;
    await deployAll(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function deployAll(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside deployAll(),",
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
  //let defaultAdmin = "0x714d4CaF73a0F5dE755488D14f82e74232DAF5B7";
  let bridgeAdmin = "0x9b3DefB46804BD74518A52dC0cf4FA7280E0B673";
  let pauseAdmin = accounts[0];
  let from_defaultAdmin = accounts[0];
  let rewardRate = new BN(1046); // 1046 * 10^-9% per second equivalent to 33% apr
  let rewardDivisor = new BN("1000000000");
  let epochInterval = "259200"; //3 days
  let unstakingLockTime = "1814400"; // 21 days
  // token name and symbol
  let pTokenName = "Persistence Pegged XPRT";
  let stkTokenName = "Persistence Staked XPRT";
  let pTokenSymbol = "pXPRT";
  let stkTokenSymbol = "stkXPRT";
  // bech 32 validation attributes
  let hrpString = "persistence";
  let controlDigitString = "1";
  let dataSize = 38;
  let WhitelistedPTokenEmissionAddress = "0x3EA53661B56DC93DfaC6A1a7E0895F2460B49Be7"

  UTokensXPRTInstance = await deployProxy(
    UTokensXPRTArtifact,
    [pTokenName, pTokenSymbol, bridgeAdmin, pauseAdmin],
    { deployer, initializer: "initialize" }
  );
  console.log("UTokensXPRT deployed: ", UTokensXPRTInstance.address);

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

  TokenWrapperXPRTInstance = await deployProxy(
    TokenWrapperXPRTArtifact,
    [
      UTokensXPRTInstance.address,
      bridgeAdmin,
      pauseAdmin,
      rewardDivisor,
      hrpString,
      controlDigitString,
      dataSize,
    ],
    { deployer, initializer: "initialize" }
  );
  console.log("TokenWrapperXPRT deployed: ", TokenWrapperXPRTInstance.address);

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

  // set contract addresses in UTokensXPRT Contract
  const txReceiptSetSTokenContract =
    await UTokensXPRTInstance.setSTokenContract(STokensXPRTInstance.address, {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    });
  console.log("setSTokenContract() set for UTokensXPRT contract.");

  const txReceiptSetWrapperContract =
    await UTokensXPRTInstance.setWrapperContract(
      TokenWrapperXPRTInstance.address,
      {
        from: from_defaultAdmin,
        gasPrice: gasPrice,
        gas: gasLimit,
      }
    );
  console.log("setWrapperContract() set for UTokensXPRT contract. ");

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

  //set min value for wrap
  const txReceiptSetMinval = await TokenWrapperXPRTInstance.setMinimumValues(
    "5000000",
    "1",
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setMinimumValues() set for Token Wrapper contract.");

  console.log("ALL DONE.");
}