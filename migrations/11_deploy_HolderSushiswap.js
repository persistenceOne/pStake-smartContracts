/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const WhitelistedRewardEmissionArtifact = artifacts.require("WhitelistedRewardEmission");
const StakeLPCoreArtifact = artifacts.require("StakeLP");

const HolderSushiswapStkATOMEthArtifact = artifacts.require(
  "HolderSushiswap_STKATOM_ETH"
);
var networkID;

// const { BN } = web3.utils.BN;
const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const { BN } = web3.utils.BN;
var HolderSushiswapStkATOMEthInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    networkID = 5777;
    await deployContract(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 5000000;
    networkID = 3;
    await deployContract(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    networkID = 5;
    await deployContract(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 15e10;
    let gasLimitMainnet = 7000000;
    networkID = 1;
    await deployContract(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function deployContract(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside deployContract(),",
    " gasPrice: ",
    gasPrice,
    " gasLimit: ",
    gasLimit,
    " deployer: ",
    deployer.network,
    " accounts: ",
    accounts
  );
  // init parameters
  let pauseAdmin = accounts[0];
  let from_defaultAdmin = accounts[0];
  let valueDivisor = new BN("1000000000");

  // let WhitelistedDivisor = new BN("1000000000");

  HolderSushiswapStkATOMEthInstance = await deployProxy(
    HolderSushiswapStkATOMEthArtifact,
    [pauseAdmin, from_defaultAdmin, valueDivisor],
    { deployer, initializer: "initialize" }
  );
  console.log(
    "HolderSushiswapStkATOMEth deployed: ",
    HolderSushiswapStkATOMEthInstance.address
  );

  const txReceiptGrantRole1 =
    await HolderSushiswapStkATOMEthInstance.grantRole(
      "0x369da55721ba2b3acddd63aac7d6512c3e5762a78fa01c44f423f97868330c34", StakeLPCoreArtifact.address,
      {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    });
  console.log("grantRole() set for HolderSushiswapStkATOMEth contract.");

  const txReceiptGrantRole2 =
    await HolderSushiswapStkATOMEthInstance.grantRole(
      "0x369da55721ba2b3acddd63aac7d6512c3e5762a78fa01c44f423f97868330c34", WhitelistedRewardEmissionArtifact.address,
      {
        from: from_defaultAdmin,
        gasPrice: gasPrice,
        gas: gasLimit,
      });
  console.log("grantRole() set for HolderSushiswapStkATOMEth contract");

  // set contract addresses in UTokens Contract
  /* const txReceiptSetHolderSushiswapStkATOMEthContract =
    await PstakeInstance.setHolderSushiswapStkATOMEthContract(StakeLPInstance.address, {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    });
  console.log("setHolderSushiswapStkATOMEthContract() set for StakeLP contract."); */

  console.log("ALL DONE.");
}
