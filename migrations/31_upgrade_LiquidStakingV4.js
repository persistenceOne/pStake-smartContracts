/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

const LiquidStakingArtifactV4 = artifacts.require("LiquidStakingV4");
const LiquidStakingArtifactV3 = artifacts.require("LiquidStakingV3");
const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var LiquidStakingInstance;

module.exports = async function (deployer, network, accounts) {
    if (network === "development") {
        let gasPriceGanache = 3e10;
        let gasLimitGanache = 800000;
        await LiquidStaking(gasPriceGanache, gasLimitGanache, deployer, accounts);
    }

    if (network === "ropsten") {
        let gasPriceRopsten = 3e10;
        let gasLimitRopsten = 7000000;
        await LiquidStaking(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
    }

    if (network === "goerli") {
        let gasPriceGoerli = 5e12;
        let gasLimitGoerli = 4000000;
        await LiquidStaking(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
    }

    if (network === "mainnet") {
        let gasPriceMainnet = 15e10;
        let gasLimitMainnet = 7000000;
        await LiquidStaking(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
    }
};

async function LiquidStaking(gasPrice, gasLimit, deployer, accounts) {
    console.log(
        "inside LiquidStaking(),",
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

    LiquidStakingInstance = await upgradeProxy(
        LiquidStakingArtifactV3.address,
        LiquidStakingArtifactV4,
        { deployer }
    );

    console.log("LiquidStakingV4 upgraded: ", LiquidStakingInstance.address);

    console.log("ALL DONE.");
}
