// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
// test
import "forge-std/Test.sol";
import { AddressBook } from "./Tools/AddressBook.sol";

import { IUniswapV2Router02 } from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { DecentFolio } from "../src/DecentFolio.sol";
import { DecentFolioManager } from "../src/DecentFolioManager.sol";


contract DecentFolioManagerTest is Test, AddressBook {

    address private owner = makeAddr("owner");

    DecentFolioManager decentFolioManager;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        vm.startPrank(owner);
        decentFolioManager = new DecentFolioManager(
            _uniswapV2Router
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
    }
}