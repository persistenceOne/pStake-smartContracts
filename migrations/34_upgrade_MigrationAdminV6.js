/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const MigrationAdminArtifactV6 = artifacts.require("MigrationAdminV6");
const MigrationAdminArtifactV5 = artifacts.require("MigrationAdminV5");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var MigrationAdminInstance;

module.exports = async function (deployer, network, accounts) {
    if (network === "development") {
        let gasPriceGanache = 3e10;
        let gasLimitGanache = 800000;
        await upgradeMigrationAdmin(
            gasPriceGanache,
            gasLimitGanache,
            deployer,
            accounts
        );
    }

    if (network === "ropsten") {
        let gasPriceRopsten = 3e10;
        let gasLimitRopsten = 7000000;
        await upgradeMigrationAdmin(
            gasPriceRopsten,
            gasLimitRopsten,
            deployer,
            accounts
        );
    }

    if (network === "goerli") {
        let gasPriceGoerli = 5e12;
        let gasLimitGoerli = 4000000;
        await upgradeMigrationAdmin(
            gasPriceGoerli,
            gasLimitGoerli,
            deployer,
            accounts
        );
    }

    if (network === "mainnet") {
        let gasPriceMainnet = 5e10;
        let gasLimitMainnet = 7000000;
        await upgradeMigrationAdmin(
            gasPriceMainnet,
            gasLimitMainnet,
            deployer,
            accounts
        );
    }
};

async function upgradeMigrationAdmin(gasPrice, gasLimit, deployer, accounts) {
    console.log(
        "inside upgradeMigrationAdmin(),",
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
    // let HRPBytes = 0x70657273697374656e6365;

    MigrationAdminInstance = await upgradeProxy(
        MigrationAdminArtifactV5.address,
        MigrationAdminArtifactV6,
        { deployer }
    );

    console.log("MigrationAdminV6 upgraded: ", MigrationAdminInstance.address);

    console.log("ALL DONE.");
}
