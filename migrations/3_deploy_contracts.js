const HolderUniswapArtifact = artifacts.require("HolderUniswap");
const StakeLPArtifact = artifacts.require("StakeLPCore");
const PSTAKEArtifact = artifacts.require("PSTAKE");
const LiquidStakingArtifact = artifacts.require("LiquidStaking");
const TokenWrapperArtifact = artifacts.require("TokenWrapper");
const STokensArtifact = artifacts.require("STokens");
const UTokensArtifact = artifacts.require("UTokens");

const uTokensJSON = require("../build/contracts/UTokens.json");
const sTokensJSON = require("../build/contracts/STokens.json");
var networkID;

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
    networkID = 5777;
    await deployStakeLP(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 1e11;
    let gasLimitRopsten = 5000000;
    networkID = 3;
    await deployStakeLP(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 5e12;
    let gasLimitGoerli = 4000000;
    networkID = 5;
    await deployStakeLP(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }

  if (network === "mainnet") {
    let gasPriceMainnet = 5e10;
    let gasLimitMainnet = 7000000;
    networkID = 1;
    await deployStakeLP(gasPriceMainnet, gasLimitMainnet, deployer, accounts);
  }
};

async function deployStakeLP(gasPrice, gasLimit, deployer, accounts) {
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
  let pauseAdmin = accounts[0];
  let from_defaultAdmin = accounts[0];
  let rewardDivisor = new BN("1000000000");
  console.log("NetworkId: ", networkID);

  const uAddress = uTokensJSON.networks[networkID].address;
  const sAddress = sTokensJSON.networks[networkID].address;

  console.log("deployStakeLP() called");
  console.log("uAddress: ", uAddress);
  console.log("sAddress: ", sAddress);

  PstakeInstance = await deployProxy(PSTAKEArtifact, [pauseAdmin], {
    deployer,
    initializer: "initialize",
  });
  console.log("PSTAKE deployed: ", PstakeInstance.address);

  StakeLPInstance = await deployProxy(
    StakeLPArtifact,
    [uAddress, sAddress, PstakeInstance.address, pauseAdmin],
    { deployer, initializer: "initialize" }
  );
  console.log("StakeLP deployed: ", StakeLPInstance.address);

  HolderUniswapInstance = await deployProxy(
    HolderUniswapArtifact,
    [sAddress, StakeLPInstance.address, rewardDivisor],
    { deployer, initializer: "initialize" }
  );
  console.log("HolderUniswap deployed: ", HolderUniswapInstance.address);

  // set contract addresses in UTokens Contract
  const txReceiptSetStakeLPCoreContract =
    await PstakeInstance.setStakeLPCoreContract(StakeLPInstance.address, {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    });
  console.log("setStakeLPCoreContract() set for StakeLP contract.");

  // set contract addresses in holder uniswap Contract
  const txReceiptSetStakeLPContract =
    await HolderUniswapInstance.setStakeLPContract(StakeLPInstance.address, {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    });
  console.log("setStakeLPContract() set for Holder Uniswap contract.");

  console.log("ALL DONE.");
}

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
  let rewardRate = new BN(222); // 222 * 10^-5
  let rewardDivisor = new BN("1000000000");
  let epochInterval = "10800"; //3 hours
  let unstakingLockTime = "75600"; // 21 hours

  console.log(bridgeAdmin, "bridgeAdmin");

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
      unstakingLockTime,
      epochInterval,
      rewardDivisor,
    ],
    { deployer, initializer: "initialize" }
  );
  console.log("LiquidStaking deployed: ", LiquidStakingInstance.address);

  // set contract addresses in UTokens Contract
  const txReceiptSetSTokenContract = await UTokensInstance.setSTokenContract(
    STokensInstance.address,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setSTokenContract() set for UTokens contract.");

  const txReceiptSetWrapperContract = await UTokensInstance.setWrapperContract(
    TokenWrapperInstance.address,
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setWrapperContract() set for UTokens contract. ");

  const txReceiptSetLiquidStakingContract =
    await UTokensInstance.setLiquidStakingContract(
      LiquidStakingInstance.address,
      {
        from: from_defaultAdmin,
        gasPrice: gasPrice,
        gas: gasLimit,
      }
    );
  console.log("setLiquidStakingContract() set for UTokens contract.");

  const txReceiptSetLiquidStakingContract2 =
    await STokensInstance.setLiquidStakingContract(
      LiquidStakingInstance.address,
      {
        from: from_defaultAdmin,
        gasPrice: gasPrice,
        gas: gasLimit,
      }
    );
  console.log("setLiquidStakingContract() set for STokens contract.");

  //set min value for wrap
  const txReceiptSetMinval = await TokenWrapperInstance.setMinimumValues(
    "5000000",
    "1",
    {
      from: from_defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );
  console.log("setMinimumValues() set for Token Wrapper contract.");

  /* //set fees for wrap
     const txReceiptSetFees = await TokenWrapperInstance.setFees(
         "350000000","0",
         {
             from: from_defaultAdmin,
             gasPrice: gasPrice,
             gas: gasLimit,
         }
     );
     console.log("setFees() set for Token Wrapper contract.");

     //set fees for claim rewards
     const txReceiptSetRewardFees = await STokensInstance.setFees(
         "5000000000",
         {
             from: from_defaultAdmin,
             gasPrice: gasPrice,
             gas: gasLimit,
         }
     );
     console.log("setFees() set for Stokens contract.");*/

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

  UTokensInstance = await upgradeProxy(uTokenAddress, UTokensArtifact, {
    deployer,
  });
  console.log("UTokens upgraded: ", UTokensInstance.address);

  STokensInstance = await upgradeProxy(sTokenAddress, STokensArtifact, {
    deployer,
  });
  console.log("STokens upgraded: ", STokensInstance.address);

  TokenWrapperInstance = await upgradeProxy(
    tokenWrapperAddress,
    TokenWrapperArtifact,
    { deployer }
  );
  console.log("TokenWrapper upgraded: ", TokenWrapperInstance.address);

  LiquidStakingInstance = await upgradeProxy(
    liquidStakingAddress,
    LiquidStakingArtifact,
    { deployer }
  );
  console.log("LiquidStaking upgraded: ", LiquidStakingInstance.address);

  console.log("ALL DONE.");
}

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

  StakeLPInstance = await upgradeProxy(
    "0x6532f1cc72F34523aB815d2A7f2754afec17c8B4",
    STokensArtifact,
    { deployer }
  );
  console.log("StakeLP upgraded: ", StakeLPInstance.address);

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

  UTokensInstance = await upgradeProxy(uTokenAddress, UTokensArtifact, {
    deployer,
  });
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

  STokensInstance = await upgradeProxy(sTokenAddress, STokensArtifact, {
    deployer,
  });
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

  TokenWrapperInstance = await upgradeProxy(
    tokenWrapperAddress,
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

  LiquidStakingInstance = await upgradeProxy(
    liquidStakingAddress,
    LiquidStakingArtifact,
    { deployer }
  );
  console.log("LiquidStaking upgraded: ", LiquidStakingInstance.address);

  console.log("ALL DONE.");
}
