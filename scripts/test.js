/* eslint-disable no-loop-func */
/* eslint-disable no-await-in-loop */
/* eslint-disable no-var */
/* eslint-disable func-names */
/* eslint-disable no-console */
// require statements for importing packages & global constants
//const Web3 = require("web3");

/* [ '0x466aF9ea44f2dEbbE4fd54a98CffA26A3674fBf7',
    '0x51caF3f0E53BAAF12F8B0B6d98350CBA53e8DB7B',
    '0xCC6F6821F903b1FC3C0c9597b26C84E31AC98B36',
    '0xa69dE4538Fd5384FfB4e415B861dBc7eAED75dF2',
    '0x609d344A04245104C312925D2F5aE04F643A10CB',
    '0x7019943Ca5E81d10EFA8ACdd68B0B67Eb4B0a9f6',
    '0x768D4C50C9D4Db6f12Bb47581E4c1823Ad9eCB49',
    '0xe3355d5AD5f8dCdca879230e85eF0AaeE6f28d0B',
    '0x528B19d24426C4A78D0fDC0933c3F91C87102adA',
    '0x3F5fdb1c4B40b04f54082482DCBF9732c1199eB6' ] */

// const HDWallet = require("ethereum-hdwallet");
const HDWalletProvider = require("@truffle/hdwallet-provider");

const mnemonic =
  "baby year rocket october what surprise lab bag report swap game unveil"; // 12 word mnemonic

const lqABI = require("../build/contracts/LiquidStaking.json");
const twABI = require("../build/contracts/TokenWrapper.json");
const stABI = require("../build/contracts/STokens.json");

const LiquidStakingArtifact = artifacts.require("LiquidStaking");
const TokenWrapperArtifact = artifacts.require("TokenWrapper");
const STokensArtifact = artifacts.require("STokens");

const testData = require("./pBridgeTestData");

const LiquidStakingInstance = new web3.eth.Contract(
  JSON.parse(JSON.stringify(lqABI.abi)),
  LiquidStakingArtifact.address
);
const TokenWrapperInstance = new web3.eth.Contract(
  JSON.parse(JSON.stringify(twABI.abi)),
  TokenWrapperArtifact.address
);
const STokensInstance = new web3.eth.Contract(
  JSON.parse(JSON.stringify(stABI.abi)),
  STokensArtifact.address
);
// const hdwallet = HDWallet.fromMnemonic(mnemonic);

let action = "";
let amount = 0;
let user = "";
const DEFAULTGASPRICEGWEI = 50;
const DEFAULTGASLIMIT = "400000";
//var web3 = new Web3();

var bridgeAdminAccount = "0x9b3DefB46804BD74518A52dC0cf4FA7280E0B673";
var testAccounts = [
  "0x466aF9ea44f2dEbbE4fd54a98CffA26A3674fBf7",
  "0x51caF3f0E53BAAF12F8B0B6d98350CBA53e8DB7B",
  "0xCC6F6821F903b1FC3C0c9597b26C84E31AC98B36",
  "0xa69dE4538Fd5384FfB4e415B861dBc7eAED75dF2",
  "0x609d344A04245104C312925D2F5aE04F643A10CB",
  "0x7019943Ca5E81d10EFA8ACdd68B0B67Eb4B0a9f6",
  "0x768D4C50C9D4Db6f12Bb47581E4c1823Ad9eCB49",
  "0xe3355d5AD5f8dCdca879230e85eF0AaeE6f28d0B",
  "0x528B19d24426C4A78D0fDC0933c3F91C87102adA",
  "0x3F5fdb1c4B40b04f54082482DCBF9732c1199eB6",
];

