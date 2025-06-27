// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SimpleSwap - Minimal DEX Clone
 * @notice Enables token swaps and liquidity management
 * @dev Implements basic DEX functionality including liquidity provision and token swaps
 */
contract SimpleSwap {
    /// @notice Minimum liquidity that must remain in the pool
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    /// @notice Structure representing a token pair and its reserves
    struct Pair {
        uint256 reserveA;           // Reserve amount of token A
        uint256 reserveB;           // Reserve amount of token B
        uint256 totalLiquidity;     // Total liquidity tokens minted
        mapping(address => uint256) balanceOf;  // Liquidity balance per address
        bool initialized;           // Whether the pair has been initialized
    }

    mapping(bytes32 => Pair) internal pairStorage;

    /// @notice Mapping of token addresses to their pair data
    mapping(address => mapping(address => Pair)) private pairs;

    /// @notice Emitted when liquidity is added to a pool
    event LiquidityAdded(address indexed to, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 liquidity);
    
    /// @notice Emitted when liquidity is removed from a pool
    event LiquidityRemoved(address indexed to, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 liquidity);

    /// @notice Emitted when a token swap occurs
    event TokensSwapped(address indexed sender, uint256 amountIn, uint256 amountOut, address tokenIn, address tokenOut);

    /**
     * @notice Adds liquidity to a token pair pool
     * @dev Calculates optimal amounts and mints liquidity tokens
     * @param tokenA Address of first token in the pair
     * @param tokenB Address of second token in the pair
     * @param amountADesired Desired amount of token A to add
     * @param amountBDesired Desired amount of token B to add
     * @param amountAMin Minimum acceptable amount of token A
     * @param amountBMin Minimum acceptable amount of token B
     * @param to Address to receive liquidity tokens
     * @param deadline Deadline for the transaction
     * @return amountA Actual amount of token A added
     * @return amountB Actual amount of token B added
     * @return liquidity Amount of liquidity tokens minted
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        require(deadline >= block.timestamp, "Expired");
        require(tokenA != tokenB, "Identical tokens");

        Pair storage pair = pairs[tokenA][tokenB];
        if (!pair.initialized) {
            pair.initialized = true;
        }

        if (pair.reserveA == 0 && pair.reserveB == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            uint amountBOptimal = (amountADesired * pair.reserveB) / pair.reserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Insufficient B amount");
                amountA = amountADesired;
                amountB = amountBOptimal;
            } else {
                uint amountAOptimal = (amountBDesired * pair.reserveA) / pair.reserveB;
                require(amountAOptimal >= amountAMin, "Insufficient A amount");
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
        }

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        if (pair.totalLiquidity == 0) {
            liquidity = (amountA * amountB) / 1e18 - MINIMUM_LIQUIDITY;
            pair.balanceOf[address(0)] = MINIMUM_LIQUIDITY;
        } else {
            uint liquidityA = (amountA * pair.totalLiquidity) / pair.reserveA;
            uint liquidityB = (amountB * pair.totalLiquidity) / pair.reserveB;
            liquidity = liquidityA < liquidityB ? liquidityA : liquidityB;
        }

        require(liquidity > 0, "Insufficient liquidity minted");

        pair.reserveA += amountA;
        pair.reserveB += amountB;
        pair.totalLiquidity += liquidity;
        pair.balanceOf[to] += liquidity;

        emit LiquidityAdded(to, tokenA, tokenB, amountA, amountB, liquidity);
    }

    /**
     * @notice Removes liquidity from a token pair pool
     * @dev Burns liquidity tokens and returns proportional reserves
     * @param tokenA Address of first token in the pair
     * @param tokenB Address of second token in the pair
     * @param liquidity Amount of liquidity tokens to burn
     * @param amountAMin Minimum acceptable amount of token A to receive
     * @param amountBMin Minimum acceptable amount of token B to receive
     * @param to Address to receive underlying tokens
     * @param deadline Deadline for the transaction
     * @return amountA Actual amount of token A received
     * @return amountB Actual amount of token B received
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB) {
        require(deadline >= block.timestamp, "Expired");

        Pair storage pair = pairs[tokenA][tokenB];

        amountA = (liquidity * pair.reserveA) / pair.totalLiquidity;
        amountB = (liquidity * pair.reserveB) / pair.totalLiquidity;

        require(amountA >= amountAMin, "Insufficient A");
        require(amountB >= amountBMin, "Insufficient B");

        pair.balanceOf[msg.sender] -= liquidity;
        pair.totalLiquidity -= liquidity;
        pair.reserveA -= amountA;
        pair.reserveB -= amountB;

        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);

        emit LiquidityRemoved(to, tokenA, tokenB, amountA, amountB, liquidity);
    }

    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible
     * @dev Uses constant product formula to determine output amount
     * @param amountIn Exact amount of input tokens to swap
     * @param amountOutMin Minimum acceptable amount of output tokens
     * @param path Array of token addresses representing swap path (must be length 2)
     * @param to Address to receive output tokens
     * @param deadline Deadline for the transaction
     * @return amounts Array containing input amount and actual output amount
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(deadline >= block.timestamp, "Expired");
        require(path.length == 2, "Invalid path");

        address tokenIn = path[0];
        address tokenOut = path[1];
        Pair storage pair = pairs[tokenIn][tokenOut];

        uint amountOut = getAmountOut(amountIn, pair.reserveA, pair.reserveB);
        require(amountOut >= amountOutMin, "Insufficient output amount");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(to, amountOut);

        pair.reserveA += amountIn;
        pair.reserveB -= amountOut;

        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        emit TokensSwapped(msg.sender, amountIn, amountOut, tokenIn, tokenOut);
    }

    /**
     * @notice Gets the current price ratio between two tokens
     * @dev Price is expressed as amount of tokenB per 1e18 units of tokenA
     * @param tokenA Address of first token in the pair
     * @param tokenB Address of second token in the pair
     * @return price Current price ratio (tokenB per tokenA)
     */
    function getPrice(address tokenA, address tokenB) external view returns (uint price) {
        Pair storage pair = pairs[tokenA][tokenB];
        require(pair.reserveA > 0, "Zero reserve");
        price = (pair.reserveB * 1e18) / pair.reserveA;
    }

    /**
     * @notice Calculates the amount of output tokens for a given input
     * @dev Uses constant product formula: amountOut = (amountIn * reserveOut) / (reserveIn + amountIn)
     * @param amountIn Amount of input tokens
     * @param reserveIn Reserve amount of input token
     * @param reserveOut Reserve amount of output token
     * @return amountOut Expected amount of output tokens
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, "Insufficient input");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
    }
    /**
     * @notice Get reserves for a token pair
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return reserveA Reserve amount of tokenA
     * @return reserveB Reserve amount of tokenB
     */
    function getReserves(
        address tokenA,
        address tokenB
    ) external view returns (uint256 reserveA, uint256 reserveB) {
        bytes32 pairKey = keccak256(abi.encodePacked(
            tokenA < tokenB ? tokenA : tokenB,
            tokenA < tokenB ? tokenB : tokenA
        ));

        Pair storage pair = pairStorage[pairKey];
        (reserveA, reserveB) = (pair.reserveA, pair.reserveB); 
    }

}
