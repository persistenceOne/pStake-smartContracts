const LiquidStakingArtifact = artifacts.require("LiquidStaking");
const STokensArtifact = artifacts.require("STokens");
const UTokensArtifact = artifacts.require("UTokens");
const { BN } = web3.utils.BN;
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
var UTokensInstance, STokensInstance, LiquidStakingInstance;

module.exports = function (deployer, network, accounts) {
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 4000000;
    deployAll(gasPriceGanache, gasLimitGanache, deployer, accounts);
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 3e10;
    let gasLimitRopsten = 4000000;
    deployAll(gasPriceRopsten, gasLimitRopsten, deployer, accounts);
  }

  if (network === "goerli") {
    let gasPriceGoerli = 1e11;
    let gasLimitGoerli = 4000000;
    deployAll(gasPriceGoerli, gasLimitGoerli, deployer, accounts);
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
  await deployProxy(UTokensArtifact, [], { deployer, initializer: 'initialize' })
  .then(async function (instance) {
    UTokensInstance = instance;
    console.log("UTokens deployed: ", UTokensInstance.address);
    return await deployProxy(STokensArtifact, [UTokensInstance.address], { deployer, initializer: 'initialize' });
  })
  .then(async function (instance2) {
    STokensInstance = instance2;
    console.log("STokens deployed: ", STokensInstance.address);
    console.log("UTokens address: ", UTokensInstance.address);
    return await deployProxy(LiquidStakingArtifact, [UTokensInstance.address,STokensInstance.address], { deployer, initializer: 'initialize' });
  })
  .then(function (instance3) {
    LiquidStakingInstance = instance3;
    console.log("LiquidStaking deployed: ", instance3.address);
    return UTokensInstance.methods.setSTokenContractAddress(STokensInstance.address).send({
      from: accounts[0],
      gasPrice: gasPrice,
      gas: gasLimit,
    });
  })
  .then(function (txReceipt) {
    console.log("setSTokenContractAddress() set for UTokens contract.");
    return UTokensInstance.methods.setLiquidStakingContractAddress(
        LiquidStakingInstance.address).send(
        {
          from: accounts[0],
          gasPrice: gasPrice,
          gas: gasLimit,
        }
    );
  })
  .then(function (txReceipt) {
    console.log(
        "setLiquidStakingContractAddress() set for UTokens contract."
    );
    return STokensInstance.methods.setLiquidStakingContractAddress(
        LiquidStakingInstance.address).send(
        {
          from: accounts[0],
          gasPrice: gasPrice,
          gas: gasLimit,
        }
    );
  })
  .then(function (txReceipt) {
    console.log(
        "setLiquidStakingContractAddress() set for STokens contract."
    );
    console.log("ALL DONE.");
  })
  .catch(function (e) {
    console.error(e);
  });




  /*deployer
    .deploy(UTokensArtifact, {
      from: accounts[0],
      gasPrice: gasPrice,
      gas: gasLimit,
    })
    .then(function (instance) {
      UTokensInstance = instance;
      console.log("UTokens deployed: ", UTokensInstance.address);
      return deployer.deploy(STokensArtifact, UTokensInstance.address, {
        from: accounts[0],
        gasPrice: gasPrice,
        gas: gasLimit,
      });
    })
    .then(function (instance2) {
      STokensInstance = instance2;
      console.log("STokens deployed: ", STokensInstance.address);
      console.log("UTokens address: ", UTokensInstance.address);
      return deployer.deploy(
        LiquidStakingArtifact,
        UTokensInstance.address,
        STokensInstance.address,
        {
          from: accounts[0],
          gasPrice: gasPrice,
          gas: gasLimit,
        }
      );
    })
    .then(function (instance3) {
      LiquidStakingInstance = instance3;
      console.log("LiquidStaking deployed: ", instance3.address);
      return UTokensInstance.setSTokenContractAddress(STokensInstance.address, {
        from: accounts[0],
        gasPrice: gasPrice,
        gas: gasLimit,
      });
    })
    .then(function (txReceipt) {
      console.log("setSTokenContractAddress() set for UTokens contract.");
      return UTokensInstance.setLiquidStakingContractAddress(
        LiquidStakingInstance.address,
        {
          from: accounts[0],
          gasPrice: gasPrice,
          gas: gasLimit,
        }
      );
    })
    .then(function (txReceipt) {
      console.log(
        "setLiquidStakingContractAddress() set for UTokens contract."
      );
      return STokensInstance.setLiquidStakingContractAddress(
        LiquidStakingInstance.address,
        {
          from: accounts[0],
          gasPrice: gasPrice,
          gas: gasLimit,
        }
      );
    })
    .then(function (txReceipt) {
      console.log(
        "setLiquidStakingContractAddress() set for STokens contract."
      );
      console.log("ALL DONE.");
    })
    .catch(function (e) {
      console.error(e);
    });*/
}
