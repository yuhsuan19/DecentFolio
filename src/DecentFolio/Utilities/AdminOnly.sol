// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Slots } from "./Slots.sol";

abstract contract AdminOnly is Slots  {
    bytes32 constant AdminSlot = bytes32(uint256(keccak256("eip1967.proxy.admin"))-1);
    
    modifier onlyAdmin {
        require(msg.sender == _getSlotToAddress(AdminSlot));
        _;
    }

    function admin() public view returns (address _admin) {
        return _getSlotToAddress(AdminSlot);
    }
}