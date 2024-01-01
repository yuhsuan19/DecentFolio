// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IUniswapV2Router02 } from "../../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

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
        // DecentFolioStorage
        basedTokenAddress = _basedTokenAddress;
        initializeInvestmentTargets(
            _targetTokenAddresses, 
            _targetTokenPercentages
        );
        uniswapV2RouterAddress = _uniswapV2RouterAddress;
        uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);
    }

    function inveset(uint256 amount) external isInitialized {

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