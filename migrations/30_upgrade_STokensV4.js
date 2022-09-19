/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const STokensArtifactV4 = artifacts.require("STokensV4");
const STokensArtifactV3 = artifacts.require("STokensV3");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var STokensInstance;

module.exports = async function (deployer, network, accounts) {
    if (network === "development") {
        let gasPriceGanache = 3e10;
        let gasLimitGanache = 800000;
        await STokens(gasPriceGanache, gasLimitGanache, deployer, accounts);
    }

    if (network === "ropsten") {
        let gasPriceRopsten = 3e10;
        let gasLimitRopsten = 7000000;
        await STokens(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
    }

    if (network === "goerli") {
        let gasPriceGoerli = 5e12;
        let gasLimitGoerli = 4000000;
        await STokens(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
    }

    if (network === "mainnet") {
        let gasPriceMainnet = 15e10;
        let gasLimitMainnet = 7000000;
        await STokens(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
    }
};

async function STokens(gasPrice, gasLimit, deployer, accounts) {
    console.log(
        "inside STokens(),",
        " gasPrice: ",
        gasPrice,
        " gasLimit: ",
        gasLimit,
        " deployer: ",
        deployer.network,
        " accounts: ",
        accounts
    );

    STokensInstance = await upgradeProxy(
        STokensArtifactV3.address,
        STokensArtifactV4,
        { deployer }
    );

    console.log("STokens upgraded: ", STokensInstance.address);

    console.log("ALL DONE.");
}
