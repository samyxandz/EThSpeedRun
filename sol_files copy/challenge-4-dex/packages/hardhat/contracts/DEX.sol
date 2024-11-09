// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {
    /* ========== GLOBAL VARIABLES ========== */
    IERC20 token; // Instance of the Balloon token
    uint256 public totalLiquidity; // Total amount of liquidity provider tokens (LPTs)
    mapping(address => uint256) public liquidity; // Mapping of LP addresses to their liquidity contributions

    /* ========== EVENTS ========== */
    event EthToTokenSwap(address swapper, uint256 tokenOutput, uint256 ethInput);
    event TokenToEthSwap(address swapper, uint256 tokensInput, uint256 ethOutput);
    event LiquidityProvided(address liquidityProvider, uint256 liquidityMinted, uint256 ethInput, uint256 tokensInput);
    event LiquidityRemoved(address liquidityRemover, uint256 liquidityWithdrawn, uint256 tokensOutput, uint256 ethOutput);

    /* ========== CONSTRUCTOR ========== */
    constructor(address tokenAddr) {
        token = IERC20(tokenAddr);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Initializes the DEX with the first liquidity provision
     * @param tokens Amount of tokens to initialize with
     * @return totalLiquidity The amount of liquidity provider tokens minted
     */
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX: already initialized");
        require(tokens > 0 && msg.value > 0, "DEX: zero amounts not allowed");
        
        totalLiquidity = msg.value;
        liquidity[msg.sender] = totalLiquidity;
        
        require(token.transferFrom(msg.sender, address(this), tokens), "DEX: transfer failed");
        
        return totalLiquidity;
    }

    /**
     * @notice Returns the output amount for a given input amount and reserves
     * @dev Includes a 0.3% fee for liquidity providers
     */
    function price(uint256 xInput, uint256 xReserves, uint256 yReserves) public pure returns (uint256 yOutput) {
        uint256 xInputWithFee = (xInput * 997) / 1000;  // 0.3% fee
        uint256 numerator = xInputWithFee * yReserves;
        uint256 denominator = xReserves + xInputWithFee;
        return numerator / denominator;
    }

    /**
     * @notice Returns liquidity balance for a given address
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    /**
     * @notice Swaps ETH for tokens
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "DEX: zero ETH sent");
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));
        tokenOutput = price(msg.value, ethReserve, tokenReserve);

        require(token.transfer(msg.sender, tokenOutput), "DEX: token transfer failed");
        emit EthToTokenSwap(msg.sender, tokenOutput, msg.value);
        
        return tokenOutput;
    }

    /**
     * @notice Swaps tokens for ETH
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "DEX: zero tokens sent");
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethReserve = address(this).balance;
        ethOutput = price(tokenInput, tokenReserve, ethReserve);
        
        require(token.transferFrom(msg.sender, address(this), tokenInput), "DEX: transferFrom failed");
        (bool sent,) = msg.sender.call{value: ethOutput}("");
        require(sent, "DEX: ETH transfer failed");
        
        emit TokenToEthSwap(msg.sender, tokenInput, ethOutput);
        return ethOutput;
    }

    /**
     * @notice Adds liquidity to the DEX
     */
    function deposit() public payable returns (uint256 tokensDeposited) {
        require(msg.value > 0, "DEX: zero ETH deposited");
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
        uint256 liquidityMinted = (msg.value * totalLiquidity) / ethReserve;
        
        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;
        
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "DEX: deposit transfer failed");
        emit LiquidityProvided(msg.sender, liquidityMinted, msg.value, tokenAmount);
        
        return tokenAmount;
    }

    /**
     * @notice Removes liquidity from the DEX
     */
    function withdraw(uint256 amount) public returns (uint256 ethAmount, uint256 tokenAmount) {
        require(liquidity[msg.sender] >= amount, "DEX: insufficient liquidity");
        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));
        
        ethAmount = (amount * ethReserve) / totalLiquidity;
        tokenAmount = (amount * tokenReserve) / totalLiquidity;
        
        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;
        
        (bool sent,) = msg.sender.call{value: ethAmount}("");
        require(sent, "DEX: ETH transfer failed");
        require(token.transfer(msg.sender, tokenAmount), "DEX: token transfer failed");
        
        emit LiquidityRemoved(msg.sender, amount, tokenAmount, ethAmount);
        return (ethAmount, tokenAmount);
    }

    // Required to receive ETH
    receive() external payable {}
}