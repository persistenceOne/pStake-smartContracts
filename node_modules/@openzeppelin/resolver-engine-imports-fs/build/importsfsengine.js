"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const resolver_engine_fs_1 = require("@openzeppelin/resolver-engine-fs");
const resolver_engine_imports_1 = require("@openzeppelin/resolver-engine-imports");
const ethpmresolver_1 = require("./resolvers/ethpmresolver");
function ImportsFsEngine() {
    return resolver_engine_imports_1.ImportsEngine()
        .addResolver(resolver_engine_fs_1.resolvers.FsResolver())
        .addResolver(resolver_engine_fs_1.resolvers.NodeResolver())
        .addResolver(ethpmresolver_1.EthPmResolver())
        .addParser(resolver_engine_imports_1.parsers.ImportParser([resolver_engine_fs_1.parsers.FsParser()]));
}
exports.ImportsFsEngine = ImportsFsEngine;
//# sourceMappingURL=importsfsengine.js.map