"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deployProxy = void 0;
const upgrades_core_1 = require("@openzeppelin/upgrades-core");
const utils_1 = require("./utils");
async function deployProxy(Contract, args = [], opts = {}) {
    if (!Array.isArray(args)) {
        opts = args;
        args = [];
    }
    const { deployer } = (0, utils_1.withDefaults)(opts);
    const provider = (0, utils_1.wrapProvider)(deployer.provider);
    const manifest = await upgrades_core_1.Manifest.forNetwork(provider);
    const { impl, kind } = await (0, utils_1.deployImpl)(Contract, opts);
    const data = getInitializerData(Contract, args, opts.initializer);
    if (kind === 'uups') {
        if (await manifest.getAdmin()) {
            (0, upgrades_core_1.logWarning)(`A proxy admin was previously deployed on this network`, [
                `This is not natively used with the current kind of proxy ('uups').`,
                `Changes to the admin will have no effect on this new proxy.`,
            ]);
        }
    }
    let proxyDeployment;
    switch (kind) {
        case 'uups': {
            const ProxyFactory = (0, utils_1.getProxyFactory)(Contract);
            proxyDeployment = Object.assign({ kind }, await (0, utils_1.deploy)(deployer, ProxyFactory, impl, data));
            break;
        }
        case 'transparent': {
            const AdminFactory = (0, utils_1.getProxyAdminFactory)(Contract);
            const adminAddress = await (0, upgrades_core_1.fetchOrDeployAdmin)(provider, () => (0, utils_1.deploy)(deployer, AdminFactory));
            const TransparentUpgradeableProxyFactory = (0, utils_1.getTransparentUpgradeableProxyFactory)(Contract);
            proxyDeployment = Object.assign({ kind }, await (0, utils_1.deploy)(deployer, TransparentUpgradeableProxyFactory, impl, adminAddress, data));
            break;
        }
    }
    await manifest.addProxy(proxyDeployment);
    Contract.address = proxyDeployment.address;
    const contract = new Contract(proxyDeployment.address);
    contract.transactionHash = proxyDeployment.txHash;
    return contract;
}
exports.deployProxy = deployProxy;
function getInitializerData(Contract, args, initializer) {
    if (initializer === false) {
        return '0x';
    }
    const allowNoInitialization = initializer === undefined && args.length === 0;
    initializer = initializer !== null && initializer !== void 0 ? initializer : 'initialize';
    const stub = new Contract('');
    if (initializer in stub.contract.methods) {
        return stub.contract.methods[initializer](...args).encodeABI();
    }
    else if (allowNoInitialization) {
        return '0x';
    }
    else {
        throw new Error(`Contract ${Contract.name} does not have a function \`${initializer}\``);
    }
}
//# sourceMappingURL=deploy-proxy.js.map