/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const TokenWrapperXPRTArtifact = artifacts.require("TokenWrapperXPRT");
const STokensXPRTArtifact = artifacts.require("STokensXPRT");
const UTokensXPRTArtifact = artifacts.require("UTokensXPRT");

let networkID;

const { BN } = web3.utils.BN;
const { deployProxy } = require("@openzeppelin/truffle-upgrades");
let UTokensXPRTInstance,
  STokensXPRTInstance,
  TokenWrapperXPRTInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    networkID = 5777;
    await deployTokenWrapperXPRT(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 5000000;
    networkID = 3;
    await deployTokenWrapperXPRT(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    networkID = 5;
    await deployTokenWrapperXPRT(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 75e9;
    let gasLimitMainnet = 4000000;
    networkID = 1;
    await deployTokenWrapperXPRT(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function deployTokenWrapperXPRT(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside deployTokenWrapperXPRT(),",
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
  let bridgeAdmin = "";
  let pauseAdmin = accounts[0];
  let from_defaultAdmin = accounts[0];
  let rewardDivisor = new BN("1000000000");
  // bech 32 validation attributes
  let hrpString = "persistence";
  let controlDigitString = "1";
  let dataSize = 38;

  UTokensXPRTInstance = await UTokensXPRTArtifact.deployed();
  console.log("UTokensXPRT address: ", UTokensXPRTInstance.address);

  STokensXPRTInstance = await STokensXPRTArtifact.deployed();
  console.log("STokensXPRT address: ", STokensXPRTInstance.address);

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
  console.log("setMinimumValues() set for TokenWrapperXPRT contract.");

  console.log("ALL DONE for TokenWrapperXPRT contract");
}