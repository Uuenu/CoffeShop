// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./ReEntrancyGuard.sol";
import "./ERC20.sol";

// 8 lesson hw
contract BabySwap is ReEntrancyGuard() {
    using SafeERC20 for IERC20;
    IERC20 public coffeToken;
    IERC20 public filterToken;
    address payable public owner;


    constructor() {
        coffeToken = new CoffeToken(address(this));
        filterToken = new FilterToken(address(this));
        owner = payable(msg.sender);
    }

    modifier onlyOnwer() {
        require(msg.sender == owner, "you are not an owner");
        _;
    }

    receive() external payable {}

    function exchange(address token, uint amount) external payable noReentrant() {
        IERC20  sellToken;
        IERC20  buyToken;


       if (token == coffeToken.getTokenAddress()) {
            sellToken = coffeToken;
            buyToken = filterToken;
       }else if (token == filterToken.getTokenAddress()){
            sellToken = filterToken;
            buyToken = coffeToken;
       }

       require(
            amount > 0 && 
            amount <= sellToken.balanceOf(msg.sender), 
            "not enough tokens to sell on youre ballance!");

            uint allowance = sellToken.allowance(msg.sender, address(this));
            require(allowance >= amount, "not enough tokens to sell on in allowance!");
            
           sellToken.safeTransferFrom(msg.sender, address(this), amount);
           
           buyToken.safeTransfer(address(this), amount);
    }


    function buyToken(address token) external payable {
        uint amountWei = msg.value;
        if (token == coffeToken.getTokenAddress()) {
            uint tokenAmount;
            tokenAmount = amountWei;
            coffeToken.safeTransferFrom(address(this), msg.sender, tokenAmount);
            
        }else if (token == filterToken.getTokenAddress()) {
            uint tokenAmount;
            tokenAmount = amountWei;
            filterToken.safeTransferFrom(address(this), msg.sender, tokenAmount);
           
        }
    }
}