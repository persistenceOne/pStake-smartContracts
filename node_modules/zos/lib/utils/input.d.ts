export declare function parseArgs(args: string): string[] | never;
export declare function parseArg(input: string | string[], type: string): any;
export declare function stripBrackets(inputMaybeWithBrackets: string): string;
/**
 * Parses a string as an arbitrarily nested array of strings. Handles
 * unquoted strings in the input, or quotes using both simple and double quotes.
 * @param input string to parse
 * @returns parsed ouput.
 * The return type is a lie! This function returns a recursive type,
 * with arbitrarily nested string arrays, but ts has a hard time handling that,
 * so we're fooling it into thinking it's just one level deep.
 */
export declare function parseArray(input: string): (string | string[])[];
export declare function parseMethodParams(options: any, defaultMethod?: string): {
    methodName: any;
    methodArgs: any[];
};
export declare function validateSalt(salt: string, required?: boolean): void;
