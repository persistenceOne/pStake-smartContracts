const LiquidStakingArtifact = artifacts.require("LiquidStaking");
const TokenWrapperArtifact = artifacts.require("TokenWrapper");
const STokensArtifact = artifacts.require("STokens");
const UTokensArtifact = artifacts.require("UTokens");

const { BN } = web3.utils.BN;
const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var UTokensInstance,
  STokensInstance,
  TokenWrapperInstance,
 LiquidStakingInstance;

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
    await deployAll(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 5000000;
    await deployAll(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    await deployAll(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
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
  let defaultAdmin = accounts[0];
  let bridgeAdmin = "0x9b3DefB46804BD74518A52dC0cf4FA7280E0B673";
  let pauseAdmin = accounts[0];
  //let rewardRate = new BN(3000000) //0.003
  let rewardRate = new BN(15432) //1.5432 * 10^-5
  let rewardDivisor = new BN("1000000000")

  console.log(bridgeAdmin, "bridgeAdmin")

  UTokensInstance = await deployProxy(
    UTokensArtifact,
    [bridgeAdmin, pauseAdmin],
    { deployer, initializer: "initialize" }
  );
  console.log("UTokens deployed: ", UTokensInstance.address);

  STokensInstance = await deployProxy(
    STokensArtifact,
    [UTokensInstance.address, pauseAdmin, rewardRate, rewardDivisor],
    { deployer, initializer: "initialize" }
  );
  console.log("STokens deployed: ", STokensInstance.address);

    TokenWrapperInstance = await deployProxy(
    TokenWrapperArtifact,
    [UTokensInstance.address, bridgeAdmin, pauseAdmin, rewardDivisor],
    { deployer, initializer: "initialize" }
  );
  console.log("TokenWrapper deployed: ", TokenWrapperInstance.address);

  LiquidStakingInstance = await deployProxy(
    LiquidStakingArtifact,
    [
      UTokensInstance.address,
      STokensInstance.address,
      pauseAdmin,
        rewardDivisor,
    ],
    { deployer, initializer: "initialize" }
  );
  console.log("LiquidStaking deployed: ", LiquidStakingInstance.address);

  // set contract addresses in UTokens Contract
  const txReceiptSetSTokenContract = await UTokensInstance.setSTokenContract(
    STokensInstance.address,
    {
      from: defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setSTokenContract() set for UTokens contract.");

  const txReceiptSetWrapperContract = await UTokensInstance.setWrapperContract(
    TokenWrapperInstance.address,
    {
      from: defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setWrapperContract() set for UTokens contract. ");

  const txReceiptSetLiquidStakingContract = await UTokensInstance.setLiquidStakingContract(
    LiquidStakingInstance.address,
    {
      from: defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setLiquidStakingContract() set for UTokens contract.");

  const txReceiptSetLiquidStakingContract2 = await STokensInstance.setLiquidStakingContract(
    LiquidStakingInstance.address,
    {
      from: defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
    console.log("setLiquidStakingContract() set for STokens contract.");

/*    const txReceiptSetEpochTs = await LiquidStakingInstance.setUnstakeEpoch(
        "1623324050","1623324050",
        {
            from: defaultAdmin,
            gasPrice: gasPrice,
            gas: gasLimit,
        }
    );
    console.log("SetEpochTs() set for LiquidStaking contract.");*/



  console.log("ALL DONE.");
}

//upgrading all contracts
async function upgradeAll(gasPrice, gasLimit, deployer, accounts) {
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
    let defaultAdmin = accounts[0];
    let bridgeAdmin = accounts[1];
    let pauseAdmin = accounts[2];
    let rewardRate = new BN(3000000);

    UTokensInstance = await upgradeProxy(uTokenAddress,
        UTokensArtifact,
        { deployer }
    );
    console.log("UTokens upgraded: ", UTokensInstance.address);

    STokensInstance = await upgradeProxy(sTokenAddress,
        STokensArtifact,
        { deployer }
    );
    console.log("STokens upgraded: ", STokensInstance.address);

    TokenWrapperInstance = await upgradeProxy(tokenWrapperAddress,
        TokenWrapperArtifact,
        { deployer }
    );
    console.log("TokenWrapper upgraded: ", TokenWrapperInstance.address);

    LiquidStakingInstance = await upgradeProxy(liquidStakingAddress,
        LiquidStakingArtifact,
        { deployer }
    );
    console.log("LiquidStaking upgraded: ", LiquidStakingInstance.address);

    console.log("ALL DONE.");
}


//upgrading UTokens contract
async function upgradeUTokens(gasPrice, gasLimit, deployer, accounts) {
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

    UTokensInstance = await upgradeProxy(uTokenAddress,
        UTokensArtifact,
        { deployer }
    );
    console.log("UTokens upgraded: ", UTokensInstance.address);

    console.log("ALL DONE.");
}


//upgrading STokens contract
async function upgradeSTokens(gasPrice, gasLimit, deployer, accounts) {
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

    STokensInstance = await upgradeProxy(sTokenAddress,
        STokensArtifact,
        { deployer }
    );
    console.log("STokens upgraded: ", STokensInstance.address);

    console.log("ALL DONE.");
}


//upgrading TokenWrapper contract
async function upgradeTokenWrapper(gasPrice, gasLimit, deployer, accounts) {
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

    TokenWrapperInstance = await upgradeProxy(tokenWrapperAddress,
        TokenWrapperArtifact,
        { deployer }
    );
    console.log("TokenWrapper upgraded: ", TokenWrapperInstance.address);

    console.log("ALL DONE.");
}


//upgrading LiquidStaking contracts
async function upgradeLiquidStaking(gasPrice, gasLimit, deployer, accounts) {
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
    
    LiquidStakingInstance = await upgradeProxy(liquidStakingAddress,
        LiquidStakingArtifact,
        { deployer }
    );
    console.log("LiquidStaking upgraded: ", LiquidStakingInstance.address);

    console.log("ALL DONE.");
}


