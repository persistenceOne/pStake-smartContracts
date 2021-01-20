const config = require('./config.json');
const data = require('./utilities/data');
const constants = require('./constants/index');
const HttpUtils = require('./utilities/http');
const stakeDrop = require('./utilities/stakeDrop');
const httpUtils = new HttpUtils();

async function insertAllBlocks() {
    let distributionStatus = await data.find(constants.Collection.STATUS, {DISTRIBUTION_STATUS: 'DISTRIBUTION_STATUS'});
    if (distributionStatus.length === 0) {
        await data.insertOne(constants.Collection.STATUS, {
            DELEGATION_STATUS: 'DELEGATION_STATUS',
            worldGlobalDelegation: 0.0,
            worldAuditDelegation: 0.0,
        });
        await data.insertOne(constants.Collection.STATUS, {
            LAST_DISTRIBUTED_HEIGHT: 'LAST_DISTRIBUTED_HEIGHT',
            height: 0
        });
        await data.insertOne(constants.Collection.STATUS, {
            DISTRIBUTION_STATUS: 'DISTRIBUTION_STATUS',
            lastHeight: 0,
            totalDistributed: 0.0,
            leftOver: 0.0
        });
        let a = 0;
        for (let i = config.rewards.computeStartHeight; i <= config.rewards.stopHeight; i++) {
            let k = stakeDrop.getUXPRTRewardsAtBlock(i, 0);
            a = a + k;
        }
        console.log('total')
        console.log(a);
    } else {
        if (config.simulateOnChain) {
            let delegationList = [];

            let delegationsResponse = await httpUtils.httpGet(config.node.ip, config.node.lcdPort, `/staking/validators/${config.auditValidator}/delegations`);
            let delegations = JSON.parse(delegationsResponse).result;
            console.log(delegations.length);
            delegationList = delegationList.concat(delegations);

            let delegationsResponseBinance = await httpUtils.httpGet(config.node.ip, config.node.lcdPort, `/staking/validators/kavavaloper1wu8m65vqazssv2rh8rthv532hzggfr3h9azwz9/delegations`);
            let delegationsBinance = JSON.parse(delegationsResponseBinance).result;
            console.log(delegations.length);
            delegationList = delegationList.concat(delegationsBinance.slice(0, delegations.length));

            console.log(delegationList.length);
            let delegatorsList = [];
            let worldAudit = 0;
            let worldGlobal = 0;
            for (let i = 0; i < delegationList.length; i++) {
                let delegator = delegatorsList.find(x => x.delegatorAddress === delegationList[i].delegator_address);
                if (delegator === undefined) {
                    let delegations = delegationList.filter(x => x.delegator_address === delegationList[i].delegator_address);
                    let auditDelegation = delegations.find(x => x.validator_address === config.auditValidator);
                    let auditDelegationShares = 0;
                    if (auditDelegation !== undefined) {
                        auditDelegationShares = parseFloat(auditDelegation.shares);
                    }
                    let globalDelegation = delegations.map(x => parseFloat(x.shares)).reduce((a, b) => a + b, 0.0);
                    let delegator = {
                        height: config.rewards.computeStartHeight,
                        delegatorAddress: delegationList[i].delegator_address,
                        txType: 'SEND_COIN',
                        auditDelegation: auditDelegationShares,
                        globalDelegation: globalDelegation,
                        distributionComplete: false
                    }
                    worldAudit = worldAudit + auditDelegationShares;
                    worldGlobal = worldGlobal + globalDelegation;
                    delegatorsList.push(delegator);
                }
            }
            await data.insertMany(constants.Collection.DELEGATOR, delegatorsList);
            await data.insertOne(constants.Collection.STATUS, {
                DELEGATION_STATUS: 'DELEGATION_STATUS',
                worldGlobalDelegation: worldGlobal,
                worldAuditDelegation: worldAudit,
            });
        } else {
            for (let i = 1; i <= config.simulateAddresses; i++) {
                let delegatorAddress = 'address' + i;
                // console.log(delegatorAddress)
                let a = Math.random() * 1000000000.0;
                let g = Math.random() * 1000000000.0;
                let delegator = {
                    height: 56565,
                    delegatorAddress: delegatorAddress,
                    txType: 'SEND_COIN',
                    auditDelegation: a,
                    globalDelegation: g,
                    distributionComplete: false
                }
                await data.insertOne(constants.Collection.DELEGATOR, delegator);
            }
        }
    }
    process.exit(0);
}

function shuffle(array) {
    var currentIndex = array.length, temporaryValue, randomIndex;

    // While there remain elements to shuffle...
    while (0 !== currentIndex) {

        // Pick a remaining element...
        randomIndex = Math.floor(Math.random() * currentIndex);
        currentIndex -= 1;

        // And swap it with the current element.
        temporaryValue = array[currentIndex];
        array[currentIndex] = array[randomIndex];
        array[randomIndex] = temporaryValue;
    }

    return array;

    //cosmosvaloper1m77y54nu3y8ntew39yh98nscdsd8mglnecumzl
}

data.SetupDB(insertAllBlocks);