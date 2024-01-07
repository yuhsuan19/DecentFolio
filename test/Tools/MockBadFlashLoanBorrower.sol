// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IDecentFolioFlashLoanReceiver } from "../../src/DecentFolio/IDecentFolioFlashLoanReceiver.sol";
import { DecentFolio } from "../../src/DecentFolio/DecentFolio.sol";


contract MockBadFlashLoanBorrower is IDecentFolioFlashLoanReceiver {

    bool borrowCheck;
    address decentFolio;

    constructor(address _decentFolioAddress) {
        decentFolio = _decentFolioAddress;
    }

    function executeOperation(
        address _tokenAddress,
        uint256 _borrowAmount,
        uint256,
        address,
        bytes32
    ) external {
        require(msg.sender == decentFolio, "Wrong msg.sender");

        if (ERC20(_tokenAddress).balanceOf(address(this)) >= _borrowAmount) {
            borrowCheck = true;
        }
        
        ERC20(_tokenAddress).transfer(
            decentFolio, 
            _borrowAmount
        );
    }
}