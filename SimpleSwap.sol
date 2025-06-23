// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title SimpleSwap - Uniswap V2-style Decentralized Exchange
 * @notice Implements core DEX functionality: liquidity pools, token swaps, and price oracle
 * @dev Uses constant product formula x*y=k with 0.3% trading fee
 */

contract SimpleSwap {
    using Math for uint256;

    /**
     * @dev Pair structure storing liquidity pool state
     * @param reserve0 Reserve amount of token0
     * @param reserve1 Reserve amount of token1
     * @param totalSupply Total LP token supply
     * @param liquidityBalances Mapping of LP token balances per provider
     */
    struct Pair {
        uint256 reserve0;
        uint256 reserve1;
        uint256 totalSupply;
        mapping(address => uint256) liquidityBalances;
    }

    /// @dev Minimum LP tokens to lock permanently during pool creation
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    /// @dev Storage for all token pairs (key: keccak256(sorted token addresses))
    mapping(bytes32 => Pair) private pairStorage;

     /**
     * @notice Emitted when liquidity is added to a pool
     * @param provider Address providing liquidity
     * @param token0 First token in pair
     * @param token1 Second token in pair
     * @param amount0 Amount of token0 added
     * @param amount1 Amount of token1 added
     * @param liquidity LP tokens minted to provider
     */
    event LiquidityAdded(
        address indexed provider,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );
    
    /**
     * @notice Emitted when liquidity is removed from a pool
     * @param provider Address removing liquidity
     * @param token0 First token in pair
     * @param token1 Second token in pair
     * @param amount0 Amount of token0 returned
     * @param amount1 Amount of token1 returned
     * @param liquidity LP tokens burned
     */
    event LiquidityRemoved(
        address indexed provider,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );
    
     /**
     * @notice Emitted during token swap
     * @param sender Swapper address
     * @param amountIn Input token amount
     * @param amountOut Output token amount
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     */
    event TokensSwapped(
        address indexed sender,
        uint256 amountIn,
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    );

    /**
     * @notice Calculate output amount for given input
     * @dev Implements x*y=k formula with 0.3% fee
     * @param amountIn Input token amount
     * @param reserveIn Reserve of input token
     * @param reserveOut Reserve of output token
     * @return amountOut Output token amount
     */
    function getAmountOut(
        uint256 amountIn, 
        uint256 reserveIn, 
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");
        
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /**
     * @dev Generate unique pair identifier
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return bytes32 Pair key (keccak256 of sorted tokens)
     */
    function getPairKey(address tokenA, address tokenB) private pure returns (bytes32) {
        (address token0, address token1) = tokenA < tokenB ? 
            (tokenA, tokenB) : (tokenB, tokenA);
        return keccak256(abi.encodePacked(token0, token1));
    }

    /**
     * @dev Get pair storage reference
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return Pair storage reference
     */
    function getPair(address tokenA, address tokenB) private view returns (Pair storage) {
        return pairStorage[getPairKey(tokenA, tokenB)];
    }

    /**
     * @notice Add liquidity to a token pair
     * @dev Mints LP tokens proportional to deposit value
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param amountADesired Max amount of tokenA to deposit
     * @param amountBDesired Max amount of tokenB to deposit
     * @param amountAMin Minimum tokenA amount (slippage protection)
     * @param amountBMin Minimum tokenB amount (slippage protection)
     * @param to Recipient of LP tokens
     * @param deadline Transaction validity deadline
     * @return amountA Actual tokenA amount deposited
     * @return amountB Actual tokenB amount deposited
     * @return liquidity LP tokens minted
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(deadline >= block.timestamp, "Expired");
        Pair storage pair = getPair(tokenA, tokenB);
        
        (uint256 reserveA, uint256 reserveB) = (pair.reserve0, pair.reserve1);
        
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Insufficient B");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
                require(amountAOptimal >= amountAMin, "Insufficient A");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }

        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "Transfer A failed");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB), "Transfer B failed");

        if (pair.totalSupply == 0) {
            liquidity = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
            pair.liquidityBalances[address(0)] = MINIMUM_LIQUIDITY;
        } else {
            liquidity = Math.min(
                (amountA * pair.totalSupply) / reserveA,
                (amountB * pair.totalSupply) / reserveB
            );
        }

        require(liquidity > 0, "Insufficient liquidity");
        
        pair.reserve0 = reserveA + amountA;
        pair.reserve1 = reserveB + amountB;
        pair.totalSupply += liquidity;
        pair.liquidityBalances[to] += liquidity;
        
        emit LiquidityAdded(to, tokenA, tokenB, amountA, amountB, liquidity);
    }

    /**
     * @notice Remove liquidity from a pool
     * @dev Burns LP tokens and returns proportional token amounts
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param liquidity LP tokens to burn
     * @param amountAMin Minimum tokenA to receive (slippage protection)
     * @param amountBMin Minimum tokenB to receive (slippage protection)
     * @param to Recipient of underlying tokens
     * @param deadline Transaction validity deadline
     * @return amountA TokenA amount received
     * @return amountB TokenB amount received
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(deadline >= block.timestamp, "Expired");
        Pair storage pair = getPair(tokenA, tokenB);
        
        amountA = (liquidity * pair.reserve0) / pair.totalSupply;
        amountB = (liquidity * pair.reserve1) / pair.totalSupply;
        
        require(amountA >= amountAMin && amountB >= amountBMin, "Insufficient amounts");
        
        pair.liquidityBalances[msg.sender] -= liquidity;
        pair.totalSupply -= liquidity;
        pair.reserve0 -= amountA;
        pair.reserve1 -= amountB;
        
        require(IERC20(tokenA).transfer(to, amountA), "Transfer A failed");
        require(IERC20(tokenB).transfer(to, amountB), "Transfer B failed");
        
        emit LiquidityRemoved(msg.sender, tokenA, tokenB, amountA, amountB, liquidity);
    }

    /**
     * @notice Swap exact tokens for tokens along a path
     * @dev Supports direct swaps only (2-token path)
     * @param amountIn Exact input token amount
     * @param amountOutMin Minimum output tokens (slippage protection)
     * @param path [inputToken, outputToken] path
     * @param to Recipient of output tokens
     * @param deadline Transaction validity deadline
     * @return amounts Array containing [inputAmount, outputAmount]
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts) {
        require(deadline >= block.timestamp, "Expired");
        require(path.length == 2, "Invalid path");
        
        address tokenIn = path[0];
        address tokenOut = path[1];
        Pair storage pair = getPair(tokenIn, tokenOut);
        
        (uint256 reserveIn, uint256 reserveOut) = tokenIn < tokenOut ? 
            (pair.reserve0, pair.reserve1) : (pair.reserve1, pair.reserve0);
        
        uint256 amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "Insufficient output");
        
         require(IERC20(tokenIn).transferFrom(msg.sender, address(this), (amountOut)) == true, "Transfer A failed");
        
        if (tokenIn < tokenOut) {
            pair.reserve0 += amountIn;
            pair.reserve1 -= amountOut;
        } else {
            pair.reserve1 += amountIn;
            pair.reserve0 -= amountOut;
        }
        
        require(IERC20(tokenOut).transfer(to, amountOut), "Transfer out failed");
        
        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
        
        emit TokensSwapped(msg.sender, amountIn, amountOut, tokenIn, tokenOut);
    }

     /**
     * @notice Get current price of tokenA in terms of tokenB
     * @dev Price = (reserveB / reserveA) scaled to 1e18
     * @param tokenA Base token address
     * @param tokenB Quote token address
     * @return price Price of tokenA in tokenB (1e18 precision)
     */
    function getPrice(address tokenA, address tokenB) external view returns (uint256 price) {
        Pair storage pair = getPair(tokenA, tokenB);
        (uint256 reserveA, uint256 reserveB) = tokenA < tokenB ? 
            (pair.reserve0, pair.reserve1) : (pair.reserve1, pair.reserve0);
        
        if (reserveA > 0) {
            price = (reserveB * 1e18) / reserveA;
        }
    }

    /**
     * @notice Get reserves for a token pair
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return reserveA Reserve amount of tokenA
     * @return reserveB Reserve amount of tokenB
     */
    function getReserves(address tokenA, address tokenB) external view returns (uint256 reserveA, uint256 reserveB) {
        Pair storage pair = getPair(tokenA, tokenB);
        (reserveA, reserveB) = tokenA < tokenB ? 
            (pair.reserve0, pair.reserve1) : (pair.reserve1, pair.reserve0);
    }
}