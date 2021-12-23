/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const LiquidStakingArtifact = artifacts.require("LiquidStaking");
const TokenWrapperArtifact = artifacts.require("TokenWrapper");
const STokensArtifact = artifacts.require("STokens");
const UTokensArtifact = artifacts.require("UTokens");

const { BN } = web3.utils.BN;
const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var UTokensInstance,
  STokensInstance,
  TokenWrapperInstance,
 LiquidStakingInstance;

//deploy ATOMs contracts
module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await deployAll(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 4000000;
    await deployAll(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await deployAll(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

    if (network === "mainnet") {
        let gasPriceMainnet = 5e10;
        let gasLimitMainnet = 7000000;
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
  let bridgeAdmin = "";
  let pauseAdmin = accounts[0];
  let from_defaultAdmin = accounts[0]
  let rewardRate = new BN(222) // 222 * 10^-5
  let rewardDivisor = new BN("1000000000")
  let epochInterval = "259200" //3 days
    let unstakingLockTime = "1814400" // 21 days

  console.log(bridgeAdmin, "bridgeAdmin")

  UTokensInstance = await deployProxy(
    UTokensArtifact,
    [bridgeAdmin, pauseAdmin],
    { deployer, initializer: "initialize" }
  );
  console.log("UTokens deployed: ", UTokensInstance.address);

  STokensInstance = await deployProxy(
    STokensArtifact,
    [UTokensInstance.address, pauseAdmin, rewardRate, rewardDivisor],
    { deployer, initializer: "initialize" }
  );
  console.log("STokens deployed: ", STokensInstance.address);

    TokenWrapperInstance = await deployProxy(
    TokenWrapperArtifact,
    [UTokensInstance.address, bridgeAdmin, pauseAdmin, rewardDivisor],
    { deployer, initializer: "initialize" }
  );
  console.log("TokenWrapper deployed: ", TokenWrapperInstance.address);

  LiquidStakingInstance = await deployProxy(
    LiquidStakingArtifact,
    [
      UTokensInstance.address,
      STokensInstance.address,
      pauseAdmin,
        unstakingLockTime,
        epochInterval,
        rewardDivisor,
    ],
    { deployer, initializer: "initialize" }
  );
  console.log("LiquidStaking deployed: ", LiquidStakingInstance.address);

  // set contract addresses in UTokens Contract
  const txReceiptSetSTokenContract = await UTokensInstance.setSTokenContract(
    STokensInstance.address,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setSTokenContract() set for UTokens contract.");

  const txReceiptSetWrapperContract = await UTokensInstance.setWrapperContract(
    TokenWrapperInstance.address,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setWrapperContract() set for UTokens contract. ");

  const txReceiptSetLiquidStakingContract = await UTokensInstance.setLiquidStakingContract(
    LiquidStakingInstance.address,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setLiquidStakingContract() set for UTokens contract.");

  const txReceiptSetLiquidStakingContract2 = await STokensInstance.setLiquidStakingContract(
    LiquidStakingInstance.address,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
    console.log("setLiquidStakingContract() set for STokens contract.");

    //set min value for wrap
    const txReceiptSetMinval = await TokenWrapperInstance.setMinimumValues(
        "5000000","1",
        {
            from: from_defaultAdmin,
            gasPrice: gasPrice,
            gas: gasLimit,
        }
    );
    console.log("setMinimumValues() set for Token Wrapper contract.");

  console.log("ALL DONE.");
}


