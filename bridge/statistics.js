const config = require('./config.json');
const data = require('./utilities/data');
const errors = require('./utilities/errors');
const plotLib = require('nodeplotlib');
const constants = require('./constants/index');

const containerSize = 500000000;
let auditResult = new Map();
// let globalResult = new Map();
let threshHoldHeight = 3906000;
let factor = 1000000
let max = 1000;

async function compute() {
    try {
        let allDelegators = await data.find(constants.Collection.DELEGATOR, {});
        let allDistributions = await data.find(constants.Collection.DISTRIBUTION, {});
        let distributionCompleteDelegators = await data.find(constants.Collection.DELEGATOR, {distributionComplete: true});
        let x = [];
        let y = [];
        let z = 0;
        let c = 0;
        let n = 0;
        let r = 0;
        let a = 0;
        let g = 0;
        for (let i = 0; i < allDelegators.length; i++) {
            let delegator = allDelegators[i];
            let rewards = allDistributions.find(x => x.delegatorAddress === delegator.delegatorAddress);
            let j = Math.floor(delegator.auditDelegation / containerSize);
            let k = Math.floor(delegator.globalDelegation / containerSize);
            // if (j == 200 && k == 200) {
            //     console.log(delegator)
            // }
            if (delegator.globalDelegation <= (max * factor)) {
                n = n + 1;
                r = r + rewards.amount;
                a = a + delegator.auditDelegation;
                g = g + delegator.globalDelegation;

            }
            if (rewards.startHeight <= threshHoldHeight && j <= 500 && k <= 500) {
                // if (delegator.auditDelegation !== 0) {
                if (auditResult.has(j)) {
                    let result = auditResult.get(j);
                    if (result.has(k)) {
                        let data = result.get(k);
                        let oldNum = data.num;
                        let oldAuditDelegation = data.auditDelegation;
                        let oldGlobalDelegation = data.globalDelegation;
                        let oldMeanAuditDelegation = data.meanAuditDelegation;
                        let oldMeanGlobalDelegation = data.meanGlobalDelegation;
                        let oldTotalReward = data.totalReward;
                        let oldMeanReward = data.meanReward;
                        if (j == 0 && k == 200) {
                            console.log(oldNum);
                            // z = z + delegator.globalDelegation;
                            // c = c + 1
                        }
                        data.num = oldNum + 1;
                        data.auditDelegation = oldAuditDelegation + delegator.auditDelegation / factor;
                        data.globalDelegation = oldGlobalDelegation + delegator.globalDelegation / factor;
                        data.meanAuditDelegation = ((oldMeanAuditDelegation * oldNum) + delegator.auditDelegation / factor) / (oldNum + 1);
                        data.meanGlobalDelegation = ((oldMeanGlobalDelegation * oldNum) + delegator.globalDelegation / factor) / (oldNum + 1);
                        data.totalReward = oldTotalReward + rewards.amount / factor;
                        data.meanReward = ((oldMeanReward * oldNum) + rewards.amount / factor) / (oldNum + 1);
                        // result.set(j, data);
                    } else {
                        let data = {
                            num: 1,
                            auditDelegation: delegator.auditDelegation / factor,
                            meanAuditDelegation: delegator.auditDelegation / factor,
                            globalDelegation: delegator.globalDelegation / factor,
                            meanGlobalDelegation: delegator.globalDelegation / factor,
                            totalReward: rewards.amount / factor,
                            meanReward: rewards.amount / factor
                        }
                        result.set(k, data);
                    }
                    // auditResult.set(j, result);
                } else {
                    let data = {
                        num: 1,
                        auditDelegation: delegator.auditDelegation / factor,
                        meanAuditDelegation: delegator.auditDelegation / factor,
                        globalDelegation: delegator.globalDelegation / factor,
                        meanGlobalDelegation: delegator.globalDelegation / factor,
                        totalReward: rewards.amount / factor,
                        meanReward: rewards.amount / factor
                    }
                    let result = new Map();
                    result.set(k, data);
                    auditResult.set(j, result);
                }
                // }
                // if (j == 0 && k == 200) {
                //     console.log(auditResult.get(0).get(200));
                //     // z = z + delegator.globalDelegation;
                //     // c = c + 1
                // }
            }
        }
        console.log(z / factor)
        console.log(c)
        console.log('max delegation globally: ' + max)
        console.log('total particiapnts: ' + n)
        console.log('total rewards: ' + (r / factor))
        console.log('audit deleg: ' +(a / factor))
        console.log('global deleg: ' +(g / factor))
        let num = [];
        let auditTotalDelegation = [];
        let auditMeanDelegation = [];
        let globalTotalDelegation = [];
        let globalMeanDelegation = [];
        let totalReward = [];
        let meanReward = [];
        let auditKeys = Array.from(auditResult.keys());
        for (let i = 0; i < auditKeys.length; i++) {
            let result = auditResult.get(auditKeys[i])
            let globalKeys = Array.from(result.keys());
            for (let j = 0; j < globalKeys.length; j++) {
                x.push(auditKeys[i]);
                y.push(globalKeys[j]);
                num.push(result.get(globalKeys[j]).num);
                auditTotalDelegation.push(result.get(globalKeys[j]).auditDelegation);
                auditMeanDelegation.push(result.get(globalKeys[j]).meanAuditDelegation);
                globalTotalDelegation.push(result.get(globalKeys[j]).globalDelegation);
                globalMeanDelegation.push(result.get(globalKeys[j]).meanGlobalDelegation);
                totalReward.push(result.get(globalKeys[j]).totalReward);
                meanReward.push(result.get(globalKeys[j]).meanReward);
            }
        }
        // console.log(x.length)
        // console.log(y.length)
        // console.log(num.length)
        // console.log(totalReward.length)
        // console.log(meanReward.length)

        // console.log(auditResult.get(200).get(200));
        console.log(auditResult.get(0).get(200));
        // plotLib.plot([{x: x, y: y, z: num, type: 'scatter3d'}], {
        //     title: 'Number of delegators',
        //     autosize: true,
        //     xaxis: {title: 'Audit Bins (Size = 500)'},
        //     yaxis: {title: 'Global Bins (Size = 500)'}
        // });
        // plotLib.plot([{x: x, y: y, z: totalReward, type: 'scatter3d'}], {
        //     title: 'Total Rewards',
        //     autosize: true,
        //     xaxis: {title: 'Audit Bins (Size = 500)'},
        //     yaxis: {title: 'Global Bins (Size = 500)'}
        // });
        plotLib.plot([{x: x, y: y, z: meanReward, type: 'scatter3d'}], {
            title: 'Mean Rewards',
            autosize: true,
            xaxis: {title: 'Audit Bins (Size = 500)'},
            yaxis: {title: 'Global Bins (Size = 500)'}
        });
    } catch (e) {
        console.log('COMPUTE FAILED');
        console.log(e);
    }
}

