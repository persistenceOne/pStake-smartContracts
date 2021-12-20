const Migrations = artifacts.require("Migrations");

module.exports = function (deployer, network, accounts) {
  // console.log("deployer: ", deployer);
  deployer.deploy(Migrations);
};
