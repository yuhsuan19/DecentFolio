// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IUniswapV2Router01 } from "../../lib/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

import { InvestmentTarget, DecentFolioStorage } from "./DecentFolioStorage.sol";
import { AdminOnly } from "./Utilities/AdminOnly.sol";
import { IDecentFolioFlashLoanReceiver } from "./IDecentFolioFlashLoanReceiver.sol";

contract DecentFolio is ERC721, DecentFolioStorage, AdminOnly {

    modifier isInitialized {
        require(
            initialized,
            "Not intialized"
        );
        _;
    }

    modifier noReentrancy() {
        require(!reentrancyLocked, "ReentrancyGuard: reentrant call");
        reentrancyLocked = true;
        _;
        reentrancyLocked = false;
    }

    // Note: just for deploying implemetation contract
    constructor() ERC721(
        "DecentFolioImplementation", 
        "DF"
    ) {}

    function initialize(
        address _basedTokenAddress,
        address[] memory _targetTokenAddresses,
        uint256[] memory _targetTokenPercentages,
        address _uniswapV2RouterAddress,
        uint256 _flashLoanInterestRate
    ) public {
        basedTokenAddress = _basedTokenAddress;
        basedToken = IERC20(_basedTokenAddress);
        initializeInvestmentTargets(
            _targetTokenAddresses, 
            _targetTokenPercentages
        );
        uniswapV2RouterAddress = _uniswapV2RouterAddress;
        uniswapV2Router = IUniswapV2Router01(uniswapV2RouterAddress);
        flashLoanInterestRate = _flashLoanInterestRate;

        initialized = true;
    }

    function inveset(
        uint256 _amount,
        uint256 _lockedTimeInterval
    ) external isInitialized returns (uint256 tokenId) {
        require(
            _amount > 0,
            "The amount of investment must not be zero"
        );

        uint256 _tokenId = totalSupply;

        totalSupply = totalSupply + 1;

        totalLockedTimeInterval = totalLockedTimeInterval + _lockedTimeInterval;

        lockedTimeIntervals[_tokenId] = _lockedTimeInterval;
        unlockedTimeStamps[_tokenId] = block.timestamp + _lockedTimeInterval;

        multiSwapTargets(
            _tokenId, 
            _amount
        );

        _mint(
            msg.sender, 
            _tokenId
        );
        return _tokenId;
    }

    function fragAndTransfer(
         uint256 _tokenId,
         uint256 _transferPercentage, 
         address _to
    ) external isInitialized returns (uint256 fromTokenId, uint256 toTokenId) {

        uint256 _fromTokenId = totalSupply;
        uint256 _toTokenId = totalSupply + 1;
        totalSupply = totalSupply + 2;

        totalLockedTimeInterval = lockedTimeIntervals[_tokenId] * 2;
        lockedTimeIntervals[_fromTokenId] = lockedTimeIntervals[_tokenId];
        lockedTimeIntervals[_toTokenId] = lockedTimeIntervals[_tokenId];

        unlockedTimeStamps[_fromTokenId] = unlockedTimeStamps[_tokenId];
        unlockedTimeStamps[_toTokenId] = unlockedTimeStamps[_tokenId];

        for (uint256 index; index < investmentTargets.length; index ++) {
            (address _targetAddress,) = investmentTarget(index);
            uint256 _investAmount = investTokenAmounts[_tokenId][_targetAddress];

            uint256 _toAmount = _investAmount * _transferPercentage / 100;
            uint256 _fromAmount = _investAmount - _toAmount;

            totalInvestTokenAmounts[_targetAddress] = totalInvestTokenAmounts[_targetAddress] + _toAmount + _fromAmount;
            investTokenAmounts[_toTokenId][_targetAddress] = _toAmount;
            investTokenAmounts[_fromTokenId][_targetAddress] = _fromAmount;
        }

        burn(_tokenId);
        _mint(
            msg.sender, 
            _fromTokenId
        );
        _mint(
            _to, 
            _toTokenId
        );

        return(_fromTokenId, _toTokenId);
    }

    function redeem(
        uint256 _tokenId,
        address _receiver
    ) external isInitialized {
        require(
            ownerOf(_tokenId) == msg.sender,
            "The owner of the token id is not the msg.sneder"
        );
        require(
              unlockedTimeStamps[_tokenId] < block.timestamp,
              "This token is still under locked status"
        );
        resolveBalances();

        uint256 redeemBasedTokenAmount;
        for (uint256 index; index < investmentTargets.length; index ++) {    
            (address _targetAddress,) = investmentTarget(index);
            uint256 _balBeforeSwap = basedToken.balanceOf(address(this));

            uint256 _profit = profitAmount(
                _tokenId, 
                _targetAddress
            );
            totalProfitTokenAmounts[_targetAddress] = totalProfitTokenAmounts[_targetAddress] - _profit;

            uint256 _amountIn = investTokenAmounts[_tokenId][_targetAddress] + _profit;
            IERC20(_targetAddress).approve(
                uniswapV2RouterAddress, 
                _amountIn
            );

            address[] memory _path = new address[](2);
            _path[0] = _targetAddress;
            _path[1] = basedTokenAddress;
            uint256[] memory _swapAmounts = uniswapV2Router.swapExactTokensForTokens(
                _amountIn, 
                0, 
                _path, 
                address(this), 
                block.timestamp
            );
            uint256 _balAfterSwap = basedToken.balanceOf(address(this));
            require(
                (_balAfterSwap == _balBeforeSwap + _swapAmounts[1]), 
                "Fail to swap"
            );
            redeemBasedTokenAmount = redeemBasedTokenAmount + _swapAmounts[1];

        }
        burn(_tokenId);
        basedToken.transfer(
            _receiver, 
            redeemBasedTokenAmount
        );
    }

    // Note: the investors who want to redeem before the unlocked time have to give up the profit
    function earlyRedemm(
        uint256 _tokenId,
        address _receiver
    ) external isInitialized {
        require(
            ownerOf(_tokenId) == msg.sender,
            "The owner of the token id is not the msg.sneder"
        );
        uint256 redeemBasedTokenAmount;

        for (uint256 index; index < investmentTargets.length; index ++) {    
            (address _targetAddress,) = investmentTarget(index);
            uint256 _balBeforeSwap = basedToken.balanceOf(address(this));

            uint256 _amountIn = investTokenAmounts[_tokenId][_targetAddress];
            IERC20(_targetAddress).approve(
                uniswapV2RouterAddress, 
                _amountIn
            );

            address[] memory _path = new address[](2);
            _path[0] = _targetAddress;
            _path[1] = basedTokenAddress;
            uint256[] memory _swapAmounts = uniswapV2Router.swapExactTokensForTokens(
                _amountIn, 
                0, 
                _path, 
                address(this), 
                block.timestamp
            );
            uint256 _balAfterSwap = basedToken.balanceOf(address(this));
            require(
                (_balAfterSwap == _balBeforeSwap + _swapAmounts[1]), 
                "Fail to swap"
            );
            redeemBasedTokenAmount = redeemBasedTokenAmount + _swapAmounts[1];
        }

        burn(_tokenId);
        basedToken.transfer(
            _receiver, 
            redeemBasedTokenAmount
        );
    }

    function flashLoan(
        address _borrowTokenAddress,
        uint256 _borrowAmount,
        address _borrowTo,
        bytes32 _payload
    ) external isInitialized noReentrancy {
        checkIsTargetToken(_borrowTokenAddress);
        
        uint256 _balanceBeforeLending = IERC20(_borrowTokenAddress).balanceOf(address(this));
        require(
            _borrowAmount > 10_000,
            "The borrow amount cannot be less than 10_000"
        );
        require(
            _balanceBeforeLending >= _borrowAmount,
            "Insufficeient balance"
        );

        IERC20(_borrowTokenAddress).transfer(
            _borrowTo, 
            _borrowAmount
        );
        uint256 _interest = _borrowAmount * flashLoanInterestRate / 10_000;

        IDecentFolioFlashLoanReceiver(_borrowTo).executeOperation(
            _borrowTokenAddress, 
            _borrowAmount, 
            _interest, 
            msg.sender, 
            _payload
        );

        uint256 _balanceAfterLending = IERC20(_borrowTokenAddress).balanceOf(address(this));
        require(
            _balanceAfterLending >= _balanceBeforeLending + _interest,
            "Insufficeient repay amount"
        );
    }

    function resolveBalances() public isInitialized {
        for (uint256 index; index < investmentTargets.length; index ++) {    
            (address _targetAddress,) = investmentTarget(index);
            resolveBalance(_targetAddress);
        }
    }

    function resolveBalance(
        address _tokenAddress
    ) public isInitialized {
        checkIsTargetToken(_tokenAddress);
        
        uint256 _realBalance = IERC20(_tokenAddress).balanceOf(address(this));
        uint256 _investAmount = totalInvestTokenAmounts[_tokenAddress];
        totalProfitTokenAmounts[_tokenAddress] = _realBalance - _investAmount;
    }

    function setNewFlashLoanInterestRate(
        uint256 _newInterestRate
    ) external isInitialized onlyAdmin {
        flashLoanInterestRate = _newInterestRate;
    }

    function setFolio() external isInitialized onlyAdmin {

    }

    function rebalance() external isInitialized onlyAdmin {

    }

    // MARK: Internal and Private Functions
    function initializeInvestmentTargets(
        address[] memory _targetTokenAddresses,
        uint256[] memory _targetTokenPercentages
    ) internal {
        for (uint256 i = 0; i < _targetTokenAddresses.length; i++) {
            InvestmentTarget memory target = InvestmentTarget(
                _targetTokenAddresses[i],
                _targetTokenPercentages[i]
            );
            investmentTargets.push(target);
        }
    }

    function multiSwapTargets(
        uint256 _tokenId,
        uint256 _amountIn
    ) private {

        basedToken.transferFrom(
            msg.sender,
            address(this),
            _amountIn
        );
        
        for (uint256 index; index < investmentTargets.length; index ++) {    
            (address _targetAddress, uint256 _percentage) = investmentTarget(index);

            uint256 _targetAmountIn = _amountIn * _percentage / 100;

            address[] memory _path = new address[](2);
            _path[0] = basedTokenAddress;
            _path[1] = _targetAddress;

            uint256 _balBeforeSwap = IERC20(_targetAddress).balanceOf(address(this));
            basedToken.approve(
                uniswapV2RouterAddress, 
                _targetAmountIn
            );
            uint256[] memory _swapAmounts = uniswapV2Router.swapExactTokensForTokens(
                _targetAmountIn, 
                0, 
                _path, 
                address(this), 
                block.timestamp
            );
            uint256 _balAfterSwap = IERC20(_targetAddress).balanceOf(address(this));
            require(
                (_balAfterSwap == _balBeforeSwap + _swapAmounts[1]), 
                "Fail to swap"
            );

            totalInvestTokenAmounts[_targetAddress] = totalInvestTokenAmounts[_targetAddress] + _swapAmounts[1];
            investTokenAmounts[_tokenId][_targetAddress] = _swapAmounts[1];
        }
    }

    function checkIsTargetToken(
        address _tokenAddress
    ) view private {
        bool isTargetToken;
        for (uint256 index; index < investmentTargets.length; index ++) {
            (address _targetAddress,) = investmentTarget(index);
            if (_targetAddress == _tokenAddress) {
                isTargetToken = true;
            }
        }

        require(
            isTargetToken,
            "The input token is not one of the target tokens"
        );
    }

    function burn(
        uint256 _tokenId
    ) private {
        totalLockedTimeInterval = totalLockedTimeInterval - lockedTimeIntervals[_tokenId];

        for (uint256 index; index < investmentTargets.length; index ++) {    
            (address _targetAddress,) = investmentTarget(index);
            uint256 _investAmount = investTokenAmounts[_tokenId][_targetAddress];

            totalInvestTokenAmounts[_targetAddress] = totalInvestTokenAmounts[_targetAddress] - _investAmount;
        }

        _burn(_tokenId);
    }

     function profitAmount(
        uint256 _tokenId, 
        address _tokenAddress
    ) private view returns (uint256 amount) {
        uint256 _lockedTimeInterval = lockedTimeIntervals[_tokenId];
        uint256 _investAmount = investTokenAmounts[_tokenId][_tokenAddress];

        uint256 _totalInvestAmount = totalInvestTokenAmounts[_tokenAddress];

        uint256 _profitAmount = (totalProfitTokenAmounts[_tokenAddress] * _lockedTimeInterval * _investAmount) / (_totalInvestAmount * totalLockedTimeInterval);
        return _profitAmount;
    }
}