data.SetupDB(compute);

// let oldNum = data.num;
// let oldAuditDelegation = data.auditDelegation;
// let oldMeanDelegation = data.meanDelegation;
// let oldTotalReward = data.totalReward;
// let oldMeanReward = data.meanReward;
// data.num = oldNum + 1;
// data.auditDelegation = oldAuditDelegation + delegator.auditDelegation / factor;
// data.meanDelegation = ((oldMeanDelegation * oldNum) + delegator.auditDelegation / factor) / (oldNum + 1);
// data.totalReward = oldTotalReward + ((rewards.amount * 0.25) / factor);
// data.meanReward = ((oldMeanReward * oldNum) + (rewards.amount * 0.25) / factor) / (oldNum + 1);

// console.log(auditResult.get(0));
// console.log(globalResult.get(0));
// let auditKeys = Array.from(auditResult.keys()).sort();
// let auditNum = [];
// let auditDelegation = [];
// let auditMeanDelegation = [];
// let auditTotalReward = [];
// let auditMeanReward = [];
// let globalKeys = Array.from(globalResult.keys()).sort();
// let globalNum = [];
// let globalDelegation = [];
// let globalMeanDelegation = [];
// let globalTotalReward = [];
// let globalMeanReward = [];
// for (let i = 0; i < auditKeys.length; i++) {
//     auditNum.push(auditResult.get(auditKeys[i]).num);
//     auditDelegation.push(auditResult.get(auditKeys[i]).auditDelegation);
//     auditMeanDelegation.push(auditResult.get(auditKeys[i]).meanDelegation);
//     auditTotalReward.push(auditResult.get(auditKeys[i]).totalReward);
//     auditMeanReward.push(auditResult.get(auditKeys[i]).meanReward);
// }
// for (let i = 0; i < globalKeys.length; i++) {
//     globalNum.push(globalResult.get(globalKeys[i]).num);
//     globalDelegation.push(globalResult.get(globalKeys[i]).globalDelegation);
//     globalMeanDelegation.push(globalResult.get(globalKeys[i]).meanDelegation);
//     globalTotalReward.push(globalResult.get(globalKeys[i]).totalReward);
//     globalMeanReward.push(globalResult.get(globalKeys[i]).meanReward);
// }
// let auditNumData = [{x: auditKeys, y: auditNum, type: 'bar'}]
// let auditDelegationData = [{x: auditKeys, y: auditDelegation, type: 'bar'}];
// let auditMeanDelegationData = [{x: auditKeys, y: auditMeanDelegation, type: 'bar'}]
// let auditTotalRewardData = [{x: auditKeys, y: auditTotalReward, type: 'bar'}];
// let auditMeanRewardData = [{x: auditKeys, y: auditMeanReward, type: 'bar'}]
// let globalNumData = [{x: globalKeys, y: globalNum, type: 'bar'}]
// let globalDelegationData = [{x: globalKeys, y: globalDelegation, type: 'bar'}];
// let globalMeanDelegationData = [{x: globalKeys, y: globalMeanDelegation, type: 'bar'}]
// let globalTotalRewardData = [{x: globalKeys, y: globalTotalReward, type: 'bar'}];
// let globalMeanRewardData = [{x: globalKeys, y: globalMeanReward, type: 'bar'}]
// plotLib.plot(auditNumData, {
//     title: 'Number of delegators per bin on audit',
//     autosize: true,
//     xaxis: {title: 'Bin Size = 500'},
//     yaxis: {title: 'Number of Delegators on Global'}
// });
// plotLib.plot(auditDelegationData, {
//             title: 'Total delegation on Audit per bin on audit',
//             autosize: true,
//             xaxis: {title: 'Bin Size = 500'},
//             yaxis: {title: 'Total delegation on Audit'}
//         });
// plotLib.plot(auditMeanDelegationData, {
//     title: 'Mean delegation on Audit per bin on audit',
//     autosize: true,
//     xaxis: {title: 'Bin Size = 500'},
//     yaxis: {title: 'Mean delegation on Audit'}
// });
// plotLib.plot(auditTotalRewardData, {
//             title: 'Total Rewards per bin on audit',
//             autosize: true,
//             xaxis: {title: 'Bin Size = 500'},
//             yaxis: {title: 'Total Rewards on Audit'}
//         });
// plotLib.plot(auditMeanRewardData, {
//     title: 'Mean Rewards per bin on audit',
//     autosize: true,
//     xaxis: {title: 'Bin Size = 500'},
//     yaxis: {title: 'Mean Rewards on audit'}
// });
// plotLib.plot(globalNumData, {
//     title: 'Number of delegators per bin on global',
//     autosize: true,
//     xaxis: {title: 'Bin Size = 500'},
//     yaxis: {title: 'Number of Delegators on Global'}
// });
// plotLib.plot(globalDelegationData, {
//                 title: 'Total delegation on Global per bin on global',
//             autosize: true,
//             xaxis: {title: 'Bin Size = 500'},
//             yaxis: {title: 'Total delegation on Global'}
//         });
// plotLib.plot(globalMeanDelegationData, {
//             title: 'Mean delegation on Global per bin on global',
//             autosize: true,
//             xaxis: {title: 'Bin Size = 500'},
//             yaxis: {title: 'Mean delegation on Global'}
//         });
// plotLib.plot(globalTotalRewardData, {
//             title: 'Total Rewards per bin on global',
//             autosize: true,
//             xaxis: {title: 'Bin Size = 500'},
//             yaxis: {title: 'Total Rewards on Global'}
//         });
// plotLib.plot(globalMeanRewardData, {
//             title: 'Mean Rewards per bin on global',
//             autosize: true,
//             xaxis: {title: 'Bin Size = 500'},
//             yaxis: {title: 'Mean Rewards on global'}
//         });