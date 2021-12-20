/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const Migrations = artifacts.require("Migrations");

module.exports = function (deployer, network, accounts) {
  // console.log("deployer: ", deployer);
  deployer.deploy(Migrations);
};
