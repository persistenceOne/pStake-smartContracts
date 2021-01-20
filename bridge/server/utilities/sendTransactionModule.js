// require statements for importing packages & global constants
const Web3 = require("web3");
var fs = require("fs");
const Tx = require("ethereumjs-tx");
const fetch = require("node-fetch");
const DEFAULTGASPRICE = "5000000000";

// ------------------------------------------------------------
// SETUP INFURA NODE AND WEB3 PROVIDERS
const INFURA_API_KEY = "0068ceedf8634c4bde443a0ce6f4bcd3";
const provider_ropsten = new Web3.providers.HttpProvider(
  "https://ropsten.infura.io/v3/" + INFURA_API_KEY
);
const provider_mainnet = new Web3.providers.HttpProvider(
  "https://mainnet.infura.io/v3/" + INFURA_API_KEY
);
const web3Options_mainnet = {
  transactionConfirmationBlocks: 1,
  transactionPollingTimeout: 600,
};
const web3Options_ropsten = {
  transactionConfirmationBlocks: 1,
  transactionPollingTimeout: 600,
};
const web3_mainnet = new Web3(provider_mainnet, null, web3Options_mainnet);
const web3_ropsten = new Web3(provider_ropsten, null, web3Options_ropsten);

// ------------------------------------------------------------
// READ THE ADMIN KEYSTORE JSON (ROPSTEN) FOR UTOKENS CONTRACT
var keystoreData_ropsten = fs.readFileSync("keystoreRopsten.json", "utf8");
// decrypt accout using keystore_ropsten
const keystore_ropsten = JSON.parse(keystoreData_ropsten);
const account_ropsten = web3_ropsten.eth.accounts.decrypt(
  keystore_ropsten,
  "r0p5t3n33"
);
console.log(
  "[",
  new Date().toLocaleString(),
  "] : ",
  "account_ropsten addr: ",
  account_ropsten.address
);
//console.log("pvtkey: ", account_ropsten.privateKey_ropsten);
const privateKey_ropsten = new Buffer.from(
  account_ropsten.privateKey.slice(2),
  "hex"
);
//console.log("pvt key buffer:: ", privateKey_ropsten);
console.log("[", new Date().toLocaleString(), "] : ", "...");
console.log("[", new Date().toLocaleString(), "] : ", "...");

// ------------------------------------------------------------
// READ THE CONTRACT ARTIFACT JSON
var artifactData_ropsten = fs.readFileSync("UTokensRopsten.json", "utf8");
// get the artifact object
var artifact_ropsten = JSON.parse(artifactData_ropsten);
// get the contract abi
var abi_ropsten = artifact_ropsten.abi;
// Networks: mainnet - 1 , ropsten - 3
var contractAddress_ropsten = artifact_ropsten.networks["3"].address;
//console.log("[", (new Date()).toLocaleString(), "] : ", "artifact_ropsten address: ", contractAddress_ropsten);
const contract_ropsten = new web3_ropsten.eth.Contract(
  abi_ropsten,
  contractAddress_ropsten,
  {
    defaultAccount: account_ropsten.address, // default from address
    defaultGasPrice: DEFAULTGASPRICE, // default gas price in wei, 5 gwei in this case
  }
);
// set the provider again because there seems to be a bug in setting currentprovider
contract_ropsten.setProvider(provider_ropsten || web3_ropsten.currentProvider);
console.log(
  "[",
  new Date().toLocaleString(),
  "] : ",
  "contract_ropsten addr: ",
  contract_ropsten.address
);
console.log(
  "[",
  new Date().toLocaleString(),
  "] : ",
  "contract_ropsten currentProvider: ",
  contract_ropsten.currentProvider.host
);
console.log("[", new Date().toLocaleString(), "] : ", "...");
console.log("[", new Date().toLocaleString(), "] : ", "...");
console.log("  ");
console.log("  ");
console.log(
  "####################################################################################"
);
console.log("  ");
console.log("  ");

// ------------------------------------------------------------
// TARGET - FUNCTION TO INITIATE ETHEREUM TRANSACTION
async function sendPeggedTokens(ethAddress, amount) {
  const defaultGasLimit = "200000";
  txData_ropsten = await contract_ropsten.methods
    .mint(ethAddress, amount)
    .encodeABI();
  await createAndSendTxn(
    account_ropsten,
    contract_ropsten,
    txData_ropsten,
    defaultGasLimit
  );
}

