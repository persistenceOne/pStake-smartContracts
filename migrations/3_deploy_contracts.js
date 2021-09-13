const LiquidStakingXPRTArtifact = artifacts.require("LiquidStakingXPRT");
const TokenWrapperXPRTArtifact = artifacts.require("TokenWrapperXPRT");
const STokensXPRTArtifact = artifacts.require("STokensXPRT");
const UTokensXPRTArtifact = artifacts.require("UTokensXPRT");

var networkID;

const { BN } = web3.utils.BN;
const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var UTokensXPRTInstance,
  STokensXPRTInstance,
  TokenWrapperXPRTInstance,
  LiquidStakingXPRTInstance;

// compilation: npx truffle compile
// test blockchain to deploy contracts in dev env
// ganache-cli -m "baby year rocket october what surprise lab bag report swap game unveil" -p 8545 -b 10 -l 8000000 –callGasLimit “0x61a80” –-networkId 5777 –-chainId 5777
// migration to ganache (development): npx truffle migrate
// migration to ropsten: npx truffle migrate --network ropsten

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
    networkID = 5777;
    await deployAll(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 5000000;
    networkID = 3;
    await deployAll(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    networkID = 5;
    await deployAll(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    networkID = 1;
    await deployAll(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function deployAll(gasPrice, gasLimit, deployer, accounts) {
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
  //let defaultAdmin = "0x714d4CaF73a0F5dE755488D14f82e74232DAF5B7";
  let bridgeAdmin = "0x9b3DefB46804BD74518A52dC0cf4FA7280E0B673";
  let pauseAdmin = accounts[0];
  let from_defaultAdmin = accounts[0];
  //let rewardRate = new BN(3000000) //0.003
  let rewardRate = new BN(1046); // 1046 * 10^-5
  let rewardDivisor = new BN("1000000000");
  let epochInterval = "259200"; //3 hours
  let unstakingLockTime = "1814400"; // 21 hours

  console.log(bridgeAdmin, "bridgeAdmin");

  UTokensXPRTInstance = await deployProxy(
    UTokensXPRTArtifact,
    [bridgeAdmin, pauseAdmin],
    { deployer, initializer: "initialize" }
  );
  console.log("UTokensXPRT deployed: ", UTokensXPRTInstance.address);

  STokensXPRTInstance = await deployProxy(
    STokensXPRTArtifact,
    [UTokensXPRTInstance.address, pauseAdmin, rewardRate, rewardDivisor],
    { deployer, initializer: "initialize" }
  );
  console.log("STokensXPRT deployed: ", STokensXPRTInstance.address);

  TokenWrapperXPRTInstance = await deployProxy(
    TokenWrapperXPRTArtifact,
    [UTokensXPRTInstance.address, bridgeAdmin, pauseAdmin, rewardDivisor],
    { deployer, initializer: "initialize" }
  );
  console.log("TokenWrapperXPRT deployed: ", TokenWrapperXPRTInstance.address);

  LiquidStakingXPRTInstance = await deployProxy(
    LiquidStakingXPRTArtifact,
    [
      UTokensXPRTInstance.address,
      STokensXPRTInstance.address,
      pauseAdmin,
      unstakingLockTime,
      epochInterval,
      rewardDivisor,
    ],
    { deployer, initializer: "initialize" }
  );
  console.log(
    "LiquidStakingXPRT deployed: ",
    LiquidStakingXPRTInstance.address
  );

  // set contract addresses in UTokensXPRT Contract
  const txReceiptSetSTokenContract =
    await UTokensXPRTInstance.setSTokenContract(STokensXPRTInstance.address, {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    });
  console.log("setSTokenContract() set for UTokensXPRT contract.");

  const txReceiptSetWrapperContract =
    await UTokensXPRTInstance.setWrapperContract(
      TokenWrapperXPRTInstance.address,
      {
        from: from_defaultAdmin,
        gasPrice: gasPrice,
        gas: gasLimit,
      }
    );
  console.log("setWrapperContract() set for UTokensXPRT contract. ");

  const txReceiptSetLiquidStakingXPRTContract =
    await UTokensXPRTInstance.setLiquidStakingContract(
      LiquidStakingXPRTInstance.address,
      {
        from: from_defaultAdmin,
        gasPrice: gasPrice,
        gas: gasLimit,
      }
    );
  console.log("setLiquidStakingXPRTContract() set for UTokensXPRT contract.");

  const txReceiptSetLiquidStakingXPRTContract2 =
    await STokensXPRTInstance.setLiquidStakingContract(
      LiquidStakingXPRTInstance.address,
      {
        from: from_defaultAdmin,
        gasPrice: gasPrice,
        gas: gasLimit,
      }
    );
  console.log("setLiquidStakingXPRTContract() set for STokensXPRT contract.");

  //set min value for wrap
  const txReceiptSetMinval = await TokenWrapperXPRTInstance.setMinimumValues(
    "5000000",
    "1",
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setMinimumValues() set for Token Wrapper contract.");

  console.log("ALL DONE.");
}
