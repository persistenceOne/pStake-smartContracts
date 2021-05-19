/* eslint-disable no-loop-func */
/* eslint-disable no-await-in-loop */
/* eslint-disable no-var */
/* eslint-disable func-names */
/* eslint-disable no-console */
// require statements for importing packages & global constants
const Web3 = require("web3");
const fs = require("fs");
// const Tx = require("ethereumjs-tx").Transaction;
const axios = require("axios");
const path = require("path");
/*const tendermintModule = require("./tendermintModule");
const config = require("../configuration/config.json");*/

const HDWallet = require('ethereum-hdwallet')
const mnemonic = "baby year rocket october what surprise lab bag report swap game unveil"; // 12 word mnemonic

const pBridgeTestData = require("./pBridgeTestData")

const LiquidStakingArtifact = artifacts.require("LiquidStaking");
const TokenWrapperArtifact = artifacts.require("TokenWrapper");
const STokensArtifact = artifacts.require("STokens");

var web3Provider;
var adminAccount;
var bridgeAdminAccount;

const hdwallet = HDWallet.fromMnemonic(mnemonic)
const signedRawTx = hdwallet.derive(`m/44'/60'/0'/0/0`).signTransaction({
    to: '0x0000000000000000000000000000000000000000',
    value: '0x0',
    data: '0x0'
})

console.log(`0x${signedRawTx.toString('hex')}`)

const DEFAULTGASPRICE = "50000000000";
const DEFAULTGASPRICEGWEI = 50;
const DEFAULTGASLIMIT = "400000";

async function initialize(){
    let TokenWrapperInstance = await TokenWrapperArtifact.deployed();
    bridgeAdminAccount = await initializeKeystoreJSON(
        "../keys/bridgeAdminKeystore.json",
        "password"
    );
    console.log("bridgeAdminAccount: ", bridgeAdminAccount)
    const txData = await TokenWrapperInstance.methods
        .generateUTokens("0x609d344A04245104C312925D2F5aE04F643A10CB", "1000000000")
        .encodeABI();
    console.log("txData: ", txData)
    await createAndSendEthTx(
        bridgeAdminAccount,
        TokenWrapperInstance,
        txData,
        DEFAULTGASLIMIT
    );
}

// SETUP WEB3 PROVIDERS

