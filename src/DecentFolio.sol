// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IUniswapV2Factory } from "../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { DecentFolioStorage } from "./DecentFolioStorage.sol";

contract DecentFolio is ERC721, DecentFolioStorage {

    constructor(
        string memory _tokenName, 
        string memory _symbol,
        address _basedTokenAddress,
        address[] memory _targetTokenAddresses,
        uint256[] memory _targetTokenPercentages
    ) ERC721(
        _tokenName, 
        _symbol
    ) 
    DecentFolioStorage(
        _basedTokenAddress, 
        _targetTokenAddresses, 
        _targetTokenPercentages
    ) {

    }

    function inveset(uint256 amount) external {

    }
}