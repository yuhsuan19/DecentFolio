// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { DecentFolioCreateChecker } from "./DecentFolioCreateChecker.sol";

import { IUniswapV2Router01 } from "../../lib/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import { IUniswapV2Factory } from "../../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import { DecentFolio } from "../DecentFolio/DecentFolio.sol";
import { DecentFolioProxy } from "../DecentFolio/DecentFolioProxy.sol";

contract DecentFolioManager is DecentFolioCreateChecker {

    struct FlashLoanInterestRateProposal {
        uint256 folioIndex;
        uint256 proposedTimestamp;
        uint256 newInterestRate;
    }
    
    address public owner;
    address public immutable uniswapRouterAddress;
    IUniswapV2Router01 immutable uniswapRouter;
    address public immutable uniswapFactoryAddress;
    IUniswapV2Factory immutable uniswapFactory;
    
    address implementationAddress;
    address[] public decentFolios;

    uint256 constant votingTimeInterval = 3600;
    FlashLoanInterestRateProposal[] interestRateProposals;
    mapping(uint256 proposalIndex => uint256[]) interestRateVoteTokenIds;

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
        uint256[] memory _targetTokenPercentages,
        uint256 _flashLoanInterestRate,
        uint256 _propsalExecutedThreshold
    ) external returns (uint256 index) {
        _checkBasedTokenAndTargetTokens(
            _basedTokenAddress,
            _targetTokenAddresses, 
            _targetTokenPercentages,
            uniswapFactoryAddress
        );

        bytes memory initialCallData = abi.encodeWithSignature(
            "initialize(address,address[],uint256[],address,uint256,uint256)", 
            _basedTokenAddress, 
            _targetTokenAddresses, 
            _targetTokenPercentages, 
            uniswapRouterAddress,
            _flashLoanInterestRate,
            _propsalExecutedThreshold
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

    function proposeSetNewFlashLoanInterestRate(
        uint256 _folioIndex,
        uint256 _tokenId,
        uint256 _newInterestRate
    ) external {
        DecentFolio folio = DecentFolio(decentFolios[_folioIndex]);
        require(
            folio.ownerOf(_tokenId) == msg.sender,
            "Only the holders of this decentFolio can propose change"
        );

        FlashLoanInterestRateProposal memory proposl = FlashLoanInterestRateProposal(
            _folioIndex,
            _newInterestRate,
            block.timestamp
        );

        interestRateProposals.push(proposl);
    }

    function voteSetNewFlashLoanInterestRate(
        uint256 _proposalIndex,
        uint256 _tokenId
    ) external {
        require(
            _proposalIndex < interestRateProposals.length,
            "Wrogn proposal index"
        );
        
        FlashLoanInterestRateProposal memory propsal = interestRateProposals[_proposalIndex];

        require(
            propsal.proposedTimestamp + votingTimeInterval > block.timestamp,
            "The voting is already ended"
        );

        DecentFolio folio = DecentFolio(decentFolios[propsal.folioIndex]);
        require(
            folio.ownerOf(_tokenId) == msg.sender,
            "Only the holders of this decentFolio can vote"
        );
        checkDoubleVote(
            _proposalIndex, 
            _tokenId
        );
        interestRateVoteTokenIds[_proposalIndex].push(_tokenId);
    }

    function executeSetNewFlashLoanInterestRat(
        uint256 _proposalIndex
    ) external {
        require(
            _proposalIndex < interestRateProposals.length,
            "Wrogn proposal index"
        );
        FlashLoanInterestRateProposal memory propsal = interestRateProposals[_proposalIndex];
        require(
            propsal.proposedTimestamp + votingTimeInterval < block.timestamp,
            "The proposal is still in voting"
        );
        DecentFolio folio = DecentFolio(decentFolios[propsal.folioIndex]);

        folio.checkExecutable(interestRateVoteTokenIds[_proposalIndex]);

        folio.setNewFlashLoanInterestRate(propsal.newInterestRate);
    }

    function checkDoubleVote(
        uint256 _proposalIndex,
        uint256 _tokenId
    ) private view {
        bool hasVote;
        for (uint256 i; i < interestRateVoteTokenIds[_proposalIndex].length; i++) {
            if (interestRateVoteTokenIds[_proposalIndex][i] == _tokenId) {
                hasVote = true;
            }
        }
        require(
            !hasVote,
            "This token id has already voted"
        );
    }
}