async function initializeWeb3(selectedURL) {
    console.log("INSIDE initializeWeb3()");
    // const selectedURL = config.selected.ethereumNodeURL;
    let web3Obj;
    let web3ProviderObj;
    const web3Options = {
        transactionConfirmationBlocks: 1,
        transactionPollingTimeout: 600,
    };

    // switch statement probably not required
    switch (selectedURL) {
        case "ROPSTEN_URL":
            web3ProviderObj = new Web3.providers.HttpProvider(
                config.ethereumNode[config.selected.ethereumNodeURL]
            );
            web3Obj = new Web3(web3ProviderObj, null, web3Options);
            break;

        case "ROPSTEN_WSS_URL":
            web3ProviderObj = new Web3.providers.WebsocketProvider(
                config.ethereumNode[config.selected.ethereumNodeURL]
            );
            web3Obj = new Web3(web3ProviderObj, null, web3Options);
            break;

        case "MAINNET_URL":
            web3ProviderObj = new Web3.providers.HttpProvider(
                config.ethereumNode[config.selected.ethereumNodeURL]
            );
            web3Obj = new Web3(web3ProviderObj, null, web3Options);
            break;

        case "MAINNET_WSS_URL":
            web3ProviderObj = new Web3.providers.WebsocketProvider(
                config.ethereumNode[config.selected.ethereumNodeURL]
            );
            web3Obj = new Web3(web3ProviderObj, null, web3Options);
            break;

        case "DEVNET_URL":
            web3ProviderObj = new Web3.providers.HttpProvider(
                config.ethereumNode[config.selected.ethereumNodeURL]
            );
            web3Obj = new Web3(web3ProviderObj, null, web3Options);
            break;

        case "DEVNET_WSS_URL":
            web3ProviderObj = new Web3.providers.WebsocketProvider(
                config.ethereumNode[config.selected.ethereumNodeURL]
            );
            web3Obj = new Web3(web3ProviderObj, null, web3Options);
            console.log(
                "web3Obj obtained: ",
                config.ethereumNode[config.selected.ethereumNodeURL]
            );
            break;

        case "GOERLI_URL":
            web3ProviderObj = new Web3.providers.HttpProvider(
                config.ethereumNode[config.selected.ethereumNodeURL]
            );
            web3Obj = new Web3(web3ProviderObj, null, web3Options);
            break;

        case "GOERLI_WSS_URL":
            web3ProviderObj = new Web3.providers.WebsocketProvider(
                config.ethereumNode[config.selected.ethereumNodeURL]
            );
            web3Obj = new Web3(web3ProviderObj, null, web3Options);
            console.log(
                "web3Obj obtained: ",
                config.ethereumNode[config.selected.ethereumNodeURL]
            );
            break;
        case "GETH_URL":
            web3ProviderObj = new Web3.providers.HttpProvider(
                config.ethereumNode[config.selected.ethereumNodeURL]
            );
            web3Obj = new Web3(web3ProviderObj, null, web3Options);
            break;

        case "GETH_WSS_URL":
            web3ProviderObj = new Web3.providers.WebsocketProvider(
                config.ethereumNode[config.selected.ethereumNodeURL]
            );
            web3Obj = new Web3(web3ProviderObj, null, web3Options);
            console.log(
                "web3Obj obtained: ",
                config.ethereumNode[config.selected.ethereumNodeURL]
            );
            break;

        default:
            console.log("web3 provider url not found. Defaulting to DEVURL");
            web3ProviderObj = new Web3.providers.HttpProvider(
                config.ethereumNode[config.selected.ethereumNodeURL]
            );
            web3Obj = new Web3(web3ProviderObj, null, web3Options);
            break;
    }
    return web3Obj;
}

// READ THE ADMIN KEYSTORE JSON FOR CONTRACTS

async function initializeKeystoreJSON(keystorePath, passPhrase) {
    console.log("INSIDE initializeKeystoreJSON()");

    const keystoreJSON = fs.readFileSync(
        path.join(__dirname, keystorePath),
        "utf8"
    );
    // decrypt accout using keystore
    const keystore = JSON.parse(keystoreJSON);
    console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "keystore: ",
        keystore.id
    );
    const account = web3.eth.accounts.decrypt(keystore, passPhrase);
    console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "account address: ",
        account.address
    );
    return account;
}

// READ THE CONTRACT ARTIFACT JSON FOR CONTRACTS

/*async function initializeContract(artifactPath, adminAddress, gasPrice) {
    console.log("INSIDE initializeContract()");

    // const networkID = config.NETWORKID;
    const networkID = await web3.eth.net.getId();
    console.log("web3 networkID: ", networkID);

    const artifactJSON = await fs.readFileSync(
        path.join(__dirname, artifactPath),
        "utf8"
    );
    const artifact = JSON.parse(artifactJSON);
    console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "artifact contract name: ",
        artifact.contractName
    );
    // get the contract abi
    const contractABI = artifact.abi;
    // Networks: mainnet - 1 , ropsten - 3
    const contractAddress = artifact.networks[networkID].address;
    console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "contract address: ",
        contractAddress
    );
    const contract = await new web3.eth.Contract(contractABI, contractAddress, {
        defaultAccount: adminAddress, // default from address
        defaultGasPrice: gasPrice, // default gas price in wei, 50 gwei in this case
    });
    // ## set the provider again because there seems to be a bug in setting currentprovider
    contract.setProvider(web3.currentProvider);
    console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "contract addr: ",
        contract.options.address
    );
    console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "contract currentProvider host: ",
        contract.currentProvider.url
    );
    console.log(
        "\n",
        "####################################################################################",
        "\n"
    );

    return contract;
}*/

// DEFINE EVENT SUBSCRIPTION WHICH WILL ACT AS WATCHOBJECTS

