const HttpUtils = require("../configuration/httpUtils");
const errors = require("../configuration/errors");
const httpUtils = new HttpUtils();
const config = require("../configuration/config.json");
const stakeDrop = require("../blobs/stakeDrop_blob");
const constants = require("../constants/index");
const sendTxnModule = require("./sendTransactionModule");

async function checkTxsSync(height) {
  try {
    let blockTxResponseJSON = await httpUtils.httpGet(
      config.node.ip,
      config.node.abciPort,
      `/tx_search?query="tx.height=${height}"`
    );
    let blockTxResponse = JSON.parse(blockTxResponseJSON);
    for (let i = 0; i < blockTxResponse.result.txs.length; i++) {
      let txResult = await parseTx(height, blockTxResponse.result.txs[i]);
      if (!txResult.success) {
        return txResult;
      }
    }
    return { success: true };
  } catch (e) {
    console.log(e);
    return { success: false };
  }
}

async function parseTx(height, tx) {
  try {
    let txHashResponseJSON = await httpUtils.httpGet(
      config.node.ip,
      config.node.lcdPort,
      `/txs/${tx.hash}`
    );
    let txHashResponse = JSON.parse(txHashResponseJSON);
    if (txHashResponse && txHashResponse.code) {
    } else {
      for (let i = 0; i < txHashResponse.tx.value.msg.length; i++) {
        let messageResult = await parseTxMsg(
          height,
          txHashResponse,
          txHashResponse.tx.value.msg[i]
        );
        if (!messageResult.success) {
          return messageResult;
        }
      }
    }
    return { success: true };
  } catch (e) {
    console.log(e);
    return { success: false };
  }
}

async function parseTxMsg(height, txHashResponse, txMessage) {
  try {
    let result = { success: true };
    if (constants.TxType.SendCoin[0] === txMessage.type) {
      /* let checkedDenomAmt = false;
      for (let i = 0; i < txMessage.value.amount.length; i++) {
        if (
          txMessage.value.amount[i].amount >= config.rewards.minMagicTxAmount
        ) {
          checkedDenomAmt = true;
        }
      } */

      if (
        isERCAddress(txHashResponse.tx.value.memo) &&
        txMessage.value.to_address === config.pStakeStakingAccount
      ) {
        // CREATE ACTIONABLE OBJECT
        let ethAddress = txHashResponse.tx.value.memo;

        // todo: check the decimal places???????
        let amountAtomsToPegTokens = txMessage.value.amount[0].amount;
        sendTxnModule.sendPeggedTokens(ethAddress, amountAtomsToPegTokens);

        /* result = await stakeDrop.updateERCAddress(
          txHashResponse.tx.value.memo,
          txMessage.value.from_address,
          height
        );
        if (!result.success) {
          return result;
        }
        result = await stakeDrop.onSendCoin(height, txMessage.value);
        console.log(
          "SEND_COIN - memo: " +
            txHashResponse.tx.value.memo +
            ", from_address: " +
            txMessage.value.from_address
        ); */
      }
    }

    return result;
  } catch (e) {
    console.log(e);
    return { success: false };
  }
}

function isERCAddress(address) {
  return /^(0[xX])?[0-9a-fA-F]{40}$/.test(address);
}

module.exports = {
  checkTxsSync,
};
