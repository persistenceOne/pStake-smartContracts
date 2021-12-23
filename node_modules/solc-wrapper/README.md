# solc-js-wrapper
JavaScript bindings for the [Solidity compiler](https://github.com/ethereum/solidity).

Uses the Emscripten compiled Solidity found in the [solc-bin repository](https://github.com/ethereum/solc-bin).

This is a fork of the original project [solc-js](https://github.com/ethereum/solc-js), with the difference that it removes the binary `solc`, and does not bundle any emscripten version by default. It is intended to be used from code only.

It exports the `wrapper` function that receives the emscripten binary and returns the js friendly wrapper.
