pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

// Vendor contract for buying and selling tokens, inheriting Ownable for access control
contract Vendor is Ownable {
  // Events to log token purchases and sales
  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

  // Reference to the custom token contract
  YourToken public gldTokenContract;
  // Constant defining the exchange rate: 100 tokens per 1 ETH
  uint256 public constant tokensPerEth = 100;
  
  // Constructor to initialize the contract with the token address
  constructor(address tokenAddress) {
    gldTokenContract = YourToken(tokenAddress);
  }

  // Function to buy tokens, payable to accept ETH
  function buyTokens() public payable {
    // Calculate the amount of tokens based on sent ETH
    uint256 amountOfTokens = msg.value * tokensPerEth;
    // Transfer tokens to the buyer
    require(gldTokenContract.transfer(msg.sender, amountOfTokens), "Transfer failed");
    // Emit event for token purchase
    emit BuyTokens(msg.sender, msg.value, amountOfTokens);
  }

  // Function to allow the owner to withdraw ETH from the contract
  function withdraw() public onlyOwner {
    // Transfer the entire balance to the owner
    (bool success, ) = owner().call{value: address(this).balance}("");
    require(success, "Withdrawal failed"); 
  }

  // Function to sell tokens back to the contract
  function sellTokens(uint256 amount) public {
    require(amount > 0, "Must sell a positive amount");
    // Check if the user has approved the contract to spend their tokens
    uint256 allowance = gldTokenContract.allowance(msg.sender, address(this));
    require(allowance >= amount, "Check the token allowance");
    // Calculate ETH to return based on the token amount
    uint256 ethToReturn = amount / tokensPerEth;
    require(address(this).balance >= ethToReturn, "Vendor has insufficient funds");
    
    // Transfer tokens from user to the contract
    (bool sent) = gldTokenContract.transferFrom(msg.sender, address(this), amount);
    require(sent, "Failed to transfer tokens from user to vendor");

    // Send ETH to the user
    (sent,) = msg.sender.call{value: ethToReturn}("");
    require(sent, "Failed to send ETH to the user");

    // Emit event for token sale
    emit SellTokens(msg.sender, amount, ethToReturn);
  }
}
