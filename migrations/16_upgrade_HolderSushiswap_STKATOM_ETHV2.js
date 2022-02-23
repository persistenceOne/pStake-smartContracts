/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const HolderSushiswap_STKATOM_ETHArtifactV2 = artifacts.require("HolderSushiswap_STKATOM_ETHV2");
const HolderSushiswap_STKATOM_ETHArtifact = artifacts.require("HolderSushiswap_STKATOM_ETH");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var HolderSushiswap_STKATOM_ETHInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeHolderSushiswap_STKATOM_ETH(
      gasPriceGanache,
      gasLimitGanache,
      deployer,
      accounts
    );
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await upgradeHolderSushiswap_STKATOM_ETH(
      gasPriceRopsten,
      gasLimitRopsten,
      deployer,
      accounts
    );
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeHolderSushiswap_STKATOM_ETH(
      gasPriceGoerli,
      gasLimitGoerli,
      deployer,
      accounts
    );
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 30e10;
    let gasLimitMainnet = 5000000;
    await upgradeHolderSushiswap_STKATOM_ETH(
      gasPriceMainnet,
      gasLimitMainnet,
      deployer,
      accounts
    );
  }
};

async function upgradeHolderSushiswap_STKATOM_ETH(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeHolderSushiswap_STKATOM_ETH(),",
    " gasPrice: ",
    gasPrice,
    " gasLimit: ",
    gasLimit,
    " deployer: ",
    deployer.network,
    " accounts: ",
    accounts
  );

  let HolderSushiswap_STKATOM_ETHAddress = "0x8ad5628DBf3740c0e30f412E5fF29C7C28f591cE"

  HolderSushiswap_STKATOM_ETHInstance = await upgradeProxy(
    HolderSushiswap_STKATOM_ETHAddress,
    HolderSushiswap_STKATOM_ETHArtifactV2,
    { deployer }
  );

  console.log("HolderSushiswap_STKATOM_ETH upgraded: ", HolderSushiswap_STKATOM_ETHInstance.address);

  console.log("ALL DONE.");
}
