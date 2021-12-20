/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const HolderSushiswapStkXPRTEthArtifact = artifacts.require(
  "HolderSushiswap_STKXPRT_ETH"
);
var networkID;

// const { BN } = web3.utils.BN;
const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const { BN } = web3.utils.BN;
var HolderSushiswapStkXPRTEthInstance;

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
    let gasPriceMainnet = 1e11;
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

  let StakeLPAddress = "0xA1cF35f35031c0f2a27283793bE23a22fd615F58";
  let WhitelistedRewardEmissionAddress = "0xdDa26973bB8a53BCb0b20a76Edf47474945784F2";

  // let WhitelistedDivisor = new BN("1000000000");

  HolderSushiswapStkXPRTEthInstance = await deployProxy(
    HolderSushiswapStkXPRTEthArtifact,
    [pauseAdmin, from_defaultAdmin, valueDivisor],
    { deployer, initializer: "initialize" }
  );
  console.log(
    "HolderSushiswapStkXPRTEth deployed: ",
    HolderSushiswapStkXPRTEthInstance.address
  );

  const txReceiptGrantRole1 =
    await HolderSushiswapStkXPRTEthInstance.grantRole(
      "0x369da55721ba2b3acddd63aac7d6512c3e5762a78fa01c44f423f97868330c34", StakeLPAddress,
      {
        from: from_defaultAdmin,
        gasPrice: gasPrice,
        gas: gasLimit,
      });
  console.log("grantRole() set for HolderSushiswapStkXPRTEth contract.");

  const txReceiptGrantRole2 =
    await HolderSushiswapStkXPRTEthInstance.grantRole(
      "0x369da55721ba2b3acddd63aac7d6512c3e5762a78fa01c44f423f97868330c34", WhitelistedRewardEmissionAddress,
      {
        from: from_defaultAdmin,
        gasPrice: gasPrice,
        gas: gasLimit,
      });
  console.log("grantRole() set for HolderSushiswapStkXPRTEth contract");

  // set contract addresses in UTokens Contract
  /* const txReceiptSetHolderSushiswapStkXPRTEthContract =
    await PstakeInstance.setHolderSushiswapStkXPRTEthContract(StakeLPInstance.address, {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    });
  console.log("setHolderSushiswapStkXPRTEthContract() set for StakeLP contract."); */

  console.log("ALL DONE.");
}