// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Router01 } from "../../lib/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

struct InvestmentTarget {
    address tokenAddress;
    uint256 percentage; // The percentage of the target
}

abstract contract DecentFolioStorage {
    address public basedTokenAddress;
    IERC20 basedToken;
    InvestmentTarget[] public investmentTargets;
    
    address public uniswapV2RouterAddress;
    IUniswapV2Router01 uniswapV2Router;

    bool public initialized;

    function investmentTarget(uint256 index) public view returns (address, uint256) {
        InvestmentTarget memory target = investmentTargets[index];
        return (target.tokenAddress, target.percentage);
    }
}