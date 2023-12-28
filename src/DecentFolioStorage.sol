// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IUniswapV2Factory } from "../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

struct InvestmentTarget {
    address tokenAddress;
    uint256 percentage; // The percentage of the target
}

abstract contract DecentFolioStorage {
    address constant _Uniswap_V2_Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    IUniswapV2Factory uniSwapV2Factory = IUniswapV2Factory(_Uniswap_V2_Factory);

    address public admin;

    address immutable public basedTokenAddress;
    InvestmentTarget[] public investmentTargets;

    constructor(
        address _basedTokenAddress,
        address[] memory _targetTokenAddresses,
        uint256[] memory _targetTokenPercentages
    ) {
        admin = msg.sender;
        basedTokenAddress = _basedTokenAddress; // todo: check isERC20
    
        require(
            checkSumOfTargetTokenPercentages(_targetTokenPercentages),
            "Then sum of target token percentages must equal to 100"
        );
        initializeInvestmentTargets(_targetTokenAddresses, _targetTokenPercentages);
    }

    function investmentTarget(uint256 index) public view returns (address, uint256) {
        InvestmentTarget memory target = investmentTargets[index];
        return (target.tokenAddress, target.percentage);
    }

    function checkSumOfTargetTokenPercentages(uint256[] memory _targetTokenPercentages) internal pure returns (bool) {
        uint256 sum;
        for (uint256 i = 0; i < _targetTokenPercentages.length; i++) {
            sum += _targetTokenPercentages[i];
        }
        return (sum == 100);
    }

    function initializeInvestmentTargets(
        address[] memory _targetTokenAddresses,
        uint256[] memory _targetTokenPercentages
    ) internal {
         require(
            (_targetTokenAddresses.length == _targetTokenPercentages.length), 
            "The length of target token addresses and target token percentages must be the same"
        );
        for (uint256 i = 0; i < _targetTokenAddresses.length; i++) {
            InvestmentTarget memory target = InvestmentTarget(
                _targetTokenAddresses[i], // todo: check isERC20
                _targetTokenPercentages[i]
            );
            investmentTargets.push(target);
        }
    }
}