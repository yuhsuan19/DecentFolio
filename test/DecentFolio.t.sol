// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { MockERC20Token } from "./MockERC20Token.sol";

import { DecentFolio } from "../src/DecentFolio.sol";

contract DecentFolioTest is Test {
    string testTokenName = "TestTokenName";
    string testTokenSymbol = "TestTokenSymbol";

    address admin = makeAddr("admin");
    MockERC20Token mockBasedToken = new MockERC20Token("mockBasedToken", "mockBT");
    MockERC20Token mockTargetToken_A = new MockERC20Token("mockTargetToken_A", "mTT_A");
    MockERC20Token mockTargetToken_B = new MockERC20Token("mockTargetToken_B", "mTT_B");
    MockERC20Token mockTargetToken_C = new MockERC20Token("mockTargetToken_C", "mTT_C");
    MockERC20Token mockTargetToken_D = new MockERC20Token("mockTargetToken_D", "mTT_D");

    address[] mockInvestTargetAddresses = [address(mockTargetToken_A), address(mockTargetToken_B), address(mockTargetToken_C), address(mockTargetToken_D)];
    uint256[] mockInvestTargetPercentages = [10, 20, 30, 40];

    function setUp() public {}

    function test_ConstructorLocal() public {
        DecentFolio testFolio;

        vm.startPrank(admin);
        testFolio = new DecentFolio(
            testTokenName, 
            testTokenSymbol, 
            address(mockBasedToken),
            mockInvestTargetAddresses,
            mockInvestTargetPercentages
        );
        vm.stopPrank();

        assertEq(testFolio.name(), testTokenName);
        assertEq(testFolio.symbol(), testTokenSymbol);
        assertEq(testFolio.basedTokenAddress(), address(mockBasedToken));
        assertEq(testFolio.admin(), admin);
        for (uint256 i; i < mockInvestTargetAddresses.length; i++) {
            (address targetTokenAddress, uint256 percentage) = testFolio.investmentTarget(i);
            address mockTargetTokenAddress = mockInvestTargetAddresses[i];
            uint256 mockTargetPercentage = mockInvestTargetPercentages[i];
            assertEq(targetTokenAddress, mockTargetTokenAddress);
            assertEq(percentage, mockTargetPercentage);
        }
    }
}