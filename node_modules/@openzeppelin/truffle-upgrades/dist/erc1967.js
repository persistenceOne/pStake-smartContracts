"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.erc1967 = void 0;
const upgrades_core_1 = require("@openzeppelin/upgrades-core");
const utils_1 = require("./utils");
function wrapWithProvider(getter) {
    return (args, opts) => {
        const { deployer } = (0, utils_1.withDefaults)(opts);
        const provider = (0, utils_1.wrapProvider)(deployer.provider);
        return getter(provider, args);
    };
}
exports.erc1967 = {
    getAdminAddress: wrapWithProvider(upgrades_core_1.getAdminAddress),
    getImplementationAddress: wrapWithProvider(upgrades_core_1.getImplementationAddress),
    getBeaconAddress: wrapWithProvider(upgrades_core_1.getBeaconAddress),
};
//# sourceMappingURL=erc1967.js.map