const { admin } = require("@openzeppelin/truffle-upgrades");

const adminAddress = "0x714d4CaF73a0F5dE755488D14f82e74232DAF5B7";

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
    let gasLimitRopsten = 5000000;
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

  console.log("admin: ", admin);

  await admin.transferProxyAdminOwnership(adminAddress);

  console.log("ProxyAdmin Owner set to: ", adminAddress);

  console.log("ALL DONE.");
}
