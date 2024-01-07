// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AddressBook } from "./Tools/AddressBook.sol";

import { IUniswapV2Router01 } from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import { IUniswapV2Factory } from "../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from"../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import { DecentFolio } from "../src/DecentFolio/DecentFolio.sol";
import { DecentFolioManager } from "../src/DecentFolioManager/DecentFolioManager.sol";

contract DAOTest is Test, AddressBook {

    address private owner;
    address private investor_0;
    address private investor_1;
    address private investor_2;
    address private maker;

    address private basedTokenAddress = _usdc;
    ERC20 private basedToken;
    address[] private targetTokenAddress = [_chainlink, _uni];
    uint256[] private targetTokenPercentage = [60, 40];
    uint256 private flashLoanInterestRate = 30;
    uint256 private propsalExecutedThreshold = 60;

    DecentFolioManager decentFolioManager;
    DecentFolio decentFolio;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 18952963);

        basedToken = ERC20(basedTokenAddress);
        owner = makeAddr("owner");
        deal(owner, 1_000 ether);
        
        investor_0 = makeAddr("investor_0");
        deal(investor_0, 1_000 ether);
        deal(basedTokenAddress, investor_0, 1_000 * 10 ** basedToken.decimals());

        investor_1 = makeAddr("investor_1");
        deal(investor_1, 1_000 ether);
        deal(basedTokenAddress, investor_1, 1_000 * 10 ** basedToken.decimals());

        investor_2 = makeAddr("investor_2");
        deal(investor_2, 1_000 ether);
        deal(basedTokenAddress, investor_2, 1_000 * 10 ** basedToken.decimals());

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

        vm.startPrank(investor_0);
        basedToken.approve(
            address(decentFolio), 
            1_000 * 10 ** basedToken.decimals()
        );
        decentFolio.inveset(
            1_000 * 10 ** basedToken.decimals(),
            1_000
        );
        vm.stopPrank();

        vm.startPrank(investor_1);
        basedToken.approve(
            address(decentFolio), 
            1_000 * 10 ** basedToken.decimals()
        );
        decentFolio.inveset(
            1_000 * 10 ** basedToken.decimals(),
            1_000
        );
        vm.stopPrank();

        vm.startPrank(investor_2);
        basedToken.approve(
            address(decentFolio), 
            1_000 * 10 ** basedToken.decimals()
        );
        decentFolio.inveset(
            1_000 * 10 ** basedToken.decimals(),
            1_000
        );
        vm.stopPrank();
    }

    function test_ProposeSetNewFlashLoanInterestRate_notHolder() public {
        address user = makeAddr("user");
        vm.startPrank(user);
        vm.expectRevert("Only the holders of this decentFolio can propose change");
        decentFolioManager.proposeSetNewFlashLoanInterestRate(
            0, 
            0, 
            50
        );
        vm.stopPrank();
    }

    function test_ProposeSetNewFlashLoanInterestRate() public {
        vm.startPrank(investor_0);
        uint256 _proposalIndex = decentFolioManager.proposeSetNewFlashLoanInterestRate(
            0, 
            0, 
            50
        );
        vm.stopPrank();

        (uint256 _folioIndex, uint256 _newInterestRate, uint256 _proposedTimestamp) = decentFolioManager.newFlashLoanInterestRateProposalOf(_proposalIndex);
        assertEq(_folioIndex, 0);
        assertEq(_newInterestRate, 50);
        assertEq(_proposedTimestamp, block.timestamp);
    }

    function test_Vote_WrongProposalIndex() public {
        vm.startPrank(investor_0);
        uint256 _proposalIndex = decentFolioManager.proposeSetNewFlashLoanInterestRate(
            0, 
            0, 
            50
        );
        vm.stopPrank();

        vm.startPrank(investor_0);
        vm.expectRevert("Wrogn proposal index");
        decentFolioManager.voteSetNewFlashLoanInterestRate(
            _proposalIndex + 1, 
            0
        );
        vm.stopPrank();
    }

    function test_Vote_Expired() public {
        vm.startPrank(investor_0);
        uint256 _proposalIndex = decentFolioManager.proposeSetNewFlashLoanInterestRate(
            0, 
            0, 
            50
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 3601);

        vm.startPrank(investor_0);
        vm.expectRevert("The voting is already ended");
        decentFolioManager.voteSetNewFlashLoanInterestRate(
            _proposalIndex, 
            0
        );
        vm.stopPrank();
    }

    function test_Vote_WrongTokenId() public {
        vm.startPrank(investor_0);
        uint256 _proposalIndex = decentFolioManager.proposeSetNewFlashLoanInterestRate(
            0, 
            0, 
            50
        );
        vm.stopPrank();

        vm.startPrank(investor_0);
        vm.expectRevert("Only the holders of this decentFolio can vote");
        decentFolioManager.voteSetNewFlashLoanInterestRate(
            _proposalIndex, 
            1
        );
        vm.stopPrank();
    }

    function test_Vote_doubleVoting() public {
        vm.startPrank(investor_0);
        uint256 _proposalIndex = decentFolioManager.proposeSetNewFlashLoanInterestRate(
            0, 
            0, 
            50
        );
        vm.stopPrank();

        vm.startPrank(investor_0);
        decentFolioManager.voteSetNewFlashLoanInterestRate(
            _proposalIndex, 
            0
        );
        vm.stopPrank();

        vm.startPrank(investor_0);
        vm.expectRevert("This token id has already voted");
        decentFolioManager.voteSetNewFlashLoanInterestRate(
            _proposalIndex, 
            0
        );
        vm.stopPrank();
    }

    function test_Vote() public {
        vm.startPrank(investor_0);
        uint256 _proposalIndex = decentFolioManager.proposeSetNewFlashLoanInterestRate(
            0, 
            0, 
            50
        );
        vm.stopPrank();

        vm.startPrank(investor_0);
        decentFolioManager.voteSetNewFlashLoanInterestRate(
            _proposalIndex, 
            0
        );
        vm.stopPrank();

        uint256 tokenId = decentFolioManager.interestRateVoteTokenIds(_proposalIndex, 0);
        assertEq(tokenId, 0);
    }

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

    function test_Execute_WrongProposalIndex() public {
        uint256 _proposalIndex = proposeAndVote();
        vm.expectRevert("Wrogn proposal index");
        decentFolioManager.executeSetNewFlashLoanInterestRate(_proposalIndex + 1);
    }

    function test_Execute_TooEarly() public {
        uint256 _proposalIndex = proposeAndVote();
        vm.warp(block.timestamp + 3599);
        vm.expectRevert("The proposal is still in voting");
        decentFolioManager.executeSetNewFlashLoanInterestRate(_proposalIndex);
    }

    function test_Execute_DidNotPass() public {
        uint256 _proposalIndex = proposeAndVote();
        vm.warp(block.timestamp + 3601);
        vm.expectRevert("The vote result did not pass the threshold");
        decentFolioManager.executeSetNewFlashLoanInterestRate(_proposalIndex);
    }

    function test_Execute() public {
        uint256 _proposalIndex = proposeAndVote();
        vm.startPrank(investor_1);
        decentFolioManager.voteSetNewFlashLoanInterestRate(
            _proposalIndex, 
            1
        );
        vm.stopPrank();
        vm.warp(block.timestamp + 3601);
        decentFolioManager.executeSetNewFlashLoanInterestRate(_proposalIndex);
        assertEq(decentFolio.flashLoanInterestRate(), 50);
    }

    function proposeAndVote() private returns (uint256 _propsalIndex) {
        vm.startPrank(investor_0);
        uint256 _proposalIndex = decentFolioManager.proposeSetNewFlashLoanInterestRate(
            0, 
            0, 
            50
        );
        vm.stopPrank();

        vm.startPrank(investor_0);
        decentFolioManager.voteSetNewFlashLoanInterestRate(
            _proposalIndex, 
            0
        );
        vm.stopPrank();

        return _proposalIndex;
    }
}