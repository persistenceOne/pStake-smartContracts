/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const WhitelistedRewardEmissionArtifact = artifacts.require("WhitelistedRewardEmission");
const WhitelistedRewardEmissionV2Artifact = artifacts.require("WhitelistedRewardEmissionV2");
var networkID;

const { BN } = web3.utils.BN;
const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
let WhitelistedRewardEmissionInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    networkID = 5777;
    await upgradeContract(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 5000000;
    networkID = 3;
    await upgradeContract(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    networkID = 5;
    await upgradeContract(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    networkID = 1;
    await upgradeContract(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function upgradeContract(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeContract(),",
    " gasPrice: ",
    gasPrice,
    " gasLimit: ",
    gasLimit,
    " deployer: ",
    deployer.network,
    " accounts: ",
    accounts
  );

  WhitelistedRewardEmissionInstance = await upgradeProxy(
    WhitelistedRewardEmissionArtifact.address,
    WhitelistedRewardEmissionV2Artifact,
    { deployer }
  );

  console.log("WhitelistedRewardEmission upgraded: ", WhitelistedRewardEmissionInstance.address);

  console.log("ALL DONE.");
}
