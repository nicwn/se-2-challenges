pragma solidity >=0.8.0 <0.9.0; //Do not change the solidity version as it negativly impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";

contract DiceGame {
  // State variables
  uint256 public nonce = 0;  // Nonce of the contract, used in rollTheDice() to add randomness
  uint256 public prize = 0;  // The current prize amount

  // My new mappings to track player payments and winnings
  mapping(address => uint256) public playerPaid;
  mapping(address => uint256) public playerWon;

  // Custom error for insufficient ether sent
  error NotEnoughEther();

  // Events to log important actions
  event Roll(address indexed player, uint256 amount, uint256 roll);
  event Winner(address winner, uint256 amount);
  // add events for playerPaid and playerWon
  event PlayerPaid(address indexed player, uint256 playerPaid);
  event PlayerWon(address indexed player, uint256 totalWon); 

  // Constructor function, called when deploying the contract
  constructor() payable {
    resetPrize();
  }

  // Private function to reset prize amount when someone wins
  function resetPrize() private {
    prize = ((address(this).balance * 10) / 100);  // 10% of the contract's balance
  }

  // User call this main function to play the dice game
  function rollTheDice() public payable {
    // Check if the player sent enough ether to play
    if (msg.value < 0.002 ether) {
      revert NotEnoughEther();
    }

    // Generate a pseudo-random number for the dice roll
    bytes32 prevHash = blockhash(block.number - 1);  // Get the hash of the previous block
    bytes32 hash = keccak256(abi.encodePacked(prevHash, address(this), nonce));  // Create a unique hash
    uint256 roll = uint256(hash) % 16;  // Convert hash to a number between 0 and 15

    console.log("\t", "   Previous Block Hash:", uint256(prevHash)); // To write the RiggedRoll attack contract, we need to know the previous block hash
    console.log("\t", "   Nonce:", nonce);  // and the rest of the variables that are hashed together
    console.log("\t", "   Contract Address:", address(this));
    console.log("\t", "   Dice Game Roll:", roll);

    nonce++;  // Increment the nonce for future rolls
    prize += ((msg.value * 40) / 100);  // Add 40% of the bet to the prize pool

    // Update player payment
    playerPaid[msg.sender] += msg.value;

    // Emit PlayerPaid event
    emit PlayerPaid(msg.sender, playerPaid[msg.sender]);

    // Update mappings for player's total paid amount
    playerPaid[msg.sender] += msg.value;

    // Emit an event with roll details
    emit Roll(msg.sender, msg.value, roll);

    // If the roll is greater than 5, the player loses
    if (roll > 5) {
      return;
    }

    // Player wins if the code reaches here
    uint256 amount = prize;
    (bool sent, ) = msg.sender.call{value: amount}("");  // Send the prize to the winner
    require(sent, "Failed to send Ether");

    // Update player winnings
    playerWon[msg.sender] += amount;

    // Emit PlayerWon and Winner events
    emit PlayerWon(msg.sender, playerWon[msg.sender]);
    emit Winner(msg.sender, amount);

    resetPrize();  // Reset the prize for the next game
  }

  // Function to receive Ether. msg.data must be empty
  receive() external payable {}
}
