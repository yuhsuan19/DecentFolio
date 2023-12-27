// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { DecentFolio } from "../src/DecentFolio.sol";

contract DecentFolioTest is Test {

    address admin = makeAddr("admin");

    function setUp() public {}

    function test_Constructor() public {
        string memory testTokenName = "TestTokenName";
        string memory testTokenSymbol = "TestTokenSymbol";
        DecentFolio testFolio;

        vm.startPrank(admin);
        testFolio = new DecentFolio(testTokenName, testTokenSymbol);
        vm.stopPrank();

        assertEq(testFolio.name(), testTokenName);
        assertEq(testFolio.symbol(), testTokenSymbol);
        assertEq(testFolio.admin(), admin);
    }
}