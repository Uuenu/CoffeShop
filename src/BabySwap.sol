// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./ReEntrancyGuard.sol";
import "./ERC20.sol";


// 8 lesson hw

contract BabySwap is ReEntrancyGuard() {
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

    function exchange(bool  tokenSell, uint amount) external payable noReentrant() {
        IERC20  sellToken;
        IERC20  buyToken;
        if (tokenSell == true) {
            sellToken = coffeToken;
            buyToken = filterToken;
        }else {
            sellToken = filterToken;
            buyToken = coffeToken;
        }

        require(
            amount > 0 && 
            amount <= sellToken.balanceOf(msg.sender), 
            "not enough tokens to sell on youre ballance!");

        uint allowance = sellToken.allowance(msg.sender, address(this));
        require(allowance >= amount, "not enough tokens to sell on in allowance!");
        
        bool success = sellToken.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert(" sellToken.transferFrom didnt success");
        }

        success = buyToken.transfer(address(this), amount);
         if (!success) {
            revert("buyToken.transfer didnt success");
        }
    }

    function buyToken(uint amountEth, bool tokenKind) external payable {
        if (tokenKind) {
            uint tokenAmount;
            tokenAmount = amountEth * 10 ** coffeToken.decimals();
            bool success = coffeToken.transferFrom(address(this), msg.sender, tokenAmount);
            if (!success) {
                revert(" sellToken.transferFrom didnt success");
            }
            //payable(address(this)).transfer(amountEth); 
        }else {
            uint tokenAmount;
            tokenAmount = amountEth * 10 ** coffeToken.decimals();
            bool success =filterToken.transferFrom(address(this), msg.sender, tokenAmount);
            if (!success) {
                revert(" sellToken.transferFrom didnt success");
            }  
            //payable(address(this)).transfer(amountEth); 
        }
    }
}