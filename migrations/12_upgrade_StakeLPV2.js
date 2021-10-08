const WhitelistedPTokenEmissionArtifact = artifacts.require("WhitelistedPTokenEmission");
const WhitelistedRewardEmissionArtifact = artifacts.require("WhitelistedRewardEmission");

const StakeLPCoreArtifact = artifacts.require("StakeLP");
const StakeLPCoreV2Artifact = artifacts.require("StakeLPV2");
var networkID;

// const { BN } = web3.utils.BN;
const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const { BN } = web3.utils.BN;
let StakeLPCoreInstance;

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
    let gasPriceMainnet = 15e10;
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
  // init parameters
  let pauseAdmin = accounts[0];
  let from_defaultAdmin = accounts[0];
  let valueDivisor = new BN("1000000000");

  // let WhitelistedDivisor = new BN("1000000000");

  StakeLPCoreInstance = await upgradeProxy(
    StakeLPCoreArtifact.address,
    StakeLPCoreV2Artifact,
    { deployer }
  );

  console.log("StakeLP upgraded: ", StakeLPCoreInstance.address);

  // set contract addresses in UTokens Contract
  /* const txReceiptSetStakeLPCoreContract =
    await PstakeInstance.setStakeLPCoreContract(StakeLPInstance.address, {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    });
  console.log("setStakeLPCoreContract() set for StakeLP contract."); */

  console.log("ALL DONE.");
}
