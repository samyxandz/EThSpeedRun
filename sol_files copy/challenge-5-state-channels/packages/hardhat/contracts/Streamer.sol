// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Streamer is Ownable {
  event Opened(address, uint256);
  event Challenged(address);
  event Withdrawn(address, uint256);
  event Closed(address);

  mapping(address => uint256) balances;
  mapping(address => uint256) canCloseAt;

  function fundChannel() public payable {
    // Check that the sender doesn't already have an open channel
    require(balances[msg.sender] == 0, "Channel already exists");
    
    // Update the balances mapping with received ETH
    balances[msg.sender] = msg.value;
    
    // Emit the Opened event
    emit Opened(msg.sender, msg.value);
  }

  function timeLeft(address channel) public view returns (uint256) {
    if (canCloseAt[channel] == 0 || canCloseAt[channel] < block.timestamp) {
      return 0;
    }
    return canCloseAt[channel] - block.timestamp;
  }

  function withdrawEarnings(Voucher calldata voucher) public {
    bytes32 hashed = keccak256(abi.encode(voucher.updatedBalance));
    bytes memory prefixed = abi.encodePacked("\x19Ethereum Signed Message:\n32", hashed);
    bytes32 prefixedHashed = keccak256(prefixed);
    
    // Recover signer from the signature
    address signer = ecrecover(
      prefixedHashed,
      voucher.sig.v,
      voucher.sig.r,
      voucher.sig.s
    );
    
    // Verify the channel exists and has sufficient balance
    require(balances[signer] > 0, "No channel exists for signer");
    require(balances[signer] > voucher.updatedBalance, "Insufficient channel balance");
    
    // Calculate payment amount
    uint256 payment = balances[signer] - voucher.updatedBalance;
    
    // Update channel balance
    balances[signer] = voucher.updatedBalance;
    
    // Pay the Guru (contract owner)
    (bool success, ) = owner().call{value: payment}("");
    require(success, "Payment failed");
    
    // Emit the Withdrawn event
    emit Withdrawn(signer, payment);
  }

  function challengeChannel() public {
    // Verify sender has an open channel
    require(balances[msg.sender] > 0, "No channel exists");
    
    // Set closing time to 30 seconds from now
    canCloseAt[msg.sender] = block.timestamp + 30 seconds;
    
    // Emit the Challenged event
    emit Challenged(msg.sender);
  }

  function defundChannel() public {
    // Verify the channel can be closed
    require(canCloseAt[msg.sender] > 0, "Channel not challenged");
    require(block.timestamp >= canCloseAt[msg.sender], "Challenge period not ended");
    
    // Get the remaining balance
    uint256 amount = balances[msg.sender];
    
    // Reset the channel balance
    balances[msg.sender] = 0;
    canCloseAt[msg.sender] = 0;
    
    // Return funds to the sender
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Refund failed");
    
    // Emit the Closed event
    emit Closed(msg.sender);
  }

  struct Voucher {
    uint256 updatedBalance;
    Signature sig;
  }
  
  struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }
}