const config = require("../config.json");
const data = require("./data");
const errors = require("./errors");
const constants = require("../constants/index");
const HttpUtils = require("./http");
const httpUtils = new HttpUtils();

const TxType = {
  DELEGATION_CHANGES: "DELEGATION_CHANGES",
  SEND_COIN: "SEND_COIN",
};

async function onDelegationChanges(height, delegatorAddress) {
  let result = { success: true };
  if (
    height >= config.rewards.magicTxStartHeight &&
    height <= config.rewards.stopHeight
  ) {
    result = await checkAndUpsertDelegator(
      height,
      delegatorAddress,
      TxType.DELEGATION_CHANGES
    );
  }
  return result;
}

async function onSendCoin(height, sendCoin) {
  let result = { success: true };
  if (
    height >= config.rewards.magicTxStartHeight &&
    height <= config.rewards.stopHeight
  ) {
    if (sendCoin.to_address === config.targetAccount) {
      result = await checkAndUpsertDelegator(
        height,
        sendCoin.from_address,
        TxType.SEND_COIN
      );
    }
  }
  return result;
}

async function checkAndUpsertDelegator(height, delegatorAddress, txType) {
  try {
    let allDelegators = await data.find(constants.Collection.DELEGATOR, {});
    let delegator = allDelegators.find(
      (x) => x.delegatorAddress === delegatorAddress
    );
    let upsertDelegator = false;
    if (delegator === undefined) {
      if (txType === TxType.SEND_COIN) {
        upsertDelegator = true;
      }
    } else {
      if (
        !delegator.distributionComplete &&
        txType === TxType.DELEGATION_CHANGES
      ) {
        upsertDelegator = true;
        console.log(
          "DELEGATION_CHANGES - delegator_address: " + delegatorAddress
        );
      }
    }
    if (upsertDelegator) {
      let allDelegationJson = await httpUtils.httpGet(
        config.node.ip,
        config.node.lcdPort,
        `/staking/delegators/${delegatorAddress}/delegations?height=${height}`
      );
      let allDelegationResponse = JSON.parse(allDelegationJson);
      let newDelegator = NewDelegator(
        allDelegationResponse,
        height,
        delegatorAddress,
        txType
      );
      let delegatorsIncompleteDistribution = allDelegators.filter(
        (x) => !x.distributionComplete
      );
      let worldGlobalDelegation = delegatorsIncompleteDistribution
        .map((x) => x.globalDelegation)
        .reduce((a, b) => a + b, 0.0);
      let worldAuditDelegation = delegatorsIncompleteDistribution
        .map((x) => x.auditDelegation)
        .reduce((a, b) => a + b, 0.0);
      await data.upsertOne(
        constants.Collection.DELEGATOR,
        { delegatorAddress: delegatorAddress },
        newDelegator
      );
      if (delegator === undefined) {
        worldGlobalDelegation =
          worldGlobalDelegation + newDelegator.globalDelegation;
        worldAuditDelegation =
          worldAuditDelegation + newDelegator.auditDelegation;
      } else {
        worldGlobalDelegation =
          worldGlobalDelegation +
          newDelegator.globalDelegation -
          delegator.globalDelegation;
        worldAuditDelegation =
          worldAuditDelegation +
          newDelegator.auditDelegation -
          delegator.auditDelegation;
      }
      await data.upsertOne(
        constants.Collection.STATUS,
        { DELEGATION_STATUS: "DELEGATION_STATUS" },
        {
          DELEGATION_STATUS: "DELEGATION_STATUS",
          worldGlobalDelegation: worldGlobalDelegation,
          worldAuditDelegation: worldAuditDelegation,
        }
      );
    }
    return { success: true };
  } catch (e) {
    console.log(e);
    return { success: false };
  }
}

function NewDelegator(allDelegationResponse, height, delegatorAddress, txType) {
  let auditDelegation = 0.0;
  let globalDelegation = 0.0;
  if (allDelegationResponse.result.length !== 0) {
    let delegationToAudit = allDelegationResponse.result.find(
      (delegation) => delegation.validator_address === config.auditValidator
    );
    globalDelegation = allDelegationResponse.result
      .map((delegation) => parseFloat(delegation.shares))
      .reduce((a, b) => a + b, 0.0);
    if (delegationToAudit !== undefined) {
      auditDelegation = parseFloat(delegationToAudit.shares);
    }
  }
  return {
    height: height,
    delegatorAddress: delegatorAddress,
    txType: txType,
    auditDelegation: auditDelegation,
    globalDelegation: globalDelegation,
    distributionComplete: false,
  };
}

