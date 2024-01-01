// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
// test
import "forge-std/Test.sol";
import { AddressBook } from "./Tools/AddressBook.sol";
import { MockERC20Token } from "./Tools/MockERC20Token.sol";

import { IUniswapV2Router02 } from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { DecentFolio } from "../src/DecentFolio/DecentFolio.sol";
import { DecentFolioManager } from "../src/DecentFolioManager/DecentFolioManager.sol";


contract DecentFolioManagerTest is Test, AddressBook {

    address private owner = makeAddr("owner");
    
    address private folioAdmin = makeAddr("folioAdmin");
    address private basedTokenAddress = _usdt;
    address[] private targetTokenAddress = [_chainlink, _pepe, _uni, _wbtc];
    uint256[] private targetTokenPercentage = [10, 20, 30, 40];
    
    address[] private notERC20TargetTokenAddresses = [_chainlink, _pepe, _uni, makeAddr("mockToken")];
    address[] private notUniSwapV2PairTargetTokenAddresses;
    uint256[] private wrongLengthTargetTokenPercentage = [10, 10, 10, 30, 40];
    uint256[] private wrongSumTargetTokenPercentage = [10, 20, 20, 40];

    DecentFolioManager decentFolioManager;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        vm.startPrank(owner);
        decentFolioManager = new DecentFolioManager(
            _uniswapV2Router,
            _uniswapV2Factory
        );
        vm.stopPrank();
    }

    function test_Constructor() public {
        assertEq(
            decentFolioManager.owner(),
            owner
        );
        assertEq(
            decentFolioManager.uniswapRouterAddress(),
            _uniswapV2Router
        );
        assertEq(
            decentFolioManager.uniswapFactoryAddress(),
            _uniswapV2Factory
        );
    }

    function test_CreateDecentFolio_BasedTokenNotERC20() public {
        address mockAddress = makeAddr("mockAddress");

        vm.startPrank(folioAdmin);
        vm.expectRevert("The based token must be ERC20");
        decentFolioManager.createERC20BasedFolio(
            mockAddress, 
            targetTokenAddress, 
            targetTokenPercentage
        );
        vm.stopPrank();        
    }

    function test_CreateDecentFolio_TargetTokenEmpty() public {
        address[] memory emptyAddresses = new address[](0);

        vm.startPrank(folioAdmin);
        vm.expectRevert("The input of target tokens cannot be empty");
        decentFolioManager.createERC20BasedFolio(
            basedTokenAddress, 
            emptyAddresses, 
            targetTokenPercentage
        );
        vm.stopPrank();        
    }

    function test_CreateDecentFolio_TargetTokenAddressesAndPercentagesDifferentLength() public {
        vm.startPrank(folioAdmin);
        vm.expectRevert("The length of target token addresses and target token percentages must be the same");
        decentFolioManager.createERC20BasedFolio(
            basedTokenAddress, 
            targetTokenAddress, 
            wrongLengthTargetTokenPercentage
        );
        vm.stopPrank();
    }

    function test_CreateDecentFolio_WrongTargetPercentagesSum() public {
        vm.startPrank(folioAdmin);
        vm.expectRevert("The sum of target token percentages must equal to 100");
        decentFolioManager.createERC20BasedFolio(
            basedTokenAddress, 
            targetTokenAddress, 
            wrongSumTargetTokenPercentage
        );
        vm.stopPrank();
    }

    function test_CreateDecentFolio_TargetTokenNotERC20() public {
        vm.startPrank(folioAdmin);
        vm.expectRevert("The target token must be ERC20");
        decentFolioManager.createERC20BasedFolio(
            basedTokenAddress, 
            notERC20TargetTokenAddresses, 
            targetTokenPercentage
        );
        vm.stopPrank();
    }

    function test_CreateDecentFolio_TargetTokenNotInUniSwapPair() public {
        vm.startPrank(folioAdmin);
        MockERC20Token mockERC20 = new MockERC20Token("mockTargetToken", "mTT");
        notUniSwapV2PairTargetTokenAddresses.push(_chainlink);
        notUniSwapV2PairTargetTokenAddresses.push(_pepe);
        notUniSwapV2PairTargetTokenAddresses.push(_uni);
        notUniSwapV2PairTargetTokenAddresses.push(address(mockERC20));

        vm.expectRevert("Cannot find the pair of based token and target token in Uniswap V2");
        decentFolioManager.createERC20BasedFolio(
            basedTokenAddress, 
            notUniSwapV2PairTargetTokenAddresses, 
            targetTokenPercentage
        );
        vm.stopPrank();
    }
}