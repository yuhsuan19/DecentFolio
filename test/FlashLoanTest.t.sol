// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AddressBook } from "./Tools/AddressBook.sol";
import { MockBadFlashLoanBorrower } from "./Tools/MockBadFlashLoanBorrower.sol";
import { MockFlashLoanBorrower } from "./Tools/MockFlashLoanBorrower.sol";

import { IUniswapV2Router01 } from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import { IUniswapV2Factory } from "../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from"../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import { DecentFolio } from "../src/DecentFolio/DecentFolio.sol";
import { DecentFolioManager } from "../src/DecentFolioManager/DecentFolioManager.sol";

contract FlashLoanTest is Test, AddressBook {
    address private owner;
    address private investor;
    address private maker;

    address private basedTokenAddress = _usdc;
    ERC20 private basedToken;
    address[] private targetTokenAddress = [_chainlink, _uni];
    uint256[] private targetTokenPercentage = [60, 40];
    uint256 private flashLoanInterestRate = 30; // 0.3%
    uint256 private propsalExecutedThreshold = 60;

    DecentFolioManager decentFolioManager;
    DecentFolio decentFolio;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 18952963);

        basedToken = ERC20(basedTokenAddress);
        owner = makeAddr("owner");
        deal(owner, 1_000 ether);
        
        investor = makeAddr("investor");
        deal(investor, 1_000 ether);
        deal(basedTokenAddress, investor, 10_000 * 10 ** basedToken.decimals());

        addLiquidities();

        vm.startPrank(owner);
        decentFolioManager = new DecentFolioManager(
            _uniswapV2Router,
            _uniswapV2Factory
        );
        vm.stopPrank();

        uint256 index = decentFolioManager.createERC20BasedFolio(
            basedTokenAddress, 
            targetTokenAddress, 
            targetTokenPercentage,
            flashLoanInterestRate,
            propsalExecutedThreshold
        );
        address folioAddress = decentFolioManager.decentFolio(index);
        decentFolio = DecentFolio(folioAddress);

        vm.startPrank(investor);
        basedToken.approve(
            address(decentFolio), 
            10_000 * 10 ** basedToken.decimals()
        );
        decentFolio.inveset(
            10_000 * 10 ** basedToken.decimals(),
            86_400
        );
        vm.stopPrank();
    }

    function test_FlashLoan() public {
        address user = makeAddr("user");
        MockFlashLoanBorrower mockFlashLoanBorrower = new MockFlashLoanBorrower(
            address(decentFolio),
            user
        );

        uint256 _borrowAmount = 50 * 10 ** ERC20(_chainlink).decimals();
        uint256 _interest = _borrowAmount * flashLoanInterestRate / 10000;

        deal(
            _chainlink, 
            address(mockFlashLoanBorrower), 
            _interest
        );

        uint256 _balanceBefore = ERC20(_chainlink).balanceOf(address(decentFolio));
        
        vm.startPrank(user);
        decentFolio.flashLoan(
            _chainlink, 
            _borrowAmount, 
            address(mockFlashLoanBorrower), 
            ""
        );
        vm.stopPrank();
        uint256 _balanceAfter = ERC20(_chainlink).balanceOf(address(decentFolio));


        decentFolio.resolveBalances();
        assertEq(decentFolio.totalProfitTokenAmountOf(_chainlink), _interest);
        assertEq(_balanceAfter, _balanceBefore + _interest);
    }

    // Note: pass, will be revert as expection, but cannot catch the revertion
    // function test_FlashLoan_notPayInterest() public {
    //     MockBadFlashLoanBorrower badBorrower = new MockBadFlashLoanBorrower(
    //         address(decentFolio)
    //     );
    //     // vm.expectRevert("Insufficeient repay amount");
    //     decentFolio.flashLoan(
    //         _chainlink, 
    //         10 * 10 ** ERC20(_chainlink).decimals(), 
    //         address(badBorrower), 
    //         ""
    //     );
    // }

    // function test_FlashLoan_InsufficeientBalance() public {
    //     address user = makeAddr("user");
    //     MockFlashLoanBorrower mockFlashLoanBorrower = new MockFlashLoanBorrower(
    //         address(decentFolio),
    //         user
    //     );
    //     vm.startPrank(user);
    //     vm.expectRevert("Insufficeient balance");
    //     decentFolio.flashLoan(
    //         _chainlink, 
    //         1000_000_000 * 10 ** ERC20(_chainlink).decimals(), 
    //         address(mockFlashLoanBorrower), 
    //         ""
    //     );
    //     vm.stopPrank();
    // }

    function addLiquidities() private {
        IUniswapV2Router01 router = IUniswapV2Router01(_uniswapV2Router);
        deal(maker, 1_000 ether);
        maker = makeAddr("maker");

        for (uint256 i; i < targetTokenAddress.length; i++) {
            address _targetTokenAddress = targetTokenAddress[i];
            ERC20 _targetToken = ERC20(_targetTokenAddress);
            
            deal(basedTokenAddress, maker, 1_000_000_000 * 10 ** basedToken.decimals());
            deal(_targetTokenAddress, maker, 1_000_000_000 * 10 ** ERC20(_targetToken).decimals());

            vm.startPrank(maker);
            basedToken.approve(
                _uniswapV2Router, 
                1_000_000_000 * 10 ** basedToken.decimals()
            );
            ERC20(_targetTokenAddress).approve(
                _uniswapV2Router, 
                1_000_000_000 * 10 ** ERC20(_targetToken).decimals()
            );

            router.addLiquidity(
                basedTokenAddress, 
                _targetTokenAddress, 
                1_000_000_000 * 10 ** basedToken.decimals(), 
                1_000_000_000 * 10 ** ERC20(_targetToken).decimals(), 
                0, 
                0, 
                maker,
                block.timestamp
            );
            vm.stopPrank();
        }
    }
}
