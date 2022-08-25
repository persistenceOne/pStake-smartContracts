/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the pStake-smartContracts contributors
 SPDX-License-Identifier: Apache-2.0
*/

//UNIT TEST

/* This unit test uses the OpenZeppelin test environment and OpenZeppelin test helpers,
which we will be using for our unit testing. */
const {web3} = require("@openzeppelin/test-helpers/src/setup");
const {
    deployProxy,
} = require("@openzeppelin/truffle-upgrades");

const {
    accounts,
    contract,
} = require("@openzeppelin/test-environment");
const {
    BN,
    expectRevert,
} = require("@openzeppelin/test-helpers");
const { TestHelper } = require('zos');
const { Contracts, ZWeb3 } = require('zos-lib');

ZWeb3.initialize(web3.currentProvider);
const LiquidStaking = artifacts.require('LiquidStakingV3');
const TokenWrapper = artifacts.require('TokenWrapperV6');
const sTokens = artifacts.require('STokensV3');
const MigrationAdmin = artifacts.require('MigrationAdminV3');

let defaultAdmin = "0xD796aD3ADAf2809EDB36e7E215b54Fee663F4DA3";
let pauseAdmin = "0xD796aD3ADAf2809EDB36e7E215b54Fee663F4DA3";

describe('Migration Admin', () => {
    let amount = new BN(200);
    let rewardRate = new BN(3000000);
    let _rewardRate = new BN(3000000);
    let rewardDivisor = new BN(1000000000)
    let epochInterval = "259200" //3 days
    let unstakingLockTime = "1814400" // 21 days
    let utokens;
    let stokens;
    let migrationAdmin;
    let tokenWrapper;
    beforeEach(async function () {
        this.project = await TestHelper()

        utokens = await deployProxy(uTokens, [bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        stokens = await deployProxy(sTokens, [utokens.address, pauseAdmin, _rewardRate, rewardDivisor], { initializer: 'initialize' });

        tokenWrapper = await deployProxy(TokenWrapper, [utokens.address, bridgeAdmin, pauseAdmin, rewardDivisor], { initializer: 'initialize' });

        migrationAdmin = await deployProxy(MigrationAdmin, [utokens.address, stokens.address, tokenWrapper.address, pauseAdmin], { initializer: 'initialize' });

        await utokens.setSTokenContract(stokens.address,{from: defaultAdmin})
        await utokens.setWrapperContract(tokenWrapper.address,{from: defaultAdmin})
        await utokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})

        await stokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})
        await stokens.setRewardRate(rewardRate,{from: defaultAdmin,});
    });
    describe("Set smart contract address", function () {
        it("Only bridge owner can set sToken contract address: ", async function () {
            await utokens.setSTokenContract(stokens.address,{from: defaultAdmin,});
            // TEST SCENARIO END
        }, 200000);

        it("Only bridge owner can set liquidStaking contract address: ", async function () {
            await utokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin,});
            // TEST SCENARIO END
        }, 200000);

        it("Non owner can set sToken contract address: ", async function () {
            await expectRevert(utokens.setSTokenContract(stokens.address,{from: unknownAddress,}), "UT3");
            // TEST SCENARIO END
        }, 200000);

        it("Non owner can set wrapper contract address: ", async function () {
            await expectRevert(utokens.setWrapperContract(tokenWrapper.address,{from: unknownAddress,}), "UT5");
            // TEST SCENARIO END
        }, 200000);

        it("Non owner can set liquidStaking contract address: ", async function () {
            await expectRevert(utokens.setLiquidStakingContract(liquidStaking.address,{from: unknownAddress,}), "UT4");
            // TEST SCENARIO END
        }, 200000);
    });

    describe("Pausable", function () {
        it('Only pauser admin can pause contracts', async function () {
            await utokens.pause({from: pauseAdmin,});
            let checkPause = await utokens.paused();
            expect(checkPause === true)
        });

        it('Non pauser admin cannot pause contracts', async function () {
            await expectRevert(utokens.pause({from: unknownAddress,}), "UT6");
        });

        it('Only pauser admin can unpause contracts', async function () {
            await utokens.pause({from: pauseAdmin,});
            let checkPause = await utokens.paused();
            expect(checkPause === true)

            await utokens.unpause({from: pauseAdmin,});
            checkPause = await utokens.paused();
            expect(checkPause === false)
        });

        it('Non pauser admin cannot unpause contracts', async function () {
            await expectRevert(utokens.unpause({from: unknownAddress,}), "UT7");
        });
    });
});
