const txType = {
    SendCoin: ["cosmos-sdk/MsgSend", "bank/MsgSend"],
    DelegationChanges: ["cosmos-sdk/MsgDelegate", "cosmos-sdk/MsgBeginRedelegate", "cosmos-sdk/MsgUndelegate", "staking/MsgDelegate", "staking/MsgBeginRedelegate", "staking/MsgUndelegate"],
    Cosmos: {
        DELEGATE: "cosmos-sdk/MsgDelegate",
        REDELEGATE: "cosmos-sdk/MsgBeginRedelegate",
        UNDELEGATE: "cosmos-sdk/MsgUndelegate",
        SEND_COIN: "cosmos-sdk/MsgSend"
    },
    Terra: {
        DELEGATE: "staking/MsgDelegate",
        REDELEGATE: "staking/MsgBeginRedelegate",
        UNDELEGATE: "staking/MsgUndelegate",
        SEND_COIN: "bank/MsgSend"
    }
}

module.exports = txType