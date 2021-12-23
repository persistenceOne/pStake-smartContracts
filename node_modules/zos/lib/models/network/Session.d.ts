declare const DEFAULT_TX_TIMEOUT: number;
interface SessionOptions {
    network?: string;
    from?: string;
    timeout?: number;
    expires?: Date;
}
declare const Session: {
    getOptions(overrides?: SessionOptions, silent?: boolean): SessionOptions;
    setDefaultNetworkIfNeeded(network: string): void;
    getNetwork(): {
        network: string;
        expired: boolean;
    };
    open({ network, from, timeout }: SessionOptions, expires?: number, logInfo?: boolean): void;
    close(): void;
    ignoreFile(): void;
    _parseSession(): SessionOptions;
    _setDefaults(session: SessionOptions): SessionOptions;
    _hasExpired(session: SessionOptions): boolean;
};
export { DEFAULT_TX_TIMEOUT };
export default Session;
