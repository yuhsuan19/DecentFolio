// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IUniswapV2Router02 } from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Factory } from "../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { DecentFolio } from "./DecentFolio.sol";
import { DecentFolioCreateChecker } from "./DecentFolioCreateChecker.sol";

contract DecentFolioManager is DecentFolioCreateChecker {
    
    address public owner;
    address public immutable uniswapRouterAddress;
    IUniswapV2Router02 immutable uniswapRouter;
    address public immutable uniswapFactoryAddress;
    IUniswapV2Factory immutable uniswapFactory;

    DecentFolio[] public decentFolios;

    constructor(
        address _uniSwapRouterAddress,
        address _uniswapFactoryAddress
    ) {
        owner = msg.sender;
        uniswapRouterAddress = _uniSwapRouterAddress;
        uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
        uniswapFactoryAddress = _uniswapFactoryAddress;
        uniswapFactory = IUniswapV2Factory(uniswapFactoryAddress);
    }

    function createERC20BasedFolio(
        string memory _folioTokenName, 
        string memory _folioTokenSymbol,
        address _basedTokenAddress,
        address[] memory _targetTokenAddresses,
        uint256[] memory _targetTokenPercentages
    ) external returns (uint256) {
        _checkBasedTokenAndTargetTokens(
            _basedTokenAddress,
            _targetTokenAddresses, 
            _targetTokenPercentages,
            uniswapFactoryAddress
        );

        DecentFolio folio = new DecentFolio(
            _folioTokenName,
            _folioTokenSymbol,
            _basedTokenAddress,
            _targetTokenAddresses,
            _targetTokenPercentages
        );
        decentFolios.push(folio);

        // return the index of new created folio
        return decentFolios.length - 1;
    }
}