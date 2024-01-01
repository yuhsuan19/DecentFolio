// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { AdminOnly } from "./Utilities/AdminOnly.sol";

contract DecentFolioProxy is AdminOnly {
    bytes32 constant ImpletationSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation"))-1);

    constructor(
        address _implementation,
        bytes memory _initialCallData
    ) {
        _setSlotToAddress(ImpletationSlot, _implementation);
        _setSlotToAddress(AdminSlot, msg.sender);

        require(
            _initialCallData.length > 0, 
            "The initial call data cannot be empty"
        );
        (bool success,) = _implementation.delegatecall(_initialCallData);
         require(
            success, 
            "Fail to intialize DecentFolio"
        );
    }

    function upgradeToAndCall(
        address newImplementation, 
        bytes memory _initialCallData
    ) external onlyAdmin {
        _setSlotToAddress(ImpletationSlot, newImplementation);

        require(
            _initialCallData.length > 0, 
            "The initial call data cannot be empty"
        );
        (bool success,) = newImplementation.delegatecall(_initialCallData);
         require(
            success, 
            "Fail to intialize DecentFolio"
        );
  }
    
    function implementation() public view returns (address impl) {
        return _getSlotToAddress(ImpletationSlot);
    }

    fallback() external payable virtual {
        _delegate(implementation());
    }

    receive() external payable {
        _delegate(implementation());
    }

    function _delegate(
        address _implementation
    ) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { 
                revert(0, returndatasize()) 
            }
            default { 
                return(0, returndatasize()) 
            }
        }
    }
}