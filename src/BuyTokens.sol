// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract BuyTokens is ReentrancyGuard {
    error UnAuthorized();
    error NotEnoughTokens();
    error InsufficientBalance();
    error InvalidAmount();
    error NotAnOwner();
    error NoAmountToWithdraw();
    error TransactionFailed();

    IERC20 public token;
    address public immutable owner;
    uint256 public perTokenPrice = 0.0001 ether;

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert UnAuthorized();
        _;
    }

    struct Buyer {
        address tokenHolder;
        uint256 tokensHold;
        uint256 time;
    }

    mapping(address => Buyer) public buyers;

    event BuyerDetail(address holderName, uint256 amount, uint256 time);

    function buyToken(uint256 _amountOfToken) external payable nonReentrant {
        if (_amountOfToken == 0) revert InvalidAmount();

        uint256 finalPay = _amountOfToken * perTokenPrice;

        if (token.balanceOf(address(this)) < _amountOfToken) revert NotEnoughTokens();

        if (msg.value != finalPay) revert InsufficientBalance();
        buyers[msg.sender] = Buyer({tokenHolder: msg.sender, tokensHold: _amountOfToken, time: block.timestamp});

        bool success = token.transfer(msg.sender, _amountOfToken);
        if (!success) revert TransactionFailed();

        emit BuyerDetail(msg.sender, _amountOfToken, block.timestamp);
    }

    function withdrawAmount() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoAmountToWithdraw();

        (bool success,) = payable(owner).call{value: balance}("");

        if (!success) revert TransactionFailed();
    }
}
