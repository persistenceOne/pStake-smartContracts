const { admin } = require("@openzeppelin/truffle-upgrades");
var StakeLPInstance;

// This needs to be deployed separately after changing the mnemonic in the truffle-config.js to: 
// baby year rocket october what surprise lab bag report swap game unveil
// This is highly urgent to deploy. Deploy this at the end as the 11th migration file

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await transferOwnership(
      gasPriceGanache,
      gasLimitGanache,
      deployer,
      accounts
    );
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 7000000;
    await transferOwnership(
      gasPriceRopsten,
      gasLimitRopsten,
      deployer,
      accounts
    );
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await transferOwnership(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    await transferOwnership(
      gasPriceMainnet,
      gasLimitMainnet,
      deployer,
      accounts
    );
  }
};

async function transferOwnership(gasPrice, gasLimit, deployer, accounts) {
  console.log(
    "inside transferOwnership(),",
    " gasPrice: ",
    gasPrice,
    " gasLimit: ",
    gasLimit,
    " deployer: ",
    deployer.network,
    " accounts: ",
    accounts
  );

  let new_owner = "0x7f5c7596748128fe72e6b353650094646f327569";

  let from_defaultAdmin = accounts[0];

  StakeLPInstance = await admin.transferProxyAdminOwnership(new_owner, {from: from_defaultAdmin});

  console.log("ownership transfered to : ", new_owner);
  console.log("ALL DONE.");
}
