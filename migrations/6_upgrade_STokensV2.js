/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const WhitelistedPTokenEmissionArtifact = artifacts.require("WhitelistedPTokenEmission");

const STokensArtifactV2 = artifacts.require("STokensV2");
const STokensArtifact = artifacts.require("STokens");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var STokensInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeSTokens(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await upgradeSTokens(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeSTokens(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 15e10;
    let gasLimitMainnet = 7000000;
    await upgradeSTokens(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function upgradeSTokens(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeSTokens(),",
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

  STokensInstance = await upgradeProxy(
    STokensArtifact.address,
    STokensArtifactV2,
    { deployer }
  );

  console.log("STokens upgraded: ", STokensInstance.address);

  // set contract addresses in STokens Contract
  const txReceipt = await STokensInstance.setWhitelistedPTokenEmissionContract(
    WhitelistedPTokenEmissionArtifact.address,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setWhitelistedPTokenEmissionContract() done");

  console.log("ALL DONE.");
}
