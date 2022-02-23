/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const HolderSushiswap_STKXPRT_ETHArtifactV2 = artifacts.require("HolderSushiswap_STKXPRT_ETHV2");
const HolderSushiswap_STKXPRT_ETHArtifact = artifacts.require("HolderSushiswap_STKXPRT_ETH");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var HolderSushiswap_STKXPRT_ETHInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeHolderSushiswap_STKXPRT_ETH(
      gasPriceGanache,
      gasLimitGanache,
      deployer,
      accounts
    );
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await upgradeHolderSushiswap_STKXPRT_ETH(
      gasPriceRopsten,
      gasLimitRopsten,
      deployer,
      accounts
    );
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeHolderSushiswap_STKXPRT_ETH(
      gasPriceGoerli,
      gasLimitGoerli,
      deployer,
      accounts
    );
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await upgradeHolderSushiswap_STKXPRT_ETH(
      gasPriceMainnet,
      gasLimitMainnet,
      deployer,
      accounts
    );
  }
};

async function upgradeHolderSushiswap_STKXPRT_ETH(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeHolderSushiswap_STKXPRT_ETH(),",
    " gasPrice: ",
    gasPrice,
    " gasLimit: ",
    gasLimit,
    " deployer: ",
    deployer.network,
    " accounts: ",
    accounts
  );

  HolderSushiswap_STKXPRT_ETHInstance = await upgradeProxy(
    HolderSushiswap_STKXPRT_ETHArtifact.address,
    HolderSushiswap_STKXPRT_ETHArtifactV2,
    { deployer }
  );

  console.log("HolderSushiswap_STKXPRT_ETH upgraded: ", HolderSushiswap_STKXPRT_ETHInstance.address);

  console.log("ALL DONE.");
}