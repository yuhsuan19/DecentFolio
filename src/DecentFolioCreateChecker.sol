// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IUniswapV2Factory } from "../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

abstract contract DecentFolioCreateChecker {

    function _checkBasedTokenAndTargetTokens(
        address _basedTokenAddress,
        address[] memory _targetTokenAddresses,
        uint256[] memory _targetTokenPercentages,
        address _uniswapFactoryAddress
    ) internal {
        _checkBasedToken(_basedTokenAddress);
        _checkTargeTokensLength(
            _targetTokenAddresses,
            _targetTokenPercentages
        );
        _checkSumOfTargetTokenPercentages(_targetTokenPercentages);
        _checkTargetTokens(
            _basedTokenAddress,
            _targetTokenAddresses,
            _uniswapFactoryAddress
        );
    }

     function _checkBasedToken(
        address _basedTokenAddress
    ) private {
        require(
            _checkIsERC20(_basedTokenAddress),
            "The based token must be ERC20"
        );
    }

    function _checkTargeTokensLength(
        address[] memory _targetTokenAddresses,
        uint256[] memory _targetTokenPercentages
    ) pure private {
        require((
            _targetTokenAddresses.length != 0), 
            "The input of target tokens cannot be empty"
        );
        require((
            _targetTokenAddresses.length <= 50), 
            "The max number of target tokens is 50"
        );
        require(
            (_targetTokenAddresses.length == _targetTokenPercentages.length), 
            "The length of target token addresses and target token percentages must be the same"
        );
    }

    function _checkSumOfTargetTokenPercentages(
        uint256[] memory _targetTokenPercentages
    ) pure private {
        uint256 sum;
        for (uint256 i = 0; i < _targetTokenPercentages.length; i++) {
            sum += _targetTokenPercentages[i];
        }
        require(
            sum == 100, 
            "The sum of target token percentages must equal to 100"
        );
    }

    function _checkTargetTokens(
        address _basedTokenAddress,
        address[] memory _targetTokenAddresses,
        address _uniswapFactoryAddress
    ) private {
        IUniswapV2Factory factory = IUniswapV2Factory(_uniswapFactoryAddress);
        for (uint256 i = 0; i < _targetTokenAddresses.length; i++) {
            address targetTokenAddress = _targetTokenAddresses[i];
            require(
                _checkIsERC20(targetTokenAddress),
                "The target token must be ERC20"
            );
            address pairAddress = factory.getPair(_basedTokenAddress, targetTokenAddress);
            require(
                pairAddress != address(0),
                "Cannot find the pair of based token and target token in Uniswap V2"
            );
        }
    }
    
    function _checkIsERC20(
        address _address
    ) internal returns (bool) {
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