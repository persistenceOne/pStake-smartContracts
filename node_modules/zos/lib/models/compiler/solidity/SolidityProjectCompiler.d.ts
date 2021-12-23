import { RawContract, CompilerOptions } from './SolidityContractsCompiler';
import { SolcBuild } from './CompilerProvider';
export declare function compileProject(options?: ProjectCompilerOptions): Promise<ProjectCompileResult>;
export interface ProjectCompilerOptions extends CompilerOptions {
    manager?: string;
    inputDir?: string;
    outputDir?: string;
    force?: boolean;
}
export interface ProjectCompileResult {
    compilerVersion: SolcBuild;
    contracts: RawContract[];
}
