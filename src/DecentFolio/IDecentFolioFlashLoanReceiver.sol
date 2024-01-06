// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDecentFolioFlashLoanReceiver {
    function executeOperation(
        address _tokenAddress,
        uint256 _borrowAmount,
        uint256 _interest,
        address _bowrrower,
        bytes32 _payload
    ) external;
}