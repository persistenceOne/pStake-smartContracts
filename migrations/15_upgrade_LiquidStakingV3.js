/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const LiquidStakingArtifactV3 = artifacts.require("LiquidStakingV3");
const LiquidStakingArtifactV2 = artifacts.require("LiquidStakingV2");
const TokenWrapperArtifactV3 = artifacts.require("TokenWrapperV3");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var LiquidStakingInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await LiquidStaking(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await LiquidStaking(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await LiquidStaking(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 30e10;
    let gasLimitMainnet = 5000000;
    await LiquidStaking(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function LiquidStaking(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside LiquidStaking(),",
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
  let bridgeAdmin = "0xBbC32cFe20765120b33EC17b301E18D3e03FE543"
  let tokenWrapperV2Address =  "0xA9739b5BdAfe956DEAa8b2e695c7d4f1DF7Bc1D6";
  let liquidStakingV2Address =  "0xce3f57A8De9AA69da3289871b5FeE5E77fFCF480";

  LiquidStakingInstance = await upgradeProxy(
    liquidStakingV2Address,
    LiquidStakingArtifactV3,
    { deployer }
  );

  console.log("LiquidStaking upgraded: ", LiquidStakingInstance.address);

  // set contract addresses in LiquidStaking Contract
  const txReceipt = await LiquidStakingInstance.setTokenWrapperContract(
    tokenWrapperV2Address,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setTokenWrapperContract() done");

  const txReceiptGrantRole1 =
    await LiquidStakingInstance.grantRole(
      "0x751b795d24b92e3d92d1d0d8f2885f4e9c9c269da350af36ae6b49069babf4bf", bridgeAdmin,
      {
        from: from_defaultAdmin,
        gasPrice: gasPrice,
        gas: gasLimit,
      });
  console.log("grantRole() set for bridge admin in Liquid Staking contract.");

  console.log("ALL DONE.");
}
