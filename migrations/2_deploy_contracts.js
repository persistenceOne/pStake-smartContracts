const VestingTimelockArtifact = artifacts.require("VestingTimelock");
const LiquidStakingArtifact = artifacts.require("LiquidStaking");
const TokenWrapperArtifact = artifacts.require("TokenWrapper");
const STokensArtifact = artifacts.require("STokens");
const UTokensArtifact = artifacts.require("UTokens");

const StkXPRTArtifact = artifacts.require("StkXPRT");
const UstkXPRTArtifact = artifacts.require("UstkXPRT");

const { BN } = web3.utils.BN;
const { deployProxy } = require("@openzeppelin/truffle-upgrades");
var UTokensInstance,
  STokensInstance,
  TokenWrapperInstance,
  LiquidStakingInstance,
    ustkXPRTInstance,
    stkXPRTInstance,
    VestingTimelockInstance;

const ustkXPRTContractAddress = "0x04AE194386F89Abf5Fe91a3521353ea92D0EAbf8";

module.exports = async function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 800000;
    await deployAll(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 5e10;
    let gasLimitRopsten = 1000000;
    await deployVesting(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 1e11;
    let gasLimitGoerli = 4000000;
    await deployAll(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
  }
};

async function deployVesting(gasPrice, gasLimit, deployer, accounts) {
    console.log(
        "inside deployVesting(),",
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
    let pstkTreasury = accounts[3];
    let amount = [];
    let startTime = [];
    let cliff = [];
    let recipient = [];
    let totalAmount = new BN("10000000000");
    let numUsers = 5;

    console.log("otalAmount.div(numUsers) + " + totalAmount.div(new BN(numUsers)))
    for(let i=0; i<numUsers; i++){
        amount.push(totalAmount.div(new BN(numUsers)))
        startTime.push(parseInt(Date.now()/1000))
        recipient.push(accounts[i+4])
        cliff.push(parseInt(Date.now()/1000) + 180)
    }

    UTokensInstance = await deployProxy(
        UstkXPRTArtifact,
        [bridgeAdmin, pauseAdmin, pstkTreasury],
        { deployer, initializer: "initialize" }
    );
    console.log("ustkXPRT deployed: ", UTokensInstance.address);

    VestingTimelockInstance = await deployProxy(
        VestingTimelockArtifact,
        [UTokensInstance.address, pauseAdmin],
        { deployer, initializer: "initialize" }
    );
    console.log("VestingTimelock deployed: ", VestingTimelockInstance.address);

    await UTokensInstance.transfer(VestingTimelockInstance.address, totalAmount, {from: pstkTreasury})

    console.log("Transfer done.")

    await VestingTimelockInstance.addGrants(startTime, amount, cliff, recipient, {from: defaultAdmin})

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
