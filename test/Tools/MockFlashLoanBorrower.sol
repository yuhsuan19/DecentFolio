// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IDecentFolioFlashLoanReceiver } from "../../src/DecentFolio/IDecentFolioFlashLoanReceiver.sol";
import { DecentFolio } from "../../src/DecentFolio/DecentFolio.sol";


contract MockFlashLoanBorrower is IDecentFolioFlashLoanReceiver {

    bool borrowCheck;
    address decentFolio;
    address borrower;

    constructor(
        address _decentFolioAddress, 
        address _borrower
    ) {
        decentFolio = _decentFolioAddress;
        borrower = _borrower;
    }

    function executeOperation(
        address _tokenAddress,
        uint256 _borrowAmount,
        uint256 _interest,
        address _bowrrower,
        bytes32
    ) external {
        require(msg.sender == decentFolio);
        require(_bowrrower == borrower);

        if (ERC20(_tokenAddress).balanceOf(address(this)) >= _borrowAmount) {
            borrowCheck = true;
        }
        
        ERC20(_tokenAddress).transfer(
            decentFolio, 
            _borrowAmount + _interest
        );
    }
}