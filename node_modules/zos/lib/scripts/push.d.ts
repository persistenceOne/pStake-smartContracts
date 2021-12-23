import { PushParams } from './interfaces';
export default function push({ network, deployDependencies, deployProxyAdmin, deployProxyFactory, reupload, force, txParams, networkFile, }: PushParams): Promise<void | never>;
