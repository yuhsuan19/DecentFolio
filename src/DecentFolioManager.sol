// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IUniswapV2Router02 } from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { DecentFolio } from "./DecentFolio.sol";

contract DecentFolioManager {
    
    address public owner;
    address public uniswapRouterAddress;
    IUniswapV2Router02 uniswapRouter;

    DecentFolio[] public decentFolios;

    constructor(
        address _uniSwapRouterAddress
    ) {
        owner = msg.sender;
        uniswapRouterAddress = _uniSwapRouterAddress;
        uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
    }

    function createERC20BasedFolio(
        string memory _folioTokenName, 
        string memory _folioTokenSymbol,
        address _basedTokenAddress,
        address[] memory _targetTokenAddresses,
        uint256[] memory _targetTokenPercentages
    ) external returns (uint256) {
        _checkBasedToken(_basedTokenAddress);
        _checkTargetTokens(
            _targetTokenAddresses, 
            _targetTokenPercentages
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

    function _checkBasedToken(address _basedTokenAddress) private {
        require(
            _checkIsERC20(_basedTokenAddress),
            "The based token must be ERC20"
        );
    }

    function _checkTargetTokens(
        address[] memory _targetTokenAddresses,
        uint256[] memory _targetTokenPercentages
    ) private {
        require(
            (_targetTokenAddresses.length == _targetTokenPercentages.length), 
            "The length of target token addresses and target token percentages must be the same"
        );
        require(
            _checkSumOfTargetTokenPercentages(_targetTokenPercentages),
            "The sum of target token percentages must equal to 100"
        );
    }

    function _checkSumOfTargetTokenPercentages(uint256[] memory _targetTokenPercentages) private returns (bool) {
        uint256 sum;
        for (uint256 i = 0; i < _targetTokenPercentages.length; i++) {
            sum += _targetTokenPercentages[i];
        }
        return (sum == 100);
    }
    
    function _checkIsERC20(address _address) private returns (bool) {
        uint size;
        assembly {
            size := extcodesize(_address)
        }

        if (size <= 0) {
            return false;
        } else {
          (bool success,) = _address.call(abi.encodeWithSignature("totalSupply()"));
          return success;
        }
    }
}