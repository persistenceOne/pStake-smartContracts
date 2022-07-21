/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const TokenWrapperArtifactV4 = artifacts.require("TokenWrapperV4");
const TokenWrapperArtifactV3 = artifacts.require("TokenWrapperV3");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var TokenWrapperInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeTokenWrapper(
      gasPriceGanache,
      gasLimitGanache,
      deployer,
      accounts
    );
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 3e10;
    let gasLimitRopsten = 7000000;
    await upgradeTokenWrapper(
      gasPriceRopsten,
      gasLimitRopsten,
      deployer,
      accounts
    );
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeTokenWrapper(
      gasPriceGoerli,
      gasLimitGoerli,
      deployer,
      accounts
    );
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await upgradeTokenWrapper(
      gasPriceMainnet,
      gasLimitMainnet,
      deployer,
      accounts
    );
  }
};

async function upgradeTokenWrapper(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeTokenWrapper(),",
    " gasPrice: ",
    gasPrice,
    " gasLimit: ",
    gasLimit,
    " deployer: ",
    deployer.network,
    " accounts: ",
    accounts
  );

  TokenWrapperInstance = await upgradeProxy(
    TokenWrapperArtifactV3.address,
    TokenWrapperArtifactV4,
    { deployer }
  );

  console.log("TokenWrapperV4 upgraded: ", TokenWrapperInstance.address);

  console.log("ALL DONE.");
}
