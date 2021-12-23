import { CallParams } from './interfaces';
export default function call({ proxyAddress, methodName, methodArgs, network, txParams, networkFile, }: CallParams): Promise<void | never>;
