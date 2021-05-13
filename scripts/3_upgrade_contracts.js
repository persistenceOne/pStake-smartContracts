const LiquidStakingArtifact = artifacts.require("LiquidStaking");
const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");
let liquidStakingAddress = "0xac749a63F87Fe0A978Cb1002c2DFe9fdC5Bd52e4";

module.exports = async function (deployer, network, accounts) {
    if (network === "goerli") {
        let gasPriceGoerli = 1e11;
        let gasLimitGoerli = 4000000;
        await main(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
    }
}

async function main (gasPriceGoerli, gasLimitGoerli, deployer, accounts){
    console.log("Upgrading LiquidStaking....");
    let LiquidStakingInstance = await upgradeProxy(liquidStakingAddress,
        LiquidStakingArtifact,
        { deployer }
    );
    console.log("LiquidStaking upgraded: ", LiquidStakingInstance.address);
}