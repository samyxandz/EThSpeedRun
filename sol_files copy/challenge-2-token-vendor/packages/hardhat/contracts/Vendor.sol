// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    // Our token contract
    YourToken public yourToken;
    
    // token price for ETH
    uint256 public constant tokensPerEth = 100;

    // Events
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    // buyTokens function allows users to buy tokens by sending ETH
    function buyTokens() public payable {
        require(msg.value > 0, "Send ETH to buy tokens");

        uint256 amountOfTokens = msg.value * tokensPerEth;
        
        // Check if the vendor contract has enough tokens
        require(yourToken.balanceOf(address(this)) >= amountOfTokens, "Vendor has insufficient tokens");

        // Transfer tokens to the buyer
        bool sent = yourToken.transfer(msg.sender, amountOfTokens);
        require(sent, "Token transfer failed");

        // Emit buy event
        emit BuyTokens(msg.sender, msg.value, amountOfTokens);
    }

    // withdraw allows the owner to withdraw ETH from the contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        (bool sent, ) = msg.sender.call{value: balance}("");
        require(sent, "Failed to withdraw");
    }

    // sellTokens allows users to sell tokens back to the vendor
    function sellTokens(uint256 amount) public {
        require(amount > 0, "Specify amount of tokens to sell");
        
        // Calculate ETH amount for the tokens
        uint256 ethAmount = amount / tokensPerEth;
        require(address(this).balance >= ethAmount, "Vendor has insufficient ETH balance");

        // Transfer tokens from seller to vendor
        bool sent = yourToken.transferFrom(msg.sender, address(this), amount);
        require(sent, "Token transfer failed");

        // Transfer ETH to the seller
        (bool ethSent,) = msg.sender.call{value: ethAmount}("");
        require(ethSent, "Failed to send ETH");

        // Emit sell event
        emit SellTokens(msg.sender, amount, ethAmount);
    }

    // Function to receive ETH. msg.data must be empty
    receive() external payable {
        buyTokens();
    }
}