async function initializeWatches() {
    console.log("INSIDE initializeWatches()");
    const blockchainLocal = "cosmos";
    const { chains } = config.selected;

    // Event CalculateRewards of LiquidStaking for rewards generation (mint await uTokens)
    await STokensContract.events
        .TriggeredCalculateRewards()
        .on("connected", function (subscriptionId) {
            console.log(
                "Event CalculateRewards connected. Subscription ID: ",
                subscriptionId
            );
        })
        .on("data", function (event) {
            // prompt a console log with txHash
            console.log("\n", "Event CalculateRewards Received.");

            // parse the event object for data
            const toAddress = event.returnValues.accountAddress.toString();
            const amount = event.returnValues.tokens.toString();
            const { logIndex } = event;
            const { transactionHash } = event;
            console.log(
                "toAddress: ",
                toAddress,
                " amount: ",
                amount,
                " logIndex: ",
                logIndex,
                " transactionHash: ",
                transactionHash
            );

            // store the parsed data into a db?
            // xxx
            // xxx

            // generate a GETREWARDS transaction to send ATOMS to staker's ATOM wallet address
            tendermintModule.createAndSendTendermintTx(
                blockchainLocal,
                "GETREWARDS",
                config.pStakeAddress[blockchainLocal],
                config.validators[blockchainLocal],
                amount,
                toAddress
            );
        })
        .on("changed", function (event) {
            // remove event from local database
            console.log(
                "Event CalculateRewards Changed. Removing from local database ... : ",
                event
            );
        })
        .on("error", function (error, receipt) {
            // If the transaction was rejected by the network with a receipt,
            // the second parameter will be the receipt.
            console.log(
                "Event CalculateRewards Threw Error. Error: ",
                error,
                " ReceiptID: ",
                receipt
            );
        });
    // END Event

    // Event CalculateRewards of LiquidStaking for rewards generation (mint await uTokens)
    await TokenWrapperContract.events
        .WithdrawUTokens()
        .on("connected", function (subscriptionId) {
            console.log(
                "Event WithdrawUTokens connected. Subscription ID: ",
                subscriptionId
            );
        })
        .on("data", function (event) {
            // prompt a console log with txHash
            console.log(
                "\n",

                "Event WithdrawUTokens Received."
            );

            // parse the event object for data
            const fromAddress = event.returnValues.accountAddress.toString();
            const tokens = event.returnValues.tokens.toString();
            const toAtomAddressBytes32 = web3.utils.toHex(
                event.returnValues.toAtomAddress
            );
            const toAtomAddress = web3.utils.hexToUtf8(toAtomAddressBytes32);
            const { logIndex } = event;
            const { transactionHash } = event;
            console.log(
                "blockchain: ",
                blockchainLocal,
                "fromAddress: ",
                fromAddress,
                " tokens: ",
                tokens,
                " toAtomAddress: ",
                toAtomAddress,
                " logIndex: ",
                logIndex,
                " transactionHash: ",
                transactionHash
            );

            // store the parsed data into a db?
            // xxx
            // xxx

            // generate a SENDCOIN transaction to send ATOMS to staker's ATOM wallet address
            tendermintModule.createAndSendTendermintTx(
                blockchainLocal,
                "SENDCOIN",
                config.pStakeAddress.cosmos,
                toAtomAddress,
                tokens,
                fromAddress
            );
        })
        .on("changed", function (event) {
            // remove event from local database
            console.log(
                "Event WithdrawUTokens Changed. Removing from local database ... : ",
                event
            );
        })
        .on("error", function (error, receipt) {
            // If the transaction was rejected by the network with a receipt,
            // the second parameter will be the receipt.
            console.log(
                "Event WithdrawUTokens Threw Error. Error: ",
                error,
                " ReceiptID: ",
                receipt
            );
        });
    // END Event


    // Event StakeTokens of LiquidStaking for unpegging of tokens (burn uTokens)
    await LiquidStakingContract.events
        .StakeTokens()
        .on("connected", function (subscriptionId) {
            console.log(
                "Event StakeTokens connected. Subscription ID: ",
                subscriptionId
            );
        })
        .on("data", function (event) {
            // prompt a console log with txHash
            console.log(
                "\n",

                "Event StakeTokens Received."
            );

            // parse the event object for data
            const stakerAddress = event.returnValues.accountAddress.toString();
            const tokens = event.returnValues.tokens.toString();
            const { logIndex } = event;
            const { transactionHash } = event;
            console.log(
                "stakerAddress: ",
                stakerAddress,
                " tokens: ",
                tokens,
                " logIndex: ",
                logIndex,
                " transactionHash: ",
                transactionHash
            );

            // store the parsed data into a db?
            // xxx
            // xxx

            // generate a DELEGATE transaction to send ATOMS to staker's ATOM wallet address
            tendermintModule.createAndSendTendermintTx(
                blockchainLocal,
                "DELEGATE",
                config.pStakeAddress[blockchainLocal],
                config.validators[blockchainLocal],
                tokens,
                stakerAddress
            );
        })
        .on("changed", function (event) {
            // remove event from local database
            console.log(
                "Event StakeTokens Changed. Removing from local database ... : ",
                event
            );
        })
        .on("error", function (error, receipt) {
            // If the transaction was rejected by the network with a receipt,
            // the second parameter will be the receipt.
            console.log(
                "Event StakeTokens Threw Error. Error: ",
                error,
                " ReceiptID: ",
                receipt
            );
        });
    // END Event

    // Event UnstakeTokens of LiquidStaking for unpegging of tokens (burn uTokens)
    await LiquidStakingContract.events
        .UnstakeTokens()
        .on("connected", function (subscriptionId) {
            console.log(
                "Event UnstakeTokens connected. Subscription ID: ",
                subscriptionId
            );
        })
        .on("data", function (event) {
            // prompt a console log with txHash
            console.log(
                "\n",

                "Event UnstakeTokens Received."
            );

            // parse the event object for data
            const stakerAddress = event.returnValues.accountAddress.toString();
            const tokens = event.returnValues.tokens.toString();
            const { logIndex } = event;
            const { transactionHash } = event;
            console.log(
                "stakerAddress: ",
                stakerAddress,
                " tokens: ",
                tokens,
                " logIndex: ",
                logIndex,
                " transactionHash: ",
                transactionHash
            );

            // store the parsed data into a db?
            // xxx
            // xxx

            // generate a UNDELEGATE transaction to send ATOMS to staker's ATOM wallet address
            tendermintModule.createAndSendTendermintTx(
                blockchainLocal,
                "UNDELEGATE",
                config.pStakeAddress[blockchainLocal],
                config.validators[blockchainLocal],
                tokens,
                stakerAddress
            );
        })
        .on("changed", function (event) {
            // remove event from local database
            console.log(
                "Event UnstakeTokens Changed. Removing from local database.. : ",
                event
            );
        })
        .on("error", function (error, receipt) {
            // If the transaction was rejected by the network with a receipt,
            // the second parameter will be the receipt.
            console.log(
                "Event UnstakeTokens Threw Error. Error: ",
                error,
                " ReceiptID: ",
                receipt
            );
        });
    // END Event
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

/*
async function initializeEthBridge() {
    console.log("INSIDE initializeEthBridge()");
    const { chains } = config.selected;

    // initialize web3
    web3 = await initializeWeb3(config.selected.ethereumNodeURL);
    web3Provider = web3.currentProvider;
    console.log("web3Provider URL: ", web3Provider.url);
    // console.log("web3: ", web3);

    // initialize Keystore
    adminAccount = await initializeKeystoreJSON(
        "../keys/adminKeystore.json",
        "LiquidStakingAdmin"
    );

    bridgeAdminAccount = await initializeKeystoreJSON(
        "../keys/bridgeAdminKeystore.json",
        "password"
    );

    // initialize Contracts
    LiquidStakingContract = await initializeContract(
        "../build/LiquidStaking.json",
        adminAccount.address,
        DEFAULTGASPRICE
    );
    LiquidStakingContract.setProvider(web3.currentProvider);

    // initialize all instances of TokenWrapper pertaining to all selected chains
    /!* for (let index = 0; index < chains.length; index++) {
      TokenWrapperContract[chains[index]] = await initializeContract(
        `../build/TokenWrapper[${config.token[chains[index]]}].json`,
        adminAccount.address,
        DEFAULTGASPRICE
      );
      TokenWrapperContract[chains[index]].setProvider(web3.currentProvider);
    } *!/

    TokenWrapperContract = await initializeContract(
        "../build/TokenWrapper.json",
        adminAccount.address,
        DEFAULTGASPRICE
    );
    TokenWrapperContract.setProvider(web3.currentProvider);

    TokenWrapperContractXPRT = await initializeContract(
        "../build/TokenWrapperXPRT.json",
        adminAccount.address,
        DEFAULTGASPRICE
    );
    TokenWrapperContractXPRT.setProvider(web3.currentProvider);

    STokensContract = await initializeContract(
        "../build/STokens.json",
        adminAccount.address,
        DEFAULTGASPRICE
    );
    STokensContract.setProvider(web3.currentProvider);

    // initialize the event emitter watches for Eth
    initializeWatches();
}
*/

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
        contract.address,
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
        to: contract.address,
        data: txData,
        // EIP 155 chainId - mainnet: 1, ropsten: 3
        chainId,
    };
    console.log("rawTx: ", rawTx);

    /* // SIGN THE RAWTX, AND THEN SERIALIZE, USING ETHEREUMJS-TX
    const tx = new Tx(rawTx, { chain: config.SELECTEDCHAIN });
    // get the private key
    const LiquidStakingAdminPvtKey = Buffer.from(
      account.privateKey.slice(2),
      "hex"
    );
    // Sign the transaction and send it
    tx.sign(LiquidStakingAdminPvtKey);
    const serializedTx = tx.serialize();
    const signedTx = `0x${serializedTx.toString("hex")}`; */

    /* // SIGN & SERIALIZE TOGETHER USING WEB3 API & UNLOCKED ACCOUNT
    const signedTx = await web3.eth.signTransaction(rawTx, rawTx.from); */

    // [RECOMMENDED] SIGN & SERIALIZE TOGETHER USING WEB3 API & LOCKED ACCOUNT
    const signedTxObj = await web3.eth.accounts.signTransaction(
        rawTx,
        account.privateKey
    );
    const signedTx = signedTxObj.rawTransaction;
    // console.log("\n", "signedTxObj: ", signedTxObj, "\n");
    // console.log("privatekey: ", account.privateKey);

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

