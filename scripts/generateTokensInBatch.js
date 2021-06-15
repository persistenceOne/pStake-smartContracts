let Web3 = require('web3'); // https://www.npmjs.com/package/web3
const HDWalletProvider = require("@truffle/hdwallet-provider");

const mnemonic =
    "baby year rocket october what surprise lab bag report swap game unveil"; // 12 word mnemonic


let provider = new HDWalletProvider({
    mnemonic: {
        phrase: mnemonic
    },
    providerOrUrl: "https://goerli.infura.io/v3/c1a795f858814218840034fe273cb040"
});
// HDWalletProvider is compatible with Web3. Use it at Web3 constructor, just like any other Web3 Provider
const web3 = new Web3(provider);

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

const lqABI = require("../build/contracts/LiquidStaking.json");
const twABI = require("../build/contracts/TokenWrapper.json");
const stABI = require("../build/contracts/STokens.json");
const utABI = require("../build/contracts/UTokens.json");

const testData = require("./generateTokensInBatchData");

const LiquidStakingInstance = new web3.eth.Contract(
    JSON.parse(JSON.stringify(lqABI.abi)),
    lqABI.networks["5"].address
);

const TokenWrapperInstance = new web3.eth.Contract(
    JSON.parse(JSON.stringify(twABI.abi)),
    twABI.networks["5"].address
);

const STokensInstance = new web3.eth.Contract(
    JSON.parse(JSON.stringify(stABI.abi)),
    stABI.networks["5"].address
);

const UTokensInstance = new web3.eth.Contract(
    JSON.parse(JSON.stringify(utABI.abi)),
    utABI.networks["5"].address
);

function convertMS(ms) {
    let d, h, m, s;
    s = Math.floor(ms / 1000);
    m = Math.floor(s / 60);
    s = s % 60;
    h = Math.floor(m / 60);
    m = m % 60;
    d = Math.floor(h / 24);
    h = h % 24;
    h += d * 24;
    return h + 'h:' + m + 'm:' + s + 's';
}

async function test() {
    try {
        let start = new Date().getTime();
        let userAddress = testData.users;
        let amount =  testData.amount;
        const nonce = await web3.eth.getTransactionCount("0x51caF3f0E53BAAF12F8B0B6d98350CBA53e8DB7B");
        let amountArray = [];

        for(let k = 0; k <amount.length; k++){
            amountArray.push(await web3.utils.toBN(testData.amount[k]))
        }

        const txnOptions = {
            to: twABI.networks["5"].address,
            from: "0x51caF3f0E53BAAF12F8B0B6d98350CBA53e8DB7B",
            gas:500000,
            gasPrice: '200000000000',
            nonce,
            chainId: 5
        };

        console.log("txnOptions: ", txnOptions)
        console.log("userAddress Length: ", userAddress.length)
        console.log("amount Length: ", amount.length)
        const txn = await TokenWrapperInstance.methods.generateUTokensInBatch(userAddress, amountArray).send(txnOptions);
        console.log("txn hash: ", txn.transactionHash)
        console.log("transaction successful status: ", txn.status);

        let end = new Date().getTime();
        let time = await convertMS(end - start);
        console.log("\n\nTotal time taken for execution: ", time);

    }
    catch (e){
        console.log("Error while generating tokens: ", e)
    }
}

test();