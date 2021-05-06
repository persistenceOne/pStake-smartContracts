const LiquidStakingArtifact = artifacts.require("LiquidStaking");

const TokenWrapperArtifact = artifacts.require("TokenWrapper");
//const TokenWrapperXPRTArtifact = artifacts.require("TokenWrapperXPRT");

const STokensArtifact = artifacts.require("STokens");
const UTokensArtifact = artifacts.require("UTokens");

//const StkXPRTArtifact = artifacts.require("StkXPRT");
//const UstkXPRTArtifact = artifacts.require("UstkXPRT");

const { BN } = web3.utils.BN;
const { deployProxy } = require("@openzeppelin/truffle-upgrades");
var UTokensInstance,
  STokensInstance,
  TokenWrapperInstance,
 LiquidStakingInstance;

//deploy ATOMs contracts
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

  console.log(bridgeAdmin, "bridgeAdmin")

  UTokensInstance = await deployProxy(
    UTokensArtifact,
    [bridgeAdmin, pauseAdmin],
    { deployer, initializer: "initialize" }
  );
  console.log("UTokens deployed: ", UTokensInstance.address);
  STokensInstance = await deployProxy(
    STokensArtifact,
    [UTokensInstance.address, pauseAdmin, 3000000],
    { deployer, initializer: "initialize" }
  );
  console.log("STokens deployed: ", STokensInstance.address);
  TokenWrapperInstance = await deployProxy(
    TokenWrapperArtifact,
    [UTokensInstance.address, bridgeAdmin, pauseAdmin],
    { deployer, initializer: "initialize" }
  );
  console.log("TokenWrapper deployed: ", TokenWrapperInstance.address);
  LiquidStakingInstance = await deployProxy(
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

  console.log("ALL DONE.");
}


//deploy XPRT contracts
/*
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
    TokenWrapperInstance = await deployProxy(
        TokenWrapperArtifact,
        [UTokensInstance.address, bridgeAdmin, pauseAdmin],
        { deployer, initializer: "initialize" }
    );
    console.log("TokenWrapper deployed: ", TokenWrapperInstance.address);
    LiquidStakingInstance = await deployProxy(
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

    console.log("ALL DONE.");
}
*/
