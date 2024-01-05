// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { DecentFolioCreateChecker } from "./DecentFolioCreateChecker.sol";

import { IUniswapV2Router01 } from "../../lib/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import { IUniswapV2Factory } from "../../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import { DecentFolio } from "../DecentFolio/DecentFolio.sol";
import { DecentFolioProxy } from "../DecentFolio/DecentFolioProxy.sol";

contract DecentFolioManager is DecentFolioCreateChecker {
    
    address public owner;
    address public immutable uniswapRouterAddress;
    IUniswapV2Router01 immutable uniswapRouter;
    address public immutable uniswapFactoryAddress;
    IUniswapV2Factory immutable uniswapFactory;

    address implementationAddress;
    address[] public decentFolios;

    constructor(
        address _uniSwapRouterAddress,
        address _uniswapFactoryAddress
    ) {
        owner = msg.sender;
        uniswapRouterAddress = _uniSwapRouterAddress;
        uniswapRouter = IUniswapV2Router01(uniswapRouterAddress);
        uniswapFactoryAddress = _uniswapFactoryAddress;
        uniswapFactory = IUniswapV2Factory(uniswapFactoryAddress);

        DecentFolio implementation = new DecentFolio();
        implementationAddress = address(implementation);
    }

    function createERC20BasedFolio(
        address _basedTokenAddress,
        address[] memory _targetTokenAddresses,
        uint256[] memory _targetTokenPercentages
    ) external returns (uint256 index) {
        _checkBasedTokenAndTargetTokens(
            _basedTokenAddress,
            _targetTokenAddresses, 
            _targetTokenPercentages,
            uniswapFactoryAddress
        );

        bytes memory initialCallData = abi.encodeWithSignature(
            "initialize(address,address[],uint256[],address)", 
            _basedTokenAddress, 
            _targetTokenAddresses, 
            _targetTokenPercentages, 
            uniswapRouterAddress
        );
        DecentFolioProxy proxy = new DecentFolioProxy(
            implementationAddress,
            initialCallData
        );
        decentFolios.push(address(proxy));

        // return the index of new created folio
        return decentFolios.length - 1;
    }

    function decentFolio(
        uint256 _index
    ) view public returns (address decentFolioAddress) {
        require(
            _index < decentFolios.length,
            "The index of DecentFolio not exist"
        );
        address _decentFolioAddress = decentFolios[_index];
        return _decentFolioAddress;
    }
}