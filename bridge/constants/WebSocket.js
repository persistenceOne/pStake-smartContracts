const config = require('../config');

const queryNewBlockString = `tm.event='NewBlock'`;
const queryNewTxString = `tm.event='Tx'`;

const webSocket = {
    SUBSCRIBE_NEW_BLOCK: {
        "jsonrpc": "2.0",
        "method": "subscribe",
        "id": "0",
        "params": {
            "query": `${queryNewBlockString}`,
        },
    },
    SUBSCRIBE_TX: {
        "jsonrpc": "2.0",
        "method": "subscribe",
        "id": "0",
        "params": {
            "query": `${queryNewTxString}`,
        },
    },
    UNSUBSCRIBE_ALL: {
        "jsonrpc": "2.0",
        "method": "unsubscribe_all",
        "id": "0",
        "params": {},
    },
    URL: `ws://${config.node.ip}:${config.node.abciPort}/websocket`,
    BACKUP_URL: `ws://${config.node.ip}:${config.node.abciPort}/websocket`,
};

module.exports = webSocket;