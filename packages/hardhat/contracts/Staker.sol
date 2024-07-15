// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";
import "hardhat/console.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract; // state variable of type ExampleExternalContract. Hold the address of an instance of the ExampleExternalContract
  mapping( address => uint256 ) public balances;  // Mapping to track balances for each address
  event Stake(address indexed _address, uint256 _amount);  // event that logs the address and the amount staked.
  uint256 public constant THRESHOLD = 1 ether; // threshold to call exampleExternalContract.complete
  uint256 public deadline;
  bool public openForWithdraw = false;
  uint256 public lastExecute;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress); // converts the address into an instance of ExampleExternalContract.
      lastExecute = block.timestamp;  // set lastExecute to contract creation timestamp
      deadline = block.timestamp + 72 hours;
      console.log("exampleExternalContractAddress", exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
  function stake () public payable {
      balances[msg.sender] += msg.value; // adds the amount staked to the mapping.
      emit Stake(msg.sender, msg.value); // emits the event.
      console.log("Stake", msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public {
      require(block.timestamp >= deadline, "Deadline not passed"); // Check if deadline has passed
      // require(address(this).balance >= THRESHOLD, "Not enough balance"); // Check if balance has passed the threshold
      // If balance met threshold, call the external contract
      if (address(this).balance >= THRESHOLD) {
          exampleExternalContract.complete{value: address(this).balance}();
          balances[msg.sender] = 0;
          lastExecute = block.timestamp; // Set lastExecute to current timestamp
      } else {
          // If balance did not meet threshold, allow everyone to call a `withdraw()` function to withdraw their balance
          openForWithdraw = true;
      }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() public {
      require(openForWithdraw == true, "Withdraw not allowed");
      uint256 balance = balances[msg.sender];
      require(balance > 0, "No balance to withdraw");

      balances[msg.sender] = 0; // set user balance to 0

      (bool success, ) = msg.sender.call{value: balance}(""); // send the balance to the user
      require(success, "Failed to send Ether");
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
      if (deadline > block.timestamp) {
          return deadline - block.timestamp;
      } else {
          return 0;
      }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
      stake(); // calls the stake function if user sends eth to the contract.
  }
}
