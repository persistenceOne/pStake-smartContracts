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
const LiquidStaking = artifacts.require('LiquidStaking');
const TokenWrapper = artifacts.require('TokenWrapper');
const sTokens = artifacts.require('STokens');
const uTokens = artifacts.require('UTokens');

let defaultAdmin = "0x9ac68f077dd05cC8847cb2fF414B43D0e761aD1c";
let bridgeAdmin = "0xA7aB6D6AED3e755900d62701156BA180869EAD38";
let pauseAdmin = "0xC14DeB556AB620D8F56707bd01f5af018538Af8D";
let to = "0xD7E6Bbbed5e2B280c26016FDc4D9d818C544965D";
let unknownAddress = "0x1640cC05Cec99ceDcb82d0Fb58802BAbbbBcCD30";

describe('UTokens', () => {
    let amount = new BN(200);
    let utokens;
    let stokens;
    let liquidStaking;
    let tokenWrapper;
    beforeEach(async function () {
        this.project = await TestHelper()

        utokens = await deployProxy(uTokens, [bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        stokens = await deployProxy(sTokens, [utokens.address, pauseAdmin], { initializer: 'initialize' });

        tokenWrapper = await deployProxy(TokenWrapper, [utokens.address, stokens.address, bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        liquidStaking = await deployProxy(LiquidStaking, [utokens.address, stokens.address, bridgeAdmin, pauseAdmin], { initializer: 'initialize' });

        await utokens.setSTokenContract(stokens.address,{from: defaultAdmin})
        await utokens.setWrapperContract(tokenWrapper.address,{from: defaultAdmin})
        await utokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})

        await stokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin})
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
            await expectRevert(utokens.setSTokenContract(stokens.address,{from: unknownAddress,}), "UTokens: User not authorised to set SToken contract");
            // TEST SCENARIO END
        }, 200000);

        it("Non owner can set wrapper contract address: ", async function () {
            await expectRevert(utokens.setWrapperContract(tokenWrapper.address,{from: unknownAddress,}), "UTokens: User not authorised to set wrapper contract");
            // TEST SCENARIO END
        }, 200000);

        it("Non owner can set liquidStaking contract address: ", async function () {
            await expectRevert(utokens.setLiquidStakingContract(liquidStaking.address,{from: unknownAddress,}), "UTokens: User not authorised to set liquidStaking contract");
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
            await expectRevert(utokens.pause({from: unknownAddress,}), "UTokens: User not authorised to pause contracts");
        });

        it('Transactions could not be sent to paused contracts', async function () {
            await utokens.pause({from: pauseAdmin,});
            let checkPause = await utokens.paused();
            expect(checkPause === false)
            await expectRevert(utokens.setLiquidStakingContract(liquidStaking.address,{from: defaultAdmin,}), "Pausable: paused");
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
            await expectRevert(utokens.unpause({from: unknownAddress,}), "UTokens: User not authorised to unpause contracts");
        });
    });
});
