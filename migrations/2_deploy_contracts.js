const LiquidStakingArtifact = artifacts.require("LiquidStaking");
const TokenWrapperArtifact = artifacts.require("TokenWrapper");
const STokensArtifact = artifacts.require("STokens");
const UTokensArtifact = artifacts.require("UTokens");
const { BN } = web3.utils.BN;
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
var UTokensInstance, STokensInstance, TokenWrapperInstance, LiquidStakingInstance;

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
  await deployProxy(UTokensArtifact, [accounts[0], accounts[0]], { deployer, initializer: 'initialize' })
  .then(async function (instance) {
    UTokensInstance = instance;
   // console.log("UTokens deployed: ", UTokensInstance.address);
    return await deployProxy(STokensArtifact, [UTokensInstance.address, accounts[0]], { deployer, initializer: 'initialize' });
  })
  .then(async function (instance2) {
    STokensInstance = instance2;
    // console.log("STokens deployed: ", STokensInstance.address);
    // console.log("UTokens address: ", UTokensInstance.address);
    return await deployProxy(TokenWrapperArtifact, [UTokensInstance.address, STokensInstance.address, accounts[0], accounts[0]], { deployer, initializer: 'initialize' });
  })
  .then(async function (instance3) {
    TokenWrapperInstance = instance3;
    // console.log("STokens deployed: ", STokensInstance.address);
    // console.log("UTokens address: ", UTokensInstance.address);
    return await deployProxy(LiquidStakingArtifact, [UTokensInstance.address,STokensInstance.address, TokenWrapperInstance.address, accounts[0], accounts[0]], { deployer, initializer: 'initialize' });
  })
  .then(function (instance4) {
    LiquidStakingInstance = instance4;
   // console.log("LiquidStaking deployed: ", instance4.address);
    return UTokensInstance.setSTokenContract(
        STokensInstance.address,
        {
          from: accounts[0],
          gasPrice: gasPrice,
          gas: gasLimit,
        }
    );
  })
  .then(function (txReceipt) {
    //console.log("setWrapperContract() set for UTokens contract.");
    return UTokensInstance.setWrapperContract(
        TokenWrapperInstance.address,
        {
          from: accounts[0],
          gasPrice: gasPrice,
          gas: gasLimit,
        }
    );
  })
  .then(function (txReceipt) {
    //console.log("setSTokenContract() set for UTokens contract.");
    return UTokensInstance.setLiquidStakingContract(
        LiquidStakingInstance.address,
        {
          from: accounts[0],
          gasPrice: gasPrice,
          gas: gasLimit,
        }
    );
  })
  .then(function (txReceipt) {
    //console.log("setWrapperContract() set for UTokens contract.");
    return STokensInstance.setWrapperContract(
        TokenWrapperInstance.address,
        {
          from: accounts[0],
          gasPrice: gasPrice,
          gas: gasLimit,
        }
    );
  })
  .then(function (txReceipt) {
    /*console.log(
        "setLiquidStakingContract() set for UTokens contract."
    );*/

    return STokensInstance.setLiquidStakingContract(
        LiquidStakingInstance.address,
        {
          from: accounts[0],
          gasPrice: gasPrice,
          gas: gasLimit,
        }
    );
  })
  .then(function (txReceipt) {
    // console.log(
    //     "setLiquidStakingContract() set for Wrapper contract."
    // );

    return TokenWrapperInstance.setLiquidStakingContract(
        LiquidStakingInstance.address,
        {
          from: accounts[0],
          gasPrice: gasPrice,
          gas: gasLimit,
        }
    );

  })
  .then(function (txReceipt) {
    // console.log(
    //     "setLiquidStakingContract() set for STokens contract."
    // );
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
      return UTokensInstance.setSTokenContract(STokensInstance.address, {
        from: accounts[0],
        gasPrice: gasPrice,
        gas: gasLimit,
      });
    })
    .then(function (txReceipt) {
      console.log("setSTokenContract() set for UTokens contract.");
      return UTokensInstance.setLiquidStakingContract(
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
        "setLiquidStakingContract() set for UTokens contract."
      );
      return STokensInstance.setLiquidStakingContract(
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
        "setLiquidStakingContract() set for STokens contract."
      );
      console.log("ALL DONE.");
    })
    .catch(function (e) {
      console.error(e);
    });*/
}
