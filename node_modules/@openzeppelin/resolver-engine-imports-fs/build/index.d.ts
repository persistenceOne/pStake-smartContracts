export { Context, firstResult, Options, ResolverEngine, SubParser, SubResolver, } from "@openzeppelin/resolver-engine-core";
export { findImports, gatherSources, gatherSourcesAndCanonizeImports, ImportFile, ImportsEngine, } from "@openzeppelin/resolver-engine-imports";
export { ImportsFsEngine } from "./importsfsengine";
import { EthPmResolver } from "./resolvers/ethpmresolver";
export declare const resolvers: {
    EthPmResolver: typeof EthPmResolver;
    UriResolver: typeof import("@openzeppelin/resolver-engine-core/build/resolvers").UriResolver;
    BacktrackFsResolver: typeof import("@openzeppelin/resolver-engine-fs/build/resolvers/backtrackfsresolver").BacktrackFsResolver;
    FsResolver: typeof import("@openzeppelin/resolver-engine-fs/build/resolvers/fsresolver").FsResolver;
    NodeResolver: typeof import("@openzeppelin/resolver-engine-fs/build/resolvers/noderesolver").NodeResolver;
    GithubResolver: typeof import("@openzeppelin/resolver-engine-imports/build/resolvers/githubresolver").GithubResolver;
    IPFSResolver: typeof import("@openzeppelin/resolver-engine-imports/build/resolvers/ipfsresolver").IPFSResolver;
    SwarmResolver: typeof import("@openzeppelin/resolver-engine-imports/build/resolvers/swarmresolver").SwarmResolver;
};
export declare const parsers: {
    UrlParser: typeof import("@openzeppelin/resolver-engine-core/build/parsers").UrlParser;
    FsParser: typeof import("@openzeppelin/resolver-engine-fs/build/parsers/fsparser").FsParser;
    ImportParser: typeof import("@openzeppelin/resolver-engine-imports/build/parsers/importparser").ImportParser;
};
