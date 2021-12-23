"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deployImpl = void 0;
const upgrades_core_1 = require("@openzeppelin/upgrades-core");
const deploy_1 = require("./deploy");
const options_1 = require("./options");
const truffle_1 = require("./truffle");
const validations_1 = require("./validations");
const wrap_provider_1 = require("./wrap-provider");
async function deployImpl(Contract, opts, proxyAddress) {
    const fullOpts = (0, options_1.withDefaults)(opts);
    const provider = (0, wrap_provider_1.wrapProvider)(fullOpts.deployer.provider);
    const { contracts_build_directory, contracts_directory } = (0, truffle_1.getTruffleConfig)();
    const validations = await (0, validations_1.validateArtifacts)(contracts_build_directory, contracts_directory);
    const linkedBytecode = await (0, validations_1.getLinkedBytecode)(Contract, provider);
    const encodedArgs = encodeArgs(Contract, fullOpts.constructorArgs);
    const version = (0, upgrades_core_1.getVersion)(Contract.bytecode, linkedBytecode, encodedArgs);
    const layout = (0, upgrades_core_1.getStorageLayout)([validations], version);
    if (opts.kind === undefined) {
        fullOpts.kind = (0, upgrades_core_1.inferProxyKind)(validations, version);
    }
    if (proxyAddress !== undefined) {
        await (0, upgrades_core_1.setProxyKind)(provider, proxyAddress, fullOpts);
    }
    (0, upgrades_core_1.assertUpgradeSafe)([validations], version, fullOpts);
    if (proxyAddress !== undefined) {
        const manifest = await upgrades_core_1.Manifest.forNetwork(provider);
        const currentImplAddress = await (0, upgrades_core_1.getImplementationAddress)(provider, proxyAddress);
        const currentLayout = await (0, upgrades_core_1.getStorageLayoutForAddress)(manifest, validations, currentImplAddress);
        (0, upgrades_core_1.assertStorageUpgradeSafe)(currentLayout, layout, fullOpts);
    }
    const impl = await (0, upgrades_core_1.fetchOrDeploy)(version, provider, async () => {
        const deployment = await (0, deploy_1.deploy)(fullOpts.deployer, Contract, ...fullOpts.constructorArgs);
        return { ...deployment, layout };
    });
    return { impl, kind: fullOpts.kind };
}
exports.deployImpl = deployImpl;
function encodeArgs(Contract, constructorArgs) {
    var _a, _b;
    const fragment = Contract.abi.find((entry) => entry.type == 'constructor');
    return Contract.web3.eth.abi.encodeParameters((_b = (_a = fragment === null || fragment === void 0 ? void 0 : fragment.inputs) === null || _a === void 0 ? void 0 : _a.map((entry) => entry.type)) !== null && _b !== void 0 ? _b : [], constructorArgs);
}
//# sourceMappingURL=deploy-impl.js.map