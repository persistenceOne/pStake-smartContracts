/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const TokenWrapperXPRTArtifactV2 = artifacts.require("TokenWrapperXPRTV2");
const TokenWrapperXPRTArtifact = artifacts.require("TokenWrapperXPRT");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var TokenWrapperXPRTInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeTokenWrapperXPRT(
      gasPriceGanache,
      gasLimitGanache,
      deployer,
      accounts
    );
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await upgradeTokenWrapperXPRT(
      gasPriceRopsten,
      gasLimitRopsten,
      deployer,
      accounts
    );
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeTokenWrapperXPRT(
      gasPriceGoerli,
      gasLimitGoerli,
      deployer,
      accounts
    );
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 7e10;
    let gasLimitMainnet = 4000000;
    await upgradeTokenWrapperXPRT(
      gasPriceMainnet,
      gasLimitMainnet,
      deployer,
      accounts
    );
  }
};

async function upgradeTokenWrapperXPRT(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeTokenWrapperXPRT(),",
    " gasPrice: ",
    gasPrice,
    " gasLimit: ",
    gasLimit,
    " deployer: ",
    deployer.network,
    " accounts: ",
    accounts
  );

  TokenWrapperXPRTInstance = await upgradeProxy(
    TokenWrapperXPRTArtifact.address,
    TokenWrapperXPRTArtifactV2,
    { deployer }
  );

  console.log("TokenWrapperXPRT upgraded: ", TokenWrapperXPRTInstance.address);

  console.log("ALL DONE.");
}