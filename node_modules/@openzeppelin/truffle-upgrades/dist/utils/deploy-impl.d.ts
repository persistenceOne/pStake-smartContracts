import { ValidationOptions } from '@openzeppelin/upgrades-core';
import { Options } from './options';
import { ContractClass } from './truffle';
interface DeployedImpl {
    impl: string;
    kind: NonNullable<ValidationOptions['kind']>;
}
export declare function deployImpl(Contract: ContractClass, opts: Options, proxyAddress?: string): Promise<DeployedImpl>;
export {};
//# sourceMappingURL=deploy-impl.d.ts.map