async function iterate() {
  /*const LiquidStakingInstance = await LiquidStakingArtifact.deployed();
    const TokenWrapperInstance = await TokenWrapperArtifact.deployed();
    const STokensInstance = await STokensArtifact.deployed();*/

  const defaultGasLimit = DEFAULTGASLIMIT;
  action = testData.pBridgeTestData[32].action;
  user = testData.pBridgeTestData[32].user.toString();

  if (action === "calculateRewards") {
    console.log(
      "[",
      new Date().toLocaleString(),
      "] : ",
      "inside runTxs(): ",
      "\n",
      "accAddress: ",
      user,
      "\n",
      " actions: ",
      action,
      "\n"
    );

    try {
      const txReceipt = await STokensInstance.methods
        .calculateRewards(user)
        .send({
          from: user,
          chainId: 5,
        });
      console.log("txReceipt: ", txReceipt);
    } catch (error) {
      console.log("error: ", error);
    }

    for (let k = 32; k < testData.pBridgeTestData.length; k++) {
      /* action = testData.pBridgeTestData[k].action;
      user = testData.pBridgeTestData[k].user.toString(); */
      /*  if (action === "stake" || action === "unstake") {
      amount = await web3.utils.toBN(
        testData.pBridgeTestData[k].amount.toString()
      );
      // amount = testData.pBridgeTestData[k].amount.toString();
      if (action === "stake") {
        console.log(
          "[",
          new Date().toLocaleString(),
          "] : ",
          "inside runTxs(): ",
          "\n",
          "accAddress: ",
          user,
          "\n",
          " amount: ",
          amount,
          "\n",
          " actions: ",
          action,
          "\n"
        );

        const txData = await LiquidStakingInstance.methods
          .stake(user, amount)
          .encodeABI();

        console.log("txData: ", txData);
        const signedRawTx = hdwallet
          .derive(`m/44'/60'/0'/0/0`)
          .signTransaction({
            to: LiquidStakingArtifact.address,
            value: "0x0",
            data: txData,
          });

        console.log(`0x${signedRawTx.toString("hex")}`);
        console.log("sign: ", sign);
      } else {
        console.log(
          "[",
          new Date().toLocaleString(),
          "] : ",
          "inside runTxs(): ",
          "\n",
          "accAddress: ",
          user,
          "\n",
          " amount: ",
          amount,
          "\n",
          " actions: ",
          action,
          "\n"
        );
        const txData = await LiquidStakingInstance.methods
          .unstake(user, amount)
          .encodeABI();
        const signedRawTx = hdwallet
          .derive(`m/44'/60'/0'/0/0`)
          .signTransaction({
            to: LiquidStakingArtifact.address,
            value: "0x0",
            data: txData,
          });

        console.log(`0x${signedRawTx.toString("hex")}`);
      }
    } else if (action === "withdrawUTokens") {
      amount = await web3.utils.toBN(
        testData.pBridgeTestData[k].amount.toString()
      );
      console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "inside runTxs(): ",
        "\n",
        "accAddress: ",
        user,
        "\n",
        " amount: ",
        amount,
        "\n",
        " actions: ",
        action,
        "\n"
      );
      const txData = await TokenWrapperInstance.methods
        .withdrawUTokens(user, amount, testData.pBridgeTestData[k].cosmosAddr)
        .encodeABI();
      const signedRawTx = hdwallet.derive(`m/44'/60'/0'/0/0`).signTransaction({
        to: TokenWrapperArtifact.address,
        value: "0x0",
        data: txData,
      });

      console.log(`0x${signedRawTx.toString("hex")}`);
    } */
      /*  if (action === "calculateRewards") {
      console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "inside runTxs(): ",
        "\n",
        "accAddress: ",
        user,
        "\n",
        " actions: ",
        action,
        "\n"
      );

      try {
        const txReceipt = await STokensInstance.methods
          .calculateRewards(user)
          .send({
            from: user,
            chainId: 5,
          });
        console.log("txReceipt: ", txReceipt);
      } catch (error) {
        console.log("error: ", error);
      } */
      /* const txData = await STokensInstance.methods
        .calculateRewards(testData.pBridgeTestData[k].user.toString())
        .encodeABI();

      console.log("encode ABI for calculateRewards: ", txData);
      const signedRawTx = await hdwallet
        .derive(`m/44'/60'/0'/0/0`)
        .signTransaction({
          from: testData.pBridgeTestData[k].user.toString(),
          to: STokensArtifact.address,
          value: "0x0",
          data: txData,
        });
      console.log(
        "signedRawTx for calculateRewards: ",
        `0x${signedRawTx.toString("hex")}`
      );
      let sendTx = await web3.eth.sendSignedTransaction(signedRawTx);
      console.log(
        "sendTx for calculateRewards: ",
        `0x${sendTx.toString("hex")}`
      ); */
    }
  }
}

