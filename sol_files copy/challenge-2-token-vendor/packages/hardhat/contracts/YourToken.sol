// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract YourToken is ERC20 {
    constructor() ERC20("Gold", "GLD") {
        // Mint 1000 tokens to msg.sender
        // 1000 * 10^18 because ERC20 defaults to 18 decimals
        _mint(msg.sender, 1000 * 10**18);
    }
}