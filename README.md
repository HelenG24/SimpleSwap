# SimpleSwap Contract

Uniswap V2-style decentralized exchange implementation supporting:
- Liquidity provision/removal
- Token swaps with 0.3% fee
- Price oracle functionality

## Features
1. **Add Liquidity**: Deposit tokens to create new pools or expand existing ones.
2. **Remove Liquidity**: Withdraw proportional token reserves by burning LP tokens.
3. **Token Swaps**: Trade tokens using constant product formula with fees.
4. **Price Oracle**: Get real-time token prices based on pool reserves.

## Technical Details
### Core Functions
| Function                   | Description                                                                 |
|----------------------------|-----------------------------------------------------------------------------|
| `addLiquidity()`           | Adds tokens to liquidity pool, mints LP tokens                              |
| `removeLiquidity()`        | Burns LP tokens, returns proportional token reserves                        |
| `swapExactTokensForTokens`| Swaps exact input tokens for output tokens (0.3% fee)                      |
| `getAmountOut()`           | Calculates output amount for given input (pure math)                        |

### Pricing Mechanism
Uses constant product formula:  
**`reserve0 * reserve1 = k`**  
Swap fees: **0.3%** applied to input amount.  
LP tokens minted based on geometric mean of deposits for new pools.

### Security Features
- Reentrancy protection via Checks-Effects-Interactions
- Deadline validation for transactions
- Minimum liquidity locking (1,000 wei)
- Input validation for swap amounts

## Usage
### Deploying
1. Compile with Solidity 0.8.20+
2. Deploy to EVM-compatible network

### Interacting
**Add Liquidity:**
```javascript
addLiquidity(
  tokenA, tokenB, 
  amountADesired, amountBDesired,
  amountAMin, amountBMin,
  to, deadline
)