// FUNCTION TO GET GAS PRICE DYNAMICALLY USING ETHGASSTATION API
async function getGasPrice() {
  console.log("INSIDE getGasPrice()");
  // GAS PARAMETERS FOR TRANSACTION
  const ethGasPriceURL = "https://ethgasstation.info/json/ethgasAPI.json";
  const defaultGasPrice = DEFAULTGASPRICEGWEI;
  let fastGasPrice = DEFAULTGASPRICEGWEI;
  let avgGasPrice = DEFAULTGASPRICEGWEI;
  let safeLowGasPrice = DEFAULTGASPRICEGWEI;
  let calculatedGasPrice = (DEFAULTGASPRICEGWEI * 1e9).toString();

  // get gas price dynamically using ethgasstation.info api
  try {
    // use fetch to get api data synchronously ?
    // let response = await fetch(ethGasPriceURL);
    // let ethGasPriceJSON = await response.json();

    // use axios to fetch api data
    const response = await axios.get(ethGasPriceURL);
    console.log("Axios Response Staus: ", response.status);
    const ethGasPriceJSON = response.data;

    if (ethGasPriceJSON) {
      fastGasPrice = ethGasPriceJSON.fast / 10;
      avgGasPrice = ethGasPriceJSON.average / 10;
      safeLowGasPrice = ethGasPriceJSON.safeLow / 10;
      if (!Number.isNaN(fastGasPrice) && !Number.isNaN(avgGasPrice)) {
        if (avgGasPrice >= defaultGasPrice) {
          calculatedGasPrice = (avgGasPrice * 1e9).toString();
        } else if (fastGasPrice <= defaultGasPrice) {
          calculatedGasPrice = (defaultGasPrice * 1e9).toString();
        } else {
          calculatedGasPrice = (defaultGasPrice * 1e9).toString();
        }
      } else {
        calculatedGasPrice = (defaultGasPrice * 1e9).toString();
      }
    } else {
      calculatedGasPrice = (defaultGasPrice * 1e9).toString();
    }
    console.log(
      "[",
      new Date().toLocaleString(),
      "] : ",
      "Fast Gas Price is: ",
      fastGasPrice,
      " GWei,  Wait Time: ",
      ethGasPriceJSON.fastWait,
      " mins"
    );
    console.log(
      "[",
      new Date().toLocaleString(),
      "] : ",
      "Average Gas Price is: ",
      avgGasPrice,
      " GWei,  Wait Time: ",
      ethGasPriceJSON.avgWait,
      " mins"
    );
    console.log(
      "[",
      new Date().toLocaleString(),
      "] : ",
      "safeLow Gas Price is: ",
      safeLowGasPrice,
      " GWei,  Wait Time: ",
      ethGasPriceJSON.safeLowWait,
      " mins"
    );
    console.log(
      "[",
      new Date().toLocaleString(),
      "] : ",
      "SELECTED Gas Price is: ",
      calculatedGasPrice / 1e9,
      " GWei"
    );
  } catch (errGas) {
    calculatedGasPrice = (defaultGasPrice * 1e9).toString();
    console.error("[", new Date().toLocaleString(), "] : ", "...");
    console.error(
      "[",
      new Date().toLocaleString(),
      "] : ",
      "Error in EthGasStation API: ",
      errGas.toString()
    );
    console.error(
      "[",
      new Date().toLocaleString(),
      "] : ",
      "Dynamic Gas Price set to: ",
      calculatedGasPrice
    );
    console.error("[", new Date().toLocaleString(), "] : ", "...");
  }
  return calculatedGasPrice;
}

// FUNCTION TO CREATE AND SEND TRANSACTION
async function createAndSendEthTx(account, contract, txData, defaultGasLimit) {
  console.log(
    "[",
    new Date().toLocaleString(),
    "] : ",
    "inside createAndSendEthTx(): ",
    "\n",
    "[",
    new Date().toLocaleString(),
    "] : ",
    "account: ",
    account.address,
    "\n",
    "[",
    new Date().toLocaleString(),
    "] : ",
    " contract: ",
    contract.options.address,
    "\n",
    "[",
    new Date().toLocaleString(),
    "] : ",
    " txData: ",
    txData,
    "\n",
    "[",
    new Date().toLocaleString(),
    "] : ",
    " defaultGasLimit: ",
    defaultGasLimit
  );
  // GET GAS PRICE DYNAMICALLY
  // const finalGasPrice = DEFAULTGASPRICE;
  const finalGasPrice = await getGasPrice();

  // CREATE A RAW TRANSACTION
  const transactionCount = await web3.eth.getTransactionCount(account.address);
  const chainId = await web3.eth.getChainId();
  const rawTx = {
    nonce: transactionCount,
    gasPrice: web3.utils.toHex(finalGasPrice),
    gasLimit: web3.utils.toHex(defaultGasLimit),
    from: account.address.toString(),
    to: contract.options.address,
    data: txData,
    // EIP 155 chainId - mainnet: 1, ropsten: 3
    chainId,
  };
  console.log("rawTx: ", rawTx);

  // [RECOMMENDED] SIGN & SERIALIZE TOGETHER USING WEB3 API & LOCKED ACCOUNT
  const signedTxObj = await web3.eth.accounts.signTransaction(
    rawTx,
    account.privateKey
  );
  const signedTx = signedTxObj.rawTransaction;

  web3.eth
    .sendSignedTransaction(signedTx)
    .on("transactionHash", (hash) => {
      console.log("\n", "--------------------------------");
      console.log("[", new Date().toLocaleString(), "] : ", "...");
      console.log("ON transactionHash:", hash);
      console.log("[", new Date().toLocaleString(), "] : ", "...");
    })
    .on("receipt", (receipt) => {
      console.log("\n", "--------------------------------");
      console.log("[", new Date().toLocaleString(), "] : ", "...");
      console.log("[", new Date().toLocaleString(), "] : ", "ON receipt:");
      console.log("tx Hash: ", receipt && receipt.transactionHash);
      console.log("Block Hash: ", receipt && receipt.blockHash);
      console.log("gas used: ", receipt && receipt.gasUsed);
      console.log("status: ", receipt && receipt.status);
      console.log("[", new Date().toLocaleString(), "] : ", "...");
    })
    .on("error", (err) => {
      console.log("\n", "--------------------------------");
      console.log("[", new Date().toLocaleString(), "] : ", "...");
      console.error("[", new Date().toLocaleString(), "] : ", "ON error:", err);
      console.log("[", new Date().toLocaleString(), "] : ", "...");
    });
  console.log("TRANSACTION SENT!");
}

module.exports = async function () {
  await iterate();
};