async function onNewBlock(height) {
  try {
    let totalDistributed = 0.0;
    let distributionStatusData = await data.find(constants.Collection.STATUS, {
      DISTRIBUTION_STATUS: "DISTRIBUTION_STATUS",
    });
    let distributionStatus = distributionStatusData[0];
    let uxprtReward = getUXPRTRewardsAtBlock(
      height,
      distributionStatus.leftOver
    );
    let allDelegatorsToDistribute = await data.find(
      constants.Collection.DELEGATOR,
      { distributionComplete: false }
    );
    if (allDelegatorsToDistribute.length !== 0 && uxprtReward !== 0) {
      let allDistributions = await data.find(
        constants.Collection.DISTRIBUTION,
        {}
      );
      let allAuditDelegationShares = allDelegatorsToDistribute
        .map((x) => x.auditDelegation)
        .reduce((a, b) => a + b, 0.0);
      let allGlobalDelegationShares = allDelegatorsToDistribute
        .map((x) => x.globalDelegation)
        .reduce((a, b) => a + b, 0.0);
      for (let i = 0; i < allDelegatorsToDistribute.length; i++) {
        let delegatorDistribute = await distributeRewards(
          height,
          allDelegatorsToDistribute[i],
          allDistributions,
          uxprtReward,
          allAuditDelegationShares,
          allGlobalDelegationShares
        );
        totalDistributed = totalDistributed + delegatorDistribute.rewarded;
      }
    }
    let totalLeftOver = uxprtReward - totalDistributed;
    if (config.accuracy >= totalLeftOver) {
      totalLeftOver = 0.0;
    }
    await data.insertOne(constants.Collection.REWARDS_POOL, {
      height: height,
      distributed: totalDistributed,
      leftOver: totalLeftOver,
    });
    await data.updateOne(
      constants.Collection.STATUS,
      { DISTRIBUTION_STATUS: "DISTRIBUTION_STATUS" },
      {
        DISTRIBUTION_STATUS: "DISTRIBUTION_STATUS",
        lastHeight: height,
        totalDistributed:
          distributionStatus.totalDistributed + totalDistributed,
        leftOver: totalLeftOver,
      }
    );
    return { success: true };
  } catch (e) {
    console.log(e);
    return { success: false };
  }
}

async function distributeRewards(
  height,
  delegator,
  allDistributions,
  uxprtReward,
  allAuditDelegationShares,
  allGlobalDelegationShares
) {
  try {
    let reward = getDelegatorUXPRTRewardAtBlock(
      delegator,
      uxprtReward,
      allAuditDelegationShares,
      allGlobalDelegationShares
    );
    let rewarded = reward;
    let delegatorDistribution = allDistributions.find(
      (x) => x.delegatorAddress === delegator.delegatorAddress
    );
    if (delegatorDistribution !== undefined) {
      if (
        delegatorDistribution.amount + rewarded >=
        config.rewards.maxAmtDistributionPerAddress
      ) {
        rewarded =
          config.rewards.maxAmtDistributionPerAddress -
          delegatorDistribution.amount;
        delegator.distributionComplete = true;
        await data.updateOne(
          constants.Collection.DELEGATOR,
          { delegatorAddress: delegator.delegatorAddress },
          delegator
        );
      }
      delegatorDistribution.lastHeight = height;
      delegatorDistribution.amount = delegatorDistribution.amount + rewarded;
      await data.updateOne(
        constants.Collection.DISTRIBUTION,
        { delegatorAddress: delegator.delegatorAddress },
        delegatorDistribution
      );
    } else {
      if (rewarded > config.rewards.maxAmtDistributionPerAddress) {
        rewarded = config.rewards.maxAmtDistributionPerAddress;
      }
      await data.insertOne(
        constants.Collection.DISTRIBUTION,
        NewDistribution(delegator.delegatorAddress, height, rewarded)
      );
    }
    return { rewarded: rewarded, extra: reward - rewarded };
  } catch (e) {
    console.log(e);
    return { rewarded: 0, extra: 0 };
  }
}

// let p1 = config.calculation.n * config.calculation.N * config.calculation.blocksPerDay;
// let p2 = config.calculation.N / 2.0;
// let p3 = (config.calculation.n * config.calculation.n * config.calculation.blocksPerDay) / 2.0;
// let p4 = config.calculation.n / 2;
// let p5 = (config.calculation.N * config.calculation.blocksPerDay) / 2.0;
// let diff = (config.rewards.totalDistributionAmt - (config.calculation.N * config.rewards.day1Distribution)) / (config.calculation.blocksPerDay * (p1 - p2 - p3 + p4 - p5));
// let start = (config.rewards.day1Distribution - (config.calculation.blocksPerDay * (config.calculation.blocksPerDay - 1) * diff / 2.0)) / config.calculation.blocksPerDay;
// let constantReward = start + (config.calculation.n * config.calculation.blocksPerDay - 1) * diff;
// console.log('diff')
// console.log(diff)
// console.log('start')
// console.log(start)
// console.log('constantReward')
// console.log('constantReward')
// console.log(constantReward)

// function getUXPRTRewardsAtBlock(height, leftOverReward) {
//     if (height >= config.rewards.computeStartHeight && height <= config.rewards.stopHeight) {
//         let k = height - config.rewards.computeStartHeight;
//         let dayNum = Math.ceil(k / config.calculation.blocksPerDay);
//         let usualCurrentDayReward;
//         if (dayNum <= 21) {
//             usualCurrentDayReward = start + (k * diff);
//         } else {
//             usualCurrentDayReward = constantReward;
//         }
//         return usualCurrentDayReward + leftOverReward;
//     } else {
//         if (height < config.rewards.computeStartHeight) {
//             return 0.0;
//         }
//         if (height > config.rewards.stopHeight) {
//             return leftOverReward;
//         }
//     }
//     return 0.0
// }

// let n = config.rewards.stopHeight - config.rewards.computeStartHeight + 1;
// let d = (config.rewards.totalDistributionAmt - (n * config.rewards.startAmount)) / (n * (n - 1) / 2.0);

// function getUXPRTRewardsAtBlock(height, leftOverReward) {
//     if (height >= config.rewards.computeStartHeight && height <= config.rewards.stopHeight) {
//         return config.rewards.startAmount + ((height - config.rewards.computeStartHeight) * d) + leftOverReward;
//     } else {
//         if (height < config.rewards.computeStartHeight) {
//             return 0.0;
//         }
//         if (height > config.rewards.stopHeight) {
//             return leftOverReward;
//         }
//     }
//     return 0.0
// }

let avgRewardPerBlock =
  config.rewards.totalDistributionAmt /
  (config.rewards.stopHeight - config.rewards.computeStartHeight + 1);

function getUXPRTRewardsAtBlock(height, leftOverReward) {
  if (
    height >= config.rewards.computeStartHeight &&
    height <= config.rewards.stopHeight
  ) {
    return avgRewardPerBlock + leftOverReward;
  } else {
    if (height < config.rewards.computeStartHeight) {
      return 0.0;
    }
    if (height > config.rewards.stopHeight) {
      return leftOverReward;
    }
  }
  return 0.0;
}

function isERCAddress(address) {
  return /^(0[xX])?[0-9a-fA-F]{40}$/.test(address);
}

function getDelegatorUXPRTRewardAtBlock(
  delegator,
  uxprtReward,
  allAuditDelegationShares,
  allGlobalDelegationShares
) {
  let auditRewards = 0.0;
  let globalRewards = 0.0;
  if (allAuditDelegationShares !== 0) {
    auditRewards =
      (delegator.auditDelegation *
        uxprtReward *
        config.rewards.auditPoolFactor) /
      allAuditDelegationShares;
  }
  if (allGlobalDelegationShares !== 0) {
    globalRewards =
      (delegator.globalDelegation *
        uxprtReward *
        (1 - config.rewards.auditPoolFactor)) /
      allGlobalDelegationShares;
  }
  return auditRewards + globalRewards;
}

function NewDistribution(delegatorAddress, height, amount) {
  return {
    delegatorAddress: delegatorAddress,
    startHeight: height,
    lastHeight: height,
    amount: amount,
  };
}

async function updateERCAddress(memo, delegatorAddress, height) {
  try {
    let delegators = await data.find(constants.Collection.ERC_ADDRESS, {
      delegatorAddress: delegatorAddress,
    });
    if (delegators.length === 0) {
      await data.insertOne(constants.Collection.ERC_ADDRESS, {
        height: height,
        delegatorAddress: delegatorAddress,
        ercAddress: memo,
        lastUpdatedAt: height,
      });
    } else {
      let magicTxHeight = delegators[0].height;
      await data.updateOne(
        constants.Collection.ERC_ADDRESS,
        { delegatorAddress: delegatorAddress },
        {
          height: magicTxHeight,
          delegatorAddress: delegatorAddress,
          ercAddress: memo,
          lastUpdatedAt: height,
        }
      );
    }
    return { success: true };
  } catch (e) {
    console.log(e);
    return { success: false };
  }
}

module.exports = {
  onSendCoin,
  onDelegationChanges,
  onNewBlock,
  isERCAddress,
  updateERCAddress,
  getUXPRTRewardsAtBlock,
};
