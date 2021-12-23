import { SendTxParams } from './interfaces';
export default function sendTx({ proxyAddress, methodName, methodArgs, value, gas, network, txParams, networkFile, }: SendTxParams): Promise<void | never>;
