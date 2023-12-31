// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20Token is ERC20 {
    constructor(
        string memory _tokenName,
        string memory _symbol
    ) ERC20(_tokenName, _symbol) {
        
    }
}