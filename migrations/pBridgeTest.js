/* eslint-disable no-loop-func */
/* eslint-disable no-await-in-loop */
/* eslint-disable no-var */
/* eslint-disable func-names */
/* eslint-disable no-console */
// require statements for importing packages & global constants
//const Web3 = require("web3");

const lqABI = require("../build/contracts/LiquidStaking.json");
const twABI = require("../build/contracts/TokenWrapper.json");
const stABI = require("../build/contracts/STokens.json");

const LiquidStakingArtifact = artifacts.require("LiquidStaking");
const TokenWrapperArtifact = artifacts.require("TokenWrapper");
const STokensArtifact = artifacts.require("STokens");

const testData = require("./pBridgeTestData");

const LiquidStakingInstance = new web3.eth.Contract(JSON.parse(JSON.stringify(lqABI.abi)), LiquidStakingArtifact.address);
const TokenWrapperInstance = new web3.eth.Contract(JSON.parse(JSON.stringify(twABI.abi)), TokenWrapperArtifact.address);
const STokensInstance = new web3.eth.Contract(JSON.parse(JSON.stringify(stABI.abi)), STokensArtifact.address);


let action = "";
let amount = 0;
const DEFAULTGASPRICEGWEI = 50;
const DEFAULTGASLIMIT = "400000";
//var web3 = new Web3();

var bridgeAdminAccount = "0x9b3DefB46804BD74518A52dC0cf4FA7280E0B673";

async function iterate(){
    const defaultGasLimit = DEFAULTGASLIMIT;
    for(let k = 0; k<testData.pBridgeTestData.length; k++){
        action = testData.pBridgeTestData[k].action;
        if(action === "stake" || action === "unstake"){
            amount = await web3.utils.toBN(testData.pBridgeTestData[k].amount.toString());
           // amount = testData.pBridgeTestData[k].amount.toString();
            if(action === "stake"){
                console.log(
                    "[",
                    new Date().toLocaleString(),
                    "] : ",
                    "inside runTxs(): ",
                    "\n",
                    "accAddress: ",
                    testData.pBridgeTestData[k].user.toString(),
                    "\n",
                    " amount: ",
                    amount,
                    "\n",
                    " actions: ",
                    action,
                    "\n"
                );

                const txData = await LiquidStakingInstance.methods
                    .stake(testData.pBridgeTestData[k].user.toString(), amount)
                    .encodeABI();
                console.log("txData: ", txData)
                let sign = await createAndSendEthTx(
                    bridgeAdminAccount,
                    LiquidStakingArtifact,
                    txData,
                    defaultGasLimit
                );
                console.log("sign: ", sign)
            }else{
                console.log(
                    "[",
                    new Date().toLocaleString(),
                    "] : ",
                    "inside runTxs(): ",
                    "\n",
                    "accAddress: ",
                    testData.pBridgeTestData[k].user.toString(),
                    "\n",
                    " amount: ",
                    amount,
                    "\n",
                    " actions: ",
                    action,
                    "\n"
                );
                const txData = await LiquidStakingInstance.methods
                    .unstake(testData.pBridgeTestData[k].user.toString(), amount)
                    .encodeABI();
                await createAndSendEthTx(
                    bridgeAdminAccount,
                    LiquidStakingArtifact,
                    txData,
                    defaultGasLimit
                );
            }
        }else if(action === "withdrawUTokens"){
            amount = await web3.utils.toBN(testData.pBridgeTestData[k].amount.toString());
            console.log(
                "[",
                new Date().toLocaleString(),
                "] : ",
                "inside runTxs(): ",
                "\n",
                "accAddress: ",
                testData.pBridgeTestData[k].user.toString(),
                "\n",
                " amount: ",
                amount,
                "\n",
                " actions: ",
                action,
                "\n"
            );
            const txData = await TokenWrapperInstance.methods
                .withdrawUTokens(testData.pBridgeTestData[k].user.toString(), amount, testData.pBridgeTestData[k].cosmosAddr)
                .encodeABI();
            await createAndSendEthTx(
                bridgeAdminAccount,
                TokenWrapperArtifact,
                txData,
                defaultGasLimit
            );
        }else if(action === "calculateRewards"){
            console.log(
                "[",
                new Date().toLocaleString(),
                "] : ",
                "inside runTxs(): ",
                "\n",
                "accAddress: ",
                testData.pBridgeTestData[k].user.toString(),
                "\n",
                " actions: ",
                action,
                "\n"
            );
            const txData = await STokensInstance.methods
                .calculateRewards(testData.pBridgeTestData[k].user.toString())
                .encodeABI();
            await createAndSendEthTx(
                bridgeAdminAccount,
                STokensArtifact,
                txData,
                defaultGasLimit
            );
        }
        break;
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