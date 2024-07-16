// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./ReEntrancyGuard.sol";
import "utils/SafeERC20.sol";
contract ERC20 is IERC20,  ReEntrancyGuard {
    address contractOwner;
    mapping (address => uint) balances;
    mapping (address => mapping(address => uint)) allowances;
    string _name;
    string _symbol;
    uint totalTokens;

    function name() external view returns(string memory) {
        return _name;
    }

    function symbol() external view returns(string memory) {
        return _symbol;
    }

    function decimals() external view returns(uint8) {
        return 18; // 1 token = 1 wei
    }

    function totalSupply() external view returns(uint) {
        return totalTokens;
    }

    modifier enoughtTokens(address _from, uint amount) {
        require(balanceOf(_from) >= amount, "not enough tokens");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "you are not an owner!");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint initialSupply, address shop) {
        _name = name_;
        symbol_ = symbol_;
        contractOwner = msg.sender;
        mint(initialSupply, shop);
    }

    function balanceOf(address account) public view returns(uint) {
       return balances[account];
    }

    // public onlyOwner так как только владелец токена может эмитировать новые токены 
    function mint(uint amount, address shop) public onlyOwner {
        beforeTokenTransfer(address(0), shop, amount);
        balances[shop] += amount;
        totalTokens += amount;
        emit Transfer(address(0), shop, amount);
    }

    function burn(uint amount, address from) public onlyOwner {
        beforeTokenTransfer(from, address(0), amount);
        balances[from] -= amount;
        totalTokens -= amount;
        emit Transfer(from, address(0), amount);
    }

    function transfer(address to, uint amount) external noReentrant() returns(bool){
        beforeTokenTransfer(address(0), to, amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns(uint) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint amount) external returns(bool success) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint amount) internal {
        allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) external noReentrant() returns(bool) {

        require( allowances[sender][recipient] >= amount, "not enoug tokens ");
        allowances[sender][recipient] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function getTokenAddress() public view returns (address) {
        return address(this);
    }

    function beforeTokenTransfer(address _from, address _to, uint amount) internal virtual {}

}

contract CoffeToken is ERC20 {
    constructor(address shop) ERC20("Coffe Token", "CFXT", 30, shop) {}

}

contract FilterToken is ERC20 {
    constructor(address shop) ERC20("Filter Token", "FLTKN", 50, shop) {}
}

contract CoffeShop {
    using SafeERC20 for IERC20;
    IERC20 public token;
    address payable public owner;
    event Deal(address seller, address buyer, uint amount);
    event Bought(address buyer, uint amount);
    event Sold(address seller, uint amount);

    constructor() {
        token = new CoffeToken(address(this));
        owner = payable(msg.sender);
    }

    modifier onlyOnwer() {
        require(msg.sender == owner, "you are not an owner");
        _;
    }

    receive() external payable {
        uint tokensToBuy = msg.value; // 1 wei - 1 token
        require(tokensToBuy > 0, "not enough funds!");
        require(tokenBalance() >= tokensToBuy, "not enough tokens!");

        token.safeTransfer(msg.sender, tokensToBuy);
        emit Bought(msg.sender, tokensToBuy);
        emit Deal(address(this), msg.sender, tokensToBuy);
    }

    function sell(uint amount) external payable {
        require(
            amount > 0 && 
            amount <= token.balanceOf(msg.sender), "not enough tokens on youre ballance!");
        
        uint allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "not enough tokens in allowance!");

        token.safeTransferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(amount);

        emit Sold(msg.sender, amount);
        emit Deal(msg.sender, address(this), amount);
    }

    function tokenBalance() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    function withdraw(uint amount) public payable onlyOnwer() {
        require(token.balanceOf(address(this)) >= amount, "not enough tokens on token balance");
        token.safeTransferFrom(address(this), owner, amount);
    }
}