// TARGET - FUNCTION TO INITIATE ETHEREUM TRANSACTION
// the amount need not be converted to its decimal places...
async function generatePegTokens(blockchain, ethAddress, amount) {
    console.log(
        "[",
        new Date().toLocaleString(),
        "] : ",
        "inside generatePegTokens(): ",
        "blockchain: ",
        blockchain,
        "ethAddress: ",
        ethAddress,
        "\n",
        " amount: ",
        amount,
        "\n"
    );
    const defaultGasLimit = DEFAULTGASLIMIT;
    const amountBN = await web3.utils.toBN(amount.toString());

    // get the contract artifact object as per the chain. This should be replaced
    // later with TokenWrapperContract{} object
    let TokenWrapperContractLocal =
        blockchain == "cosmos" ? TokenWrapperContract : TokenWrapperContractXPRT;

    console.log("contract address: ", TokenWrapperContractLocal.address);

    const txData = await TokenWrapperContractLocal.methods
        .generateUTokens(ethAddress.toString(), amountBN)
        .encodeABI();
    await createAndSendEthTx(
        bridgeAdminAccount,
        TokenWrapperContractLocal,
        txData,
        defaultGasLimit
    );
}

// generatePegTokens("0xa69dE4538Fd5384FfB4e415B861dBc7eAED75dF2", "200000000");
initialize().then(r => console.log("response from initialize: ", r));

module.exports = {
   // generatePegTokens,
   // getGasPrice,
  //  createAndSendEthTx,
   // initializeEthBridge,
};
