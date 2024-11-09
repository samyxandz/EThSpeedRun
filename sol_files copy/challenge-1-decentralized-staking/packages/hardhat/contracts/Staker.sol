// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ExampleExternalContract.sol";

contract Staker {
	mapping(address => uint256) public balances;
	uint256 public constant threshold = 1 ether;
	ExampleExternalContract public exampleExternalContract;
	uint256 public deadline = block.timestamp + 30 seconds;
	bool public openForWithdraw = false;
	bool public completed;
	event Stake(address indexed user, uint256 amount);

	constructor(address exampleExternalContractAddress) {
		exampleExternalContract = ExampleExternalContract(
			exampleExternalContractAddress
		);
		// 1 day from now
	}

	function stake() public payable {
		balances[msg.sender] += msg.value;
		emit Stake(msg.sender, msg.value);
	}

	function execute() public {
		require(block.timestamp > deadline, "Deadline has not passed");
		if (address(this).balance >= threshold) {
			exampleExternalContract.complete{ value: address(this).balance }();
		} else {
			openForWithdraw = true;
		}
	}

	function withdraw() public {
		require(
			address(this).balance < threshold,
			"Threshold is met, cannot withdraw"
		);
		uint256 amount = balances[msg.sender];
		balances[msg.sender] = 0;
		payable(msg.sender).transfer(amount);
	}

	function timeLeft() public view returns (uint256) {
		if (block.timestamp >= deadline) {
			return 0;
		}
		return deadline - block.timestamp;
	}

	receive() external payable {
		stake();
	}
}
