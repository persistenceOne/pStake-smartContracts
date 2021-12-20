/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const UTokensXPRTArtifactV2 = artifacts.require("UTokensXPRTV2");
const UTokensXPRTArtifact = artifacts.require("UTokensXPRT");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var UTokensXPRTInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeUTokensXPRT(
      gasPriceGanache,
      gasLimitGanache,
      deployer,
      accounts
    );
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await upgradeUTokensXPRT(
      gasPriceRopsten,
      gasLimitRopsten,
      deployer,
      accounts
    );
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeUTokensXPRT(
      gasPriceGoerli,
      gasLimitGoerli,
      deployer,
      accounts
    );
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 7e10;
    let gasLimitMainnet = 4000000;
    await upgradeUTokensXPRT(
      gasPriceMainnet,
      gasLimitMainnet,
      deployer,
      accounts
    );
  }
};

async function upgradeUTokensXPRT(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeUTokensXPRT(),",
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

  UTokensXPRTInstance = await upgradeProxy(
    UTokensXPRTArtifact.address,
    UTokensXPRTArtifactV2,
    { deployer }
  );

  let pTokenName = "pSTAKE Pegged XPRT";

  console.log("UTokensXPRT upgraded: ", UTokensXPRTInstance.address);

  // set contract addresses in UTokensXPRT Contract
  const txReceipt = await UTokensXPRTInstance.upgradeVersionInitV2(pTokenName, {
    from: from_defaultAdmin,
    gasPrice: gasPrice,
    gas: gasLimit,
  });
  console.log("upgradeVersionInitV2() done");

  console.log("ALL DONE.");
}