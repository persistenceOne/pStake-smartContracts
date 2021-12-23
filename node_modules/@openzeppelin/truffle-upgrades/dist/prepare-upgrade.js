"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.prepareUpgrade = void 0;
const utils_1 = require("./utils");
async function prepareUpgrade(proxy, Contract, opts = {}) {
    const proxyAddress = (0, utils_1.getContractAddress)(proxy);
    const { impl } = await (0, utils_1.deployImpl)(Contract, opts, proxyAddress);
    return impl;
}
exports.prepareUpgrade = prepareUpgrade;
//# sourceMappingURL=prepare-upgrade.js.map