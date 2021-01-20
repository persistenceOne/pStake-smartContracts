const config = require('./config.json');
const data = require('./utilities/data');
const errors = require('./utilities/errors');
const constants = require('./constants/index');
const txUtilities = require('./utilities/tx');
const stakeDrop = require('./utilities/stakeDrop');
const HttpUtils = require('./utilities/http');
const httpUtils = new HttpUtils();

function c() {

}

data.SetupDB(c);

async function getLastDistributedHeight() {
    let result = await data.find(constants.Collection.STATUS, {LAST_DISTRIBUTED_HEIGHT: 'LAST_DISTRIBUTED_HEIGHT'});
    if (result.length === 0) {
        return 0;
    } else {
        return result[0].height;
    }
}

async function getLatestBlockHeight() {
    let statusResponseJSON = await httpUtils.httpGet(config.node.ip, config.node.abciPort, `/status`);
    let statusResponse = JSON.parse(statusResponseJSON);
    return parseInt(statusResponse.result.sync_info.latest_block_height, 10);
}

async function checkAndDistributeRewards(height) {
    try {
        let currentHeight = await getLatestBlockHeight();
        // console.log('latest block height: ' + currentHeight);
        let checked = false;
        let computed = false;
        if (currentHeight > height) {
            if (height >= config.rewards.magicTxStartHeight && height <= config.rewards.stopHeight) {
                let checkedResponse = await txUtilities.checkTxsSync(height);
                checked = checkedResponse.success;
                if (checked) {
                    if (height >= config.rewards.computeStartHeight) {
                        await stakeDrop.onNewBlock(height);
                        computed = true;
                    }
                    let lastDistributedBlock = {LAST_DISTRIBUTED_HEIGHT: 'LAST_DISTRIBUTED_HEIGHT', height: height};
                    await data.upsertOne(constants.Collection.STATUS, {LAST_DISTRIBUTED_HEIGHT: 'LAST_DISTRIBUTED_HEIGHT'}, lastDistributedBlock);
                } else {
                    console.log('Tx Check failed at: ' + height);
                }
            } else {
                if (height > config.rewards.stopHeight) {
                    await stakeDrop.onNewBlock(height);
                    let lastDistributedBlock = {LAST_DISTRIBUTED_HEIGHT: 'LAST_DISTRIBUTED_HEIGHT', height: height};
                    await data.upsertOne(constants.Collection.STATUS, {LAST_DISTRIBUTED_HEIGHT: 'LAST_DISTRIBUTED_HEIGHT'}, lastDistributedBlock);
                    computed = true;
                }
            }
        }
        let blockComputation = {height: height, checked: checked, computed: computed};
        await data.upsertOne(constants.Collection.BLOCKS_COMPUTATION, {height: height}, blockComputation);
        return blockComputation;
    } catch (e) {
        console.log(e);
        return {height: height, checked: false, computed: false};
    }
}

async function startComputing() {
    try {
        // let start = new Date();
        let status;
        let lastDistributedHeight = await getLastDistributedHeight();
        if (lastDistributedHeight === 0) {
            status = await checkAndDistributeRewards(config.rewards.magicTxStartHeight);
        } else {
            status = await checkAndDistributeRewards(lastDistributedHeight + 1);
        }
        if (status.checked || status.computed) {
            console.log(status);
        }
        if (status.computed && status.height > config.rewards.stopHeight) {
            let distributionStatus = await data.find(constants.Collection.STATUS, {DISTRIBUTION_STATUS: 'DISTRIBUTION_STATUS'});
            if (distributionStatus[0].leftOver < config.accuracy) {
                console.log('All Distributed');
                return;
            }
        }
        if ((lastDistributedHeight === 0) || lastDistributedHeight >= config.rewards.magicTxStartHeight) { //&& lastDistributedHeight <= config.rewards.stopHeight)) {
            setTimeout(startComputing, config.nextBlockComputeWaitPeriod);
        }
        // let end = new Date();
        // let used = process.memoryUsage().heapUsed / 1024 / 1024;
        // console.log(`The script uses approximately ${Math.round(used * 100) / 100} MB`);
        // console.log('Time Taken at ' + status.height + ': ' + (end - start) + ' ms');
    } catch (e) {
        console.log(e);
        startComputing()
            .catch(err => console.log(err));
    }
}

async function start() {
    startComputing()
        .catch(err => console.log(err));
}

setTimeout(start, 500)