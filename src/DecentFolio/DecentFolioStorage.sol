// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IUniswapV2Router02 } from "../../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

struct InvestmentTarget {
    address tokenAddress;
    uint256 percentage; // The percentage of the target
}

abstract contract DecentFolioStorage {
    address public basedTokenAddress;
    InvestmentTarget[] public investmentTargets;
    
    address uniswapV2RouterAddress;
    IUniswapV2Router02 uniswapV2Router;

    bool initialized;

    function investmentTarget(uint256 index) public view returns (address, uint256) {
        InvestmentTarget memory target = investmentTargets[index];
        return (target.tokenAddress, target.percentage);
    }
}