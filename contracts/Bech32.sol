// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;


import "./BytesLib.sol";


// requirement: validate addresses like cosmosvaloper1susdz7trk9edeqf3qprkpunzqn4lyhvlduzncj
/* 
cosmos1dgtl8dqky0cucr9rlllw9cer9ysrkjnjagz5zp
cosmospub1addwnpepq272xswjqka4wm6x8nvuwshdquh0q8xrxlafz7lj32snvtg2jswl6x5ywwu
cosmosvaloper1susdz7trk9edeqf3qprkpunzqn4lyhvlduzncj
cosmosvaloperpub1addwnpepq272xswjqka4wm6x8nvuwshdquh0q8xrxlafz7lj32snvtg2jswl60hprp0
bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4
*/

library Bech32 {
    using BytesLib for bytes;

    bytes constant CHARSET = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

    function isBech32AddressValid(string memory blockchainAddress_, bytes memory hrpBytes_, bytes memory controlDigitBytes_, uint256 dataBytesSize_) internal pure returns(bool) {
        // return bech32ValidateStr(blockchainAddress);
        bytes memory _addressBytesLocal = bytes(blockchainAddress_);
        // split hrp and compare with the bytes hrp stored
        bytes memory _hrpBytesLocal = _addressBytesLocal.slice(0, hrpBytes_.length);
        if(!_hrpBytesLocal.equal(hrpBytes_)) return false;
        
        // split controlDigitBytes_ and compare with the bytes controlDigitBytes_ stored
        bytes memory _controlDigestBytes = _addressBytesLocal.slice(_hrpBytesLocal.length, 1);
        if(!_controlDigestBytes.equal(controlDigitBytes_)) return false;
        
        // split addressData and compare the length with dataBytesSize_
        bytes memory _dataBytes = _addressBytesLocal.slice(_hrpBytesLocal.length+1, (_addressBytesLocal.length-_hrpBytesLocal.length-1));
        if(_dataBytes.length != dataBytesSize_) return false;

        // validate checksum
        bytes memory _dataSliceBytes = _addressBytesLocal.slice(_hrpBytesLocal.length + 1, (_addressBytesLocal.length - 6 - _hrpBytesLocal.length - 1));
        // decode data slice using the CHARSET
        uint[] memory _dataSlice = decode(_dataSliceBytes);
        if(_dataSlice.length == 0) return false;
        // convert hrp Bytes to uint[]
        uint[] memory _hrp = toUintFromBytes(_hrpBytesLocal);
        // calculate checksummed data
        bytes memory checksummedDataBytes = encode(_hrp, _dataSlice);
        bool isValid = _dataBytes.equal(checksummedDataBytes);
        // isValid = _dataSliceBytes.equal(checksummedDataBytes);

        return isValid;
    }

    function decode(bytes memory addressDigestBytes_) internal pure returns(uint[] memory decodedBytes) {
        decodedBytes = new uint[](addressDigestBytes_.length);
        uint[] memory nullBytes;
        uint charsetIndex;

        for (uint addressDigestBytesIndex = 0; addressDigestBytesIndex < addressDigestBytes_.length; addressDigestBytesIndex++) {
            for (charsetIndex = 0; charsetIndex < CHARSET.length; charsetIndex++) {
                if(addressDigestBytes_[addressDigestBytesIndex] == CHARSET[charsetIndex])
                break;
            }
            if(charsetIndex == CHARSET.length) return nullBytes;
            decodedBytes[addressDigestBytesIndex] = charsetIndex;
        }
        return decodedBytes;
    }

    function toUintFromBytes(bytes memory dataDigestBytes_) internal pure returns(uint[] memory dataDigest) {
        dataDigest = new uint[](dataDigestBytes_.length);
        for (uint dataDigestIndex = 0; dataDigestIndex < dataDigestBytes_.length; dataDigestIndex++) {
            dataDigest[dataDigestIndex] = uint256(uint8(dataDigestBytes_[dataDigestIndex]));
        }
        return dataDigest;
    }

    function polymod(uint[] memory values) internal pure returns(uint) {
        uint32[5] memory GENERATOR = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];
        uint chk = 1;
        for (uint p = 0; p < values.length; p++) {
            uint top = chk >> 25;
            chk = (chk & 0x1ffffff) << 5 ^ values[p];
            for (uint i = 0; i < 5; i++) {
                if ((top >> i) & 1 == 1) {
                    chk ^= GENERATOR[i];
                }
            }
        }
        return chk;
    }

    function hrpExpand(uint[] memory hrp) internal pure returns (uint[] memory) {
        uint[] memory ret = new uint[](hrp.length+hrp.length+1);
        for (uint p = 0; p < hrp.length; p++) {
            ret[p] = hrp[p] >> 5;
        }
        ret[hrp.length] = 0;
        for (uint p = 0; p < hrp.length; p++) {
            ret[p+hrp.length+1] = hrp[p] & 31;
        }
        return ret;
    }

    // combines two strings together
    function concat(uint[] memory left, uint[] memory right) internal pure returns(uint[] memory) {
        uint[] memory ret = new uint[](left.length + right.length);

        uint i = 0;
        for (; i < left.length; i++) {
            ret[i] = left[i];
        }

        uint j = 0;
        while (j < right.length) {
            ret[i++] = right[j++];
        }

        return ret;
    }

    // add trailing padding to the data
    function extend(uint[] memory array, uint val, uint num) internal pure returns(uint[] memory) {
        uint[] memory ret = new uint[](array.length + num);

        uint i = 0;
        for (; i < array.length; i++) {
            ret[i] = array[i];
        }

        uint j = 0;
        while (j < num) {
            ret[i++] = val;
            j++;
        }

        return ret;
    }

    // create checksum
    function createChecksum(uint[] memory hrp, uint[] memory data) internal pure returns (uint[] memory) {
        uint[] memory values = extend(concat(hrpExpand(hrp), data), 0, 6);
        uint mod = polymod(values) ^ 1;
        uint[] memory ret = new uint[](6);
        for (uint p = 0; p < 6; p++) {
            ret[p] = (mod >> 5 * (5 - p)) & 31;
        }
        return ret;
    }

    // encode to the bech32 alphabet list
    function encode(uint[] memory hrp, uint[] memory data) internal pure returns (bytes memory) {
        uint[] memory combined = concat(data, createChecksum(hrp, data));
        // uint[] memory combined = data;

        // TODO: prepend hrp

        // convert uint[] to bytes
        bytes memory ret = new bytes(combined.length);
        for (uint p = 0; p < combined.length; p++) {
            ret[p] = CHARSET[combined[p]];
        }

        return ret;
    }

    function convert(uint[] memory data, uint inBits, uint outBits) internal pure returns (uint[] memory) {
        uint value = 0;
        uint bits = 0;
        uint maxV = (1 << outBits) - 1;

        uint[] memory ret = new uint[](32);
        uint j = 0;
        for (uint i = 0; i < data.length; ++i) {
            value = (value << inBits) | data[i];
            bits += inBits;

            while (bits >= outBits) {
                bits -= outBits;
                ret[j] = (value >> bits) & maxV;
                j += 1;
            }
        }

        return ret;
    }

}