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

    uint256 public totalSupply; //Note: Increase with mint, do not decrease with burn.

    uint256 public totalBasedTokenAmount;
    mapping(uint256 totkenId => uint256) public basedTokenAmounts;
    uint256 public totalLockedTimeInterval;
    mapping(uint256 tokenId => uint256) public lockedTimeIntervals;
    mapping(uint256 tokenId => uint256) public unlockedTimeStamps;

    mapping(address targetTokenAddress => uint256) public totalInvestTokenAmounts;
    mapping(uint256 totkenId => mapping(address targetTokenAddress => uint256)) public investTokenAmounts;

    mapping(address targetTokenAddress => uint256) public totalProfitTokenAmounts;

    uint256 public flashLoanInterestRate; // Note: will be multiplied by 0.0001

    uint256 public proposalExectedThreshold;

    bool public initialized;
    bool reentrancyLocked;

    function investmentTarget(
        uint256 index
    ) public view returns (address targetTokenAddress, uint256 targetTokenPercentage) {
        InvestmentTarget memory target = investmentTargets[index];
        return (target.tokenAddress, target.percentage);
    }

    function basedTokenAmountOf(
        uint256 _tokenId
    ) public view returns (uint256) {
        return basedTokenAmounts[_tokenId];
    }

    function lockedTimeIntervalOf(
        uint256 _tokenId
    ) public view returns (uint256) {
        return lockedTimeIntervals[_tokenId];
    }

    function unlockedTimeStampOf(
        uint256 _tokenId
    ) public view returns (uint256) {
        return unlockedTimeStamps[_tokenId];
    }

    function totalInvestTokenAmountOf(
        address _tokenAddress
    ) public view returns (uint256) {
        return totalInvestTokenAmounts[_tokenAddress];
    }

    function investTokenAmountOf(
        uint256 _tokenId,
        address _tokenAddress
    ) public view returns (uint256) {
        return investTokenAmounts[_tokenId][_tokenAddress];
    }

    function totalProfitTokenAmountOf(
        address _tokenAddress
    ) public view returns (uint256) {
        return totalProfitTokenAmounts[_tokenAddress];
    }
}