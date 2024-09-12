pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable{
  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

  YourToken public gldTokenContract;
  uint256 public constant tokensPerEth = 100;
  
  constructor(address tokenAddress) {
    gldTokenContract = YourToken(tokenAddress);
  }

  // ToDo: create a payable buyTokens() function:
  function buyTokens() public payable {
    uint256 amountOfTokens = msg.value * tokensPerEth;
    require(gldTokenContract.transfer(msg.sender, amountOfTokens), "Transfer failed");
    emit BuyTokens(msg.sender, msg.value, amountOfTokens);
  }
  // ToDo: create a withdraw() function that lets the owner withdraw ETH
  function withdraw() public onlyOwner {
    (bool success, ) = owner().call{value: address(this).balance}("");
    require(success, "Withdrawal failed"); 
  }

  // ToDo: create a sellTokens(uint256 _amount) function:
  function sellTokens(uint256 amount) public {
    require(amount > 0, "Must sell a positive amount");
    uint256 allowance = gldTokenContract.allowance(msg.sender, address(this));
    require(allowance >= amount, "Check the token allowance");
    uint256 ethToReturn = amount / tokensPerEth;
    require(address(this).balance >= ethToReturn, "Vendor has insufficient funds");
    
    (bool sent) = gldTokenContract.transferFrom(msg.sender, address(this), amount);
    require(sent, "Failed to transfer tokens from user to vendor");

    (sent,) = msg.sender.call{value: ethToReturn}("");
    require(sent, "Failed to send ETH to the user");

    emit SellTokens(msg.sender, amount, ethToReturn);
  }
}
