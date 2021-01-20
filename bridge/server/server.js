const data = require('./utilities/data');
const config = require('./config.json');
const constants = require('./constants/index');
const express = require('express');

const app = express();

app.use(function (req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    next();
});

function c() {

}

data.SetupDB(c);

app.get('/status', async function (req, res) {
    try {
        let statuses = await data.find(constants.Collection.STATUS, {});
        let delegators = await data.find(constants.Collection.DELEGATOR, {});
        let distributionCompleteDelegators = await data.find(constants.Collection.DELEGATOR, {distributionComplete: true});
        let distributionStatus = statuses.find(x => x.DISTRIBUTION_STATUS === 'DISTRIBUTION_STATUS');
        let delegationStatus = statuses.find(x => x.DELEGATION_STATUS === 'DELEGATION_STATUS');
        let distributionCompleteGlobalDelegation = distributionCompleteDelegators.map(x => x.globalDelegation).reduce((a, b) => a + b, 0.0);
        let distributionCompleteAuditDelegation = distributionCompleteDelegators.map(x => x.auditDelegation).reduce((a, b) => a + b, 0.0);
        let totalStakeDropGlobalDelegation = delegationStatus.worldGlobalDelegation + distributionCompleteGlobalDelegation;
        let totalStakeDropAuditDelegation = delegationStatus.worldAuditDelegation + distributionCompleteAuditDelegation;
        let result = {
            success: true,
            lastHeight: distributionStatus.lastHeight,
            totalDistributed: distributionStatus.totalDistributed,
            worldGlobalDelegation: delegationStatus.worldGlobalDelegation,
            worldAuditDelegation: delegationStatus.worldAuditDelegation,
            numDelegators: delegators.length,
            totalStakeDropGlobalDelegation: totalStakeDropGlobalDelegation,
            totalStakeDropAuditDelegation: totalStakeDropAuditDelegation,
            numComplete: distributionCompleteDelegators.length
        };
        res.json(result);
    } catch (e) {
        console.log(e)
        res.json({success: false, message: JSON.stringify(e)});
    }
});

app.get('/delegator/:address', async function (req, res) {
    try {
        let success = true;
        let ercAddressData = await data.find(constants.Collection.ERC_ADDRESS, {delegatorAddress: req.params.address});
        let ercAddress = '';
        let magicTxHeight = 0;
        if (ercAddressData.length !== 0) {
            ercAddress = ercAddressData[0].ercAddress;
            magicTxHeight = ercAddressData[0].height
        } else {
            success = false;
        }
        let distribution = await data.find(constants.Collection.DISTRIBUTION, {delegatorAddress: req.params.address});
        let received = 0;
        if (distribution.length !== 0) {
            received = distribution[0].amount;
        }
        let delegator = await data.find(constants.Collection.DELEGATOR, {delegatorAddress: req.params.address});
        let auditDelegation = 0;
        let globalDelegation = 0;
        if (delegator.length !== 0) {
            auditDelegation = delegator[0].auditDelegation;
            globalDelegation = delegator[0].globalDelegation;
        }
        let statuses = await data.find(constants.Collection.STATUS, {});
        let distributionStatus = statuses.find(x => x.DISTRIBUTION_STATUS === 'DISTRIBUTION_STATUS');
        let delegationStatus = statuses.find(x => x.DELEGATION_STATUS === 'DELEGATION_STATUS');
        let estimated = received;
        let leftOver = config.totalDistribute - distributionStatus.totalDistributed;
        if (leftOver !== 0) {
            if (delegationStatus.worldGlobalDelegation !== 0) {
                estimated = estimated + (globalDelegation * (1 - config.auditFactor) * leftOver) / delegationStatus.worldGlobalDelegation;
            }
            if (delegationStatus.worldAuditDelegation !== 0) {
                estimated = estimated + (auditDelegation * config.auditFactor * leftOver) / delegationStatus.worldAuditDelegation;
            }
            if (estimated > config.maxAmount) {
                estimated = config.maxAmount;
            }
        }
        let result = {
            success: success,
            delegator: req.params.address,
            received: received,
            ercAddress: ercAddress,
            magicTxHeight: magicTxHeight,
            auditDelegation: auditDelegation,
            globalDelegation: globalDelegation,
            estimated: estimated
        };
        if (!success) {
            result.message = 'Delegator not found!';
        }
        res.json(result);
    } catch (e) {
        console.log(e)
        res.json({success: false, delegator: req.params.address, message: 'Delegator not found'});
    }
});

// app.get('/all', async function (req, res) {
//     try {
//         let delegators = await data.find(constants.Collection.DELEGATOR, {});
//         let result = {
//             success: true,
//             delegators: delegators.map(x => x.delegatorAddress)
//         };
//         res.json(result);
//     } catch (e) {
//         console.log(e)
//         res.json({success: false, message: JSON.stringify(e)});
//     }
// });

let server = app.listen(config.port, config.host, function () {
    let host = server.address().address;
    let port = server.address().port;
    console.log("App listening at http://%s:%s", host, port);
});