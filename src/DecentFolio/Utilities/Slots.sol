// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

abstract contract Slots {
    function _setSlotToUint256(
        bytes32 _slot, 
        uint256 value
    ) internal {
        assembly {
            sstore(_slot, value)
        }
    }

    function _setSlotToAddress(
        bytes32 _slot, 
        address value
    ) internal {
        assembly {
            sstore(_slot, value)
        }
    }

    function _getSlotToAddress(
        bytes32 _slot
    ) internal view returns (address value) {
        assembly {
            value := sload(_slot)
        }
    }
}