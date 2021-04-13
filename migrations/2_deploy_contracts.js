const LiquidStakingArtifact = artifacts.require("LiquidStaking");
const StakeFarmingArtifact = artifacts.require("StakeFarming");
const TokenWrapperArtifact = artifacts.require("TokenWrapper");
const STokensArtifact = artifacts.require("STokens");
const UTokensArtifact = artifacts.require("UTokens");
const { BN } = web3.utils.BN;
const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var UTokensInstance,
  STokensInstance,
  TokenWrapperInstance,
  StakeFarmingInstance,
  LiquidStakingInstance;

let uTokenAddress = "0x6030661BA461b482028F4048337f96C8d7D139A2";
let sTokenAddress = "0xb8e5630650eC1476042dC75B807B3ff29551f41B";
let tokenWrapperAddress = "0x6E9bfbf67b299766B6C24FE4e66C14b41e7a70Cf";
let stakeFarmingAddress = "0x8749239387401FFCE788bDD96dAB26d9b98eb028";
let liquidStakingAddress = "0xD2B9a708641c3B9D2050A524356d4e4F022D40b7";

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await deployAll(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 3e10;
    let gasLimitRopsten = 4000000;
    await deployAll(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

    if (network === "rinkeby") {
        let gasPriceRinkeby = 3e10;
        let gasLimitRinkeby = 4000000;
        await deployAll(gasPriceRinkeby, gasLimitRinkeby, deployer, accounts);
    }

  if (network === "goerli") {
    let gasPriceGoerli = 1e11;
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
  let bridgeAdmin = accounts[1];
  let pauseAdmin = accounts[2];
    let airdropsAddress = accounts[3];
    let protocolTreasuryAddress = accounts[4];
    let communityDevFundAddress = accounts[5];
    let teamAddress = accounts[6];

  UTokensInstance = await deployProxy(
    UTokensArtifact,
    [bridgeAdmin, pauseAdmin],
    { deployer, initializer: "initialize" }
  );
  console.log("UTokens deployed: ", UTokensInstance.address);
  STokensInstance = await deployProxy(
    STokensArtifact,
    [UTokensInstance.address, pauseAdmin],
    { deployer, initializer: "initialize" }
  );
  console.log("STokens deployed: ", STokensInstance.address);
    StakeFarmingInstance = await deployProxy(
        StakeFarmingArtifact,
        [pauseAdmin, airdropsAddress, protocolTreasuryAddress, communityDevFundAddress, teamAddress],
        { deployer, initializer: "initialize" }
    );
    console.log("Stake Farming deployed: ", StakeFarmingInstance.address);
  TokenWrapperInstance = await deployProxy(
    TokenWrapperArtifact,
    [UTokensInstance.address, STokensInstance.address, bridgeAdmin, pauseAdmin],
    { deployer, initializer: "initialize" }
  );
  console.log("TokenWrapper deployed: ", TokenWrapperInstance.address);
  LiquidStakingInstance = await deployProxy(
    LiquidStakingArtifact,
    [
      UTokensInstance.address,
      STokensInstance.address,
      TokenWrapperInstance.address,
        StakeFarmingInstance.address,
      bridgeAdmin,
      pauseAdmin,
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

    const txReceiptSetLiquidStakingContract1 = await StakeFarmingInstance.setLiquidStakingContractAddress(
        LiquidStakingInstance.address,
        {
            from: defaultAdmin,
            gasPrice: gasPrice,
            gas: gasLimit,
        }
    );
    console.log("setLiquidStakingContract() set for StakeFarming contract.");


    // set contract addresses in STokens Contract
  const txReceiptSetWrapperContract2 = await STokensInstance.setWrapperContract(
    TokenWrapperInstance.address,
    {
      from: defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );

  const txReceiptSetLiquidStakingContract2 = await STokensInstance.setLiquidStakingContract(
    LiquidStakingInstance.address,
    {
      from: defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );

  // set contract addresses in TokenWrapper Contract
  const txReceiptSetLiquidStakingContract3 = await TokenWrapperInstance.setLiquidStakingContract(
    LiquidStakingInstance.address,
    {
      from: defaultAdmin,
      gasPrice: gasPrice,
      gas: gasLimit,
    }
  );

  console.log("ALL DONE.");
}

//upgrading contracts
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
    let airdropsAddress = accounts[3];
    let protocolTreasuryAddress = accounts[4];
    let communityDevFundAddress = accounts[5];
    let teamAddress = accounts[6];

    UTokensInstance = await upgradeProxy(uTokenAddress,
        UTokensArtifact,
        [bridgeAdmin, pauseAdmin],
        { deployer, initializer: "initialize" }
    );
    console.log("UTokens upgraded: ", UTokensInstance.address);
    STokensInstance = await upgradeProxy(sTokenAddress,
        STokensArtifact,
        [UTokensInstance.address, pauseAdmin],
        { deployer, initializer: "initialize" }
    );
    console.log("STokens upgraded: ", STokensInstance.address);

    StakeFarmingInstance = await upgradeProxy(stakeFarmingAddress,
        StakeFarmingArtifact,
        [pauseAdmin, airdropsAddress, protocolTreasuryAddress, communityDevFundAddress, teamAddress],
        { deployer, initializer: "initialize" }
    );
    console.log("Stake Farming upgraded: ", StakeFarmingInstance.address);

    TokenWrapperInstance = await upgradeProxy(tokenWrapperAddress,
        TokenWrapperArtifact,
        [UTokensInstance.address, STokensInstance.address, bridgeAdmin, pauseAdmin],
        { deployer, initializer: "initialize" }
    );
    console.log("TokenWrapper upgraded: ", TokenWrapperInstance.address);

    LiquidStakingInstance = await upgradeProxy(liquidStakingAddress,
        LiquidStakingArtifact,
        [
            UTokensInstance.address,
            STokensInstance.address,
            TokenWrapperInstance.address,
            bridgeAdmin,
            pauseAdmin,
        ],
        { deployer, initializer: "initialize" }
    );
    console.log("LiquidStaking upgraded: ", LiquidStakingInstance.address);

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

    const txReceiptSetLiquidStakingContract1 = await StakeFarmingInstance.setLiquidStakingContractAddress(
        LiquidStakingInstance.address,
        {
            from: defaultAdmin,
            gasPrice: gasPrice,
            gas: gasLimit,
        }
    );
    console.log("setLiquidStakingContract() set for StakeFarming contract.");


    // set contract addresses in STokens Contract
    const txReceiptSetWrapperContract2 = await STokensInstance.setWrapperContract(
        TokenWrapperInstance.address,
        {
            from: defaultAdmin,
            gasPrice: gasPrice,
            gas: gasLimit,
        }
    );

    const txReceiptSetLiquidStakingContract2 = await STokensInstance.setLiquidStakingContract(
        LiquidStakingInstance.address,
        {
            from: defaultAdmin,
            gasPrice: gasPrice,
            gas: gasLimit,
        }
    );

    // set contract addresses in TokenWrapper Contract
    const txReceiptSetLiquidStakingContract3 = await TokenWrapperInstance.setLiquidStakingContract(
        LiquidStakingInstance.address,
        {
            from: defaultAdmin,
            gasPrice: gasPrice,
            gas: gasLimit,
        }
    );

    console.log("ALL DONE.");
}




