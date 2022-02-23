/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const LiquidStakingXPRTArtifactV2 = artifacts.require("LiquidStakingXPRTV2");
const LiquidStakingXPRTArtifact = artifacts.require("LiquidStakingXPRT");
const TokenWrapperXPRTArtifactV2 = artifacts.require("TokenWrapperXPRTV2");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var LiquidStakingXPRTInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeLiquidStakingXPRT(
      gasPriceGanache,
      gasLimitGanache,
      deployer,
      accounts
    );
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await upgradeLiquidStakingXPRT(
      gasPriceRopsten,
      gasLimitRopsten,
      deployer,
      accounts
    );
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeLiquidStakingXPRT(
      gasPriceGoerli,
      gasLimitGoerli,
      deployer,
      accounts
    );
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 30e10;
    let gasLimitMainnet = 5000000;
    await upgradeLiquidStakingXPRT(
      gasPriceMainnet,
      gasLimitMainnet,
      deployer,
      accounts
    );
  }
};

async function upgradeLiquidStakingXPRT(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeLiquidStakingXPRT(),",
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
  let bridgeAdmin = "0x2E87d1c668C4bEF483A57927c7Ec4Fde852E3D8A"

  LiquidStakingXPRTInstance = await upgradeProxy(
    LiquidStakingXPRTArtifact.address,
    LiquidStakingXPRTArtifactV2,
    { deployer }
  );

  console.log("LiquidStakingXPRT upgraded: ", LiquidStakingXPRTInstance.address);

  // set contract addresses in LiquidStaking Contract
  const txReceipt = await LiquidStakingXPRTInstance.setTokenWrapperContract(
    TokenWrapperXPRTArtifactV2.address,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setTokenWrapperContract() done");

  const txReceiptGrantRole1 =
    await LiquidStakingXPRTInstance.grantRole(
      "0x751b795d24b92e3d92d1d0d8f2885f4e9c9c269da350af36ae6b49069babf4bf", bridgeAdmin,
      {
        from: from_defaultAdmin,
        gasPrice: gasPrice,
        gas: gasLimit,
      });
  console.log("grantRole() set for bridge admin in Liquid Staking contract.");

  console.log("ALL DONE.");
}