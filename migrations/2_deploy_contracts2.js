// eslint-disable-next-line no-undef
const LiquidStakingArtifact = artifacts.require("LiquidStaking");
const STokensArtifact = artifacts.require("STokens");
const UTokensArtifact = artifacts.require("UTokens");
// eslint-disable-next-line no-undef
const { BN } = web3.utils.BN;

module.exports = function (deployer, network, accounts) {
  var UTokensInstance, STokensInstance, LiquidStakingInstance;
  if (network === "development") {
    let gasPriceGanache = 3e10;
    let gasLimitGanache = 4000000;
    console.log("Accounts: ", accounts);
    deployer
      .deploy(UTokensArtifact, {
        from: accounts[0],
        gasPrice: gasPriceGanache,
        gas: gasLimitGanache,
      })
      .then(function (instance) {
        UTokensInstance = instance;
        console.log("UTokens deployed: ", instance.address);
        return deployer.deploy(STokensArtifact, UTokensInstance.address, {
          from: accounts[0],
          gasPrice: gasPriceGanache,
          gas: gasLimitGanache,
        });
      })
      .then(function (instance2) {
        STokensInstance = instance2;
        console.log("STokens deployed: ", instance2.address);
        return deployer.deploy(
          LiquidStakingArtifact,
          UTokensInstance.address,
          STokensInstance.address,
          {
            from: accounts[0],
            gasPrice: gasPriceGanache,
            gas: gasLimitGanache,
          }
        );
      })
      .then(function (instance3) {
        LiquidStakingInstance = instance3;
        console.log("LiquidStaking deployed: ", instance3.address);
        return UTokensInstance.setSTokenContractAddress(STokensInstance.address, {
          from: accounts[0],
          gasPrice: gasPriceGanache,
          gas: gasLimitGanache,
        });
      })
      .then(function (txReceipt) {
        console.log("setSTokenContractAddress() set for UTokens contract.");
        return UTokensInstance.setLiquidStakingContractAddress(
          LiquidStakingInstance.address,
          {
            from: accounts[0],
            gasPrice: gasPriceGanache,
            gas: gasLimitGanache,
          }
        );
      })
      .then(function (txReceipt) {
        console.log(
          "setLiquidStakingContractAddress() set for UTokens contract."
        );
        console.log("ALL DONE.");
      })
      .catch(function (e) {
        console.error(e);
      });
  }

  if (network === "ropsten") {
    let gasPriceRopsten = 3e10;
    let gasLimitRopsten = 400000;
    console.log("Accounts: ", accounts);
    deployer
      .deploy(UTokensArtifact, {
        from: accounts[0],
        gasPrice: gasPriceRopsten,
        gas: gasLimitRopsten,
      })
      .then(function (instance) {
        UTokensInstance = instance;
        console.log("UTokens deployed: ", instance.address);
        return deployer.deploy(STokensArtifact, UTokensInstance.address, {
          from: accounts[0],
          gasPrice: gasPriceRopsten,
          gas: gasLimitRopsten,
        });
      })
      .then(function (instance2) {
        STokensInstance = instance2;
        console.log("STokens deployed: ", instance2.address);
        return deployer.deploy(
          LiquidStakingArtifact,
          UTokensInstance.address,
          STokensInstance.address,
          {
            from: accounts[0],
            gasPrice: gasPriceGanache,
            gas: gasLimitGanache,
          }
        );
      })
      .then(function (instance3) {
        LiquidStakingInstance = instance3;
        console.log("LiquidStaking deployed: ", instance3.address);
        return UTokens.setSTokenContractAddress(STokensInstance.address, {
          from: accounts[0],
          gasPrice: gasPriceGanache,
          gas: gasLimitGanache,
        });
      })
      .then(function (instance3) {
        console.log("setSTokenContractAddress() set for UTokens contract.");
        return UTokens.setLiquidStakingContractAddress(
          LiquidStakingInstance.address,
          {
            from: accounts[0],
            gasPrice: gasPriceGanache,
            gas: gasLimitGanache,
          }
        );
      })
      .then(function (instance3) {
        console.log(
          "setLiquidStakingContractAddress() set for UTokens contract."
        );
        console.log("ALL DONE.");
      })
      .catch(function (e) {
        console.error(e);
      });
  }
};