// ------------------------------------------------------------
// FUNCTION TO CREATE AND SEND TRANSACTION
async function createAndSendTxn(
  account_ropsten,
  contract_ropsten,
  txData_ropsten,
  defaultGasLimit
) {
  // GET GAS PRICE DYNAMICALLY
  const defaultGasPrice = "5000000000";
  let finalGasPrice = (await getGasPrice()) || defaultGasPrice;

  // CREATE A RAW TRANSACTION
  var transactionCount_ropsten = await web3_ropsten.eth.getTransactionCount(
    account_ropsten.address
  );
  rawTx_ropsten = {
    nonce: transactionCount_ropsten,
    gasPrice: web3_ropsten.utils.toHex(finalGasPrice),
    gasLimit: web3_ropsten.utils.toHex(defaultGasLimit),
    from: account_ropsten.address.toString(),
    to: contract_ropsten.address,
    data: txData_ropsten,
    // EIP 155 chainId - mainnet: 1, ropsten: 3
    chainId: 3, //# change for mainnet
  };
  tx_ropsten = new Tx(rawTx_ropsten);

  // Sign the transaction and send it
  tx_ropsten.sign(privateKey_ropsten);
  serializedTx_ropsten = tx_ropsten.serialize();
  web3_ropsten.eth
    .sendSignedTransaction("0x" + serializedTx_ropsten.toString("hex"))
    .on("transactionHash", (hash) => {
      console.log("[", new Date().toLocaleString(), "] : ", "...");
      console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "ON transactionHash:",
        hash
      );
      console.log("[", new Date().toLocaleString(), "] : ", "...");
    })
    .on("confirmation", (confirmationNumber, receipt) => {
      console.log("[", new Date().toLocaleString(), "] : ", "...");
      console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "-- ropsten contract method --"
      );
      console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "ON confirmation:",
        confirmationNumber
      );
      console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "gas used: ",
        receipt && receipt.gasUsed
      );
      console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "status: ",
        receipt && receipt.status
      );
      console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "-- ropsten contract method --"
      );
      console.log("[", new Date().toLocaleString(), "] : ", "...");
    })
    .on("receipt", (receipt) => {
      console.log("[", new Date().toLocaleString(), "] : ", "...");
      console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "-- ropsten contract method --"
      );
      console.log("[", new Date().toLocaleString(), "] : ", "ON receipt:");
      console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "gas used: ",
        receipt && receipt.gasUsed
      );
      console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "status: ",
        receipt && receipt.status
      );
      console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "-- ropsten contract method --"
      );
      console.log("[", new Date().toLocaleString(), "] : ", "...");
    })
    .on("error", (err) => {
      console.log("[", new Date().toLocaleString(), "] : ", "...");
      console.error("[", new Date().toLocaleString(), "] : ", "ON error:", err);
      console.log("[", new Date().toLocaleString(), "] : ", "...");
    });
}

// ------------------------------------------------------------
// FUNCTION TO GET GAS PRICE DYNAMICALLY USING ETHGASSTATION API
async function getGasPrice() {
  // GAS PARAMETERS FOR TRANSACTION
  const ethGasPriceURL = "https://ethgasstation.info/json/ethgasAPI.json";
  const defaultGasPrice = DEFAULTGASPRICE;
  var fastGasPrice = 50;
  var avgGasPrice = 50;
  var safeLowGasPrice = 50;
  var calculatedGasPrice = "50000000000";

  // get gas price dynamically using ethgasstation.info api
  try {
    let response = await fetch(ethGasPriceURL);
    let ethGasPriceJSON = await response.json();
    if (ethGasPriceJSON) {
      fastGasPrice = ethGasPriceJSON.fast / 10;
      avgGasPrice = ethGasPriceJSON.average / 10;
      safeLowGasPrice = ethGasPriceJSON.safeLow / 10;
      if (!isNaN(fastGasPrice) && !isNaN(avgGasPrice)) {
        if (avgGasPrice >= defaultGasPrice) {
          calculatedGasPrice = (avgGasPrice * 1e9).toString();
        } else {
          if (fastGasPrice <= defaultGasPrice) {
            calculatedGasPrice = (defaultGasPrice * 1e9).toString();
          } else {
            calculatedGasPrice = (defaultGasPrice * 1e9).toString();
          }
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

module.exports = {
  sendPeggedTokens,
  getGasPrice,
  createAndSendTxn,
};
