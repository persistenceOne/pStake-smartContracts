const WhitelistedEmissionArtifactV2 = artifacts.require(
  "WhitelistedEmissionV2"
);
const StakeLPArtifactV15 = artifacts.require("StakeLPCoreV15");
const StakeLPArtifactV14 = artifacts.require("StakeLPCoreV14");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var StakeLPInstance;

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await upgradeStakeLPCore(
      gasPriceGanache,
      gasLimitGanache,
      deployer,
      accounts
    );
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await upgradeStakeLPCore(
      gasPriceRopsten,
      gasLimitRopsten,
      deployer,
      accounts
    );
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await upgradeStakeLPCore(
      gasPriceGoerli,
      gasLimitGoerli,
      deployer,
      accounts
    );
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await upgradeStakeLPCore(
      gasPriceMainnet,
      gasLimitMainnet,
      deployer,
      accounts
    );
  }
};

async function upgradeStakeLPCore(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside upgradeStakeLPCore(),",
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

  StakeLPInstance = await upgradeProxy(
    StakeLPArtifactV14.address,
    StakeLPArtifactV15,
    { deployer }
  );

  console.log("StakeLP upgraded: ", StakeLPInstance.address);

  // set contract addresses in UTokens Contract
  const txReceipt = await StakeLPInstance.setWhitelistedEmissionContract(
    WhitelistedEmissionArtifactV2.address,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setWhitelistedEmissionContract() done");

  console.log("ALL DONE.");
}
