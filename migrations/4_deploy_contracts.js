const HolderUniswapArtifact = artifacts.require("HolderUniswap");
const StakeLPArtifact = artifacts.require("StakeLPCore");
const StakeLPArtifactV2 = artifacts.require("StakeLPCoreV2");
const PSTAKEArtifact = artifacts.require("PSTAKE");
const LiquidStakingArtifact = artifacts.require("LiquidStaking");
const TokenWrapperArtifact = artifacts.require("TokenWrapper");
const STokensArtifact = artifacts.require("STokens");
const UTokensArtifact = artifacts.require("UTokens");

const uTokensJSON = require('../build/contracts/UTokens.json');
const sTokensJSON = require('../build/contracts/STokens.json');
const networkID = 3;

const { BN } = web3.utils.BN;
const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var UTokensInstance,
    STokensInstance,
    TokenWrapperInstance,
    LiquidStakingInstance,
    HolderUniswapInstance,
    StakeLPInstance,
    PstakeInstance;

/*[ '0x466aF9ea44f2dEbbE4fd54a98CffA26A3674fBf7',
    '0x51caF3f0E53BAAF12F8B0B6d98350CBA53e8DB7B',
    '0xCC6F6821F903b1FC3C0c9597b26C84E31AC98B36',
    '0xa69dE4538Fd5384FfB4e415B861dBc7eAED75dF2',
    '0x609d344A04245104C312925D2F5aE04F643A10CB',
    '0x7019943Ca5E81d10EFA8ACdd68B0B67Eb4B0a9f6',
    '0x768D4C50C9D4Db6f12Bb47581E4c1823Ad9eCB49',
    '0xe3355d5AD5f8dCdca879230e85eF0AaeE6f28d0B',
    '0x528B19d24426C4A78D0fDC0933c3F91C87102adA',
    '0x3F5fdb1c4B40b04f54082482DCBF9732c1199eB6' ]*/


//deploy ATOMs contracts
module.exports = async function (deployer, network, accounts) {
    if (network === "development") {
        let gasPriceGanache = 3e10;
        let gasLimitGanache = 800000;
        await upgradeStakeLP(gasPriceGanache, gasLimitGanache, deployer, accounts);
    }

    if (network === "ropsten") {
        let gasPriceRopsten = 1e11;
        let gasLimitRopsten = 5000000;
        await upgradeStakeLP(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
    }

    if (network === "goerli") {
        let gasPriceGoerli = 5e12;
        let gasLimitGoerli = 4000000;
        await upgradeStakeLP(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
    }

    if (network === "mainnet") {
        let gasPriceMainnet = 5e10;
        let gasLimitMainnet = 7000000;
        await upgradeStakeLP(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
    }
};
//upgrading StakeLP contract
async function upgradeStakeLP(gasPrice, gasLimit, deployer, accounts) {
    console.log(
        "inside deployAll(),",
        " gasPrice: ",
        gasPrice,
        " gasLimit: ",
        gasLimit,
        " deployer: ",
        deployer.network,
        " accounts: ",
        accounts
    );
    //const lp = await StakeLPArtifact.deployed();

    //console.log("StakeLP address: ", lp.address)

    StakeLPInstance = await upgradeProxy("0x6532f1cc72F34523aB815d2A7f2754afec17c8B4",
        StakeLPArtifactV2, { deployer }
    );
    console.log("StakeLP upgraded: ", StakeLPInstance.address);

    console.log("ALL DONE.");
}