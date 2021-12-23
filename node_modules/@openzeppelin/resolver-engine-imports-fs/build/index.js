"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var resolver_engine_core_1 = require("@openzeppelin/resolver-engine-core");
exports.firstResult = resolver_engine_core_1.firstResult;
exports.ResolverEngine = resolver_engine_core_1.ResolverEngine;
var resolver_engine_imports_1 = require("@openzeppelin/resolver-engine-imports");
exports.findImports = resolver_engine_imports_1.findImports;
exports.gatherSources = resolver_engine_imports_1.gatherSources;
exports.gatherSourcesAndCanonizeImports = resolver_engine_imports_1.gatherSourcesAndCanonizeImports;
exports.ImportsEngine = resolver_engine_imports_1.ImportsEngine;
var importsfsengine_1 = require("./importsfsengine");
exports.ImportsFsEngine = importsfsengine_1.ImportsFsEngine;
const resolver_engine_core_2 = require("@openzeppelin/resolver-engine-core");
const resolver_engine_fs_1 = require("@openzeppelin/resolver-engine-fs");
const resolver_engine_imports_2 = require("@openzeppelin/resolver-engine-imports");
const ethpmresolver_1 = require("./resolvers/ethpmresolver");
// TODO(cymerrad)
// object destructuring doesn't work in this case
// i.e.: ...fsResolvers, ...importsResolvers
// generated import paths in *.d.ts point to invalid files
// this is a more laborious way of achieving the same goal
exports.resolvers = {
    EthPmResolver: ethpmresolver_1.EthPmResolver,
    UriResolver: resolver_engine_core_2.resolvers.UriResolver,
    BacktrackFsResolver: resolver_engine_fs_1.resolvers.BacktrackFsResolver,
    FsResolver: resolver_engine_fs_1.resolvers.FsResolver,
    NodeResolver: resolver_engine_fs_1.resolvers.NodeResolver,
    GithubResolver: resolver_engine_imports_2.resolvers.GithubResolver,
    IPFSResolver: resolver_engine_imports_2.resolvers.IPFSResolver,
    SwarmResolver: resolver_engine_imports_2.resolvers.SwarmResolver,
};
exports.parsers = {
    UrlParser: resolver_engine_core_2.parsers.UrlParser,
    FsParser: resolver_engine_fs_1.parsers.FsParser,
    ImportParser: resolver_engine_imports_2.parsers.ImportParser,
};
//# sourceMappingURL=index.js.map