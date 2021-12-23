import { UpdateParams } from './interfaces';
export default function update({ packageName, contractAlias, proxyAddress, methodName, methodArgs, all, network, force, txParams, networkFile, }: UpdateParams): Promise<void>;
