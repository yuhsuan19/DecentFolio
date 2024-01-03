// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IUniswapV2Router01 } from "../../lib/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

import { InvestmentTarget, DecentFolioStorage } from "./DecentFolioStorage.sol";
import { AdminOnly } from "./Utilities/AdminOnly.sol";

contract DecentFolio is ERC721, DecentFolioStorage, AdminOnly {

    modifier isInitialized {
        require(
            initialized,
            "Not intialized"
        );
        _;
    }

    constructor() ERC721(
        "DecentFolioImplementation", 
        "DF"
    ) {}

    function initialize(
        address _basedTokenAddress,
        address[] memory _targetTokenAddresses,
        uint256[] memory _targetTokenPercentages,
        address _uniswapV2RouterAddress
    ) public {
        basedTokenAddress = _basedTokenAddress;
        basedToken = IERC20(_basedTokenAddress);
        initializeInvestmentTargets(
            _targetTokenAddresses, 
            _targetTokenPercentages
        );
        uniswapV2RouterAddress = _uniswapV2RouterAddress;
        uniswapV2Router = IUniswapV2Router01(uniswapV2RouterAddress);

        initialized = true;
    }

    function inveset(
        uint256 _amount, // 1000 e6
        uint256 _timestamp
    ) external isInitialized {
        basedToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        for (uint256 index; index < investmentTargets.length; index ++) {
            (address _targetAddress, uint256 _percentage) = investmentTarget(index);

            uint256 _amountIn = _amount * _percentage / 100;

            address[] memory _path = new address[](2);
            _path[0] = basedTokenAddress;
            _path[1] = _targetAddress;

            uint256 _balBeforeSwap = IERC20(_targetAddress).balanceOf(address(this));
            basedToken.approve(
                uniswapV2RouterAddress, 
                _amountIn
            );
            uint256[] memory _swapAmounts = uniswapV2Router.swapExactTokensForTokens(
                _amountIn, 
                0, 
                _path, 
                address(this), 
                block.timestamp
            );
            uint256 _balAfterSwap = IERC20(_targetAddress).balanceOf(address(this));
            require(
                (_balAfterSwap == _balBeforeSwap + _swapAmounts[1]), 
                "Fail to swap"
            );
        }
    }

    function flashLoan() external isInitialized {

    }

    function initializeInvestmentTargets(
        address[] memory _targetTokenAddresses,
        uint256[] memory _targetTokenPercentages
    ) internal {
        for (uint256 i = 0; i < _targetTokenAddresses.length; i++) {
            InvestmentTarget memory target = InvestmentTarget(
                _targetTokenAddresses[i],
                _targetTokenPercentages[i]
            );
            investmentTargets.push(target);
        }
    }
}