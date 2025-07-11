# SimpleSwap Contract

A minimal decentralized exchange smart contract inspired by Uniswap V2, implemented in Solidity.

## 🔧 Contract Features

This contract supports the following core functionalities:

1. **Add Liquidity**
2. **Remove Liquidity**
3. **Swap Tokens**
4. **Get Token Price**
5. **Calculate Output Amount**

---

## 📘 Functions Overview

### `addLiquidity(...)`

```solidity
function addLiquidity(
  address tokenA,
  address tokenB,
  uint amountADesired,
  uint amountBDesired,
  uint amountAMin,
  uint amountBMin,
  address to,
  uint deadline
) external returns (uint amountA, uint amountB, uint liquidity);
```

**Description**: Adds tokens to a liquidity pool and mints LP tokens to the provider.

---

### `removeLiquidity(...)`

```solidity
function removeLiquidity(
  address tokenA,
  address tokenB,
  uint liquidity,
  uint amountAMin,
  uint amountBMin,
  address to,
  uint deadline
) external returns (uint amountA, uint amountB);
```

**Description**: Burns LP tokens and returns the underlying token amounts proportionally.

---

### `swapExactTokensForTokens(...)`

```solidity
function swapExactTokensForTokens(
  uint amountIn,
  uint amountOutMin,
  address[] calldata path,
  address to,
  uint deadline
) external returns (uint[] memory amounts);
```

**Description**: Swaps an exact amount of input tokens for as many output tokens as possible, enforcing a minimum output.

---

### `getPrice(...)`

```solidity
function getPrice(address tokenA, address tokenB) external view returns (uint price);
```

**Description**: Returns the price of `tokenA` in terms of `tokenB`, scaled to 1e18.

---

### `getAmountOut(...)`

```solidity
function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut);
```

**Description**: Returns the output amount that would be received given an input amount and current reserves.

---

## 📍 Deployment Addresses (Sepolia Testnet)

| Contract   | Address                                      |
| ---------- | -------------------------------------------- |
| SimpleSwap | `0x90D04fD2D28A84286F097d7389120409DedCdDdd` |
| TokenA     | `0x26A9e1A86Ee91eCBB0e3c3De3b3f57770B9F21e7` |
| TokenB     | `0x9f64aF266c5F41970D7D528ca554Fd0D79A3ba21` |

---



