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
| SimpleSwap | `0x4787D1dC706c89020570BB88Ee380Fd4B682e009` |
| TokenA     | `0xedFED3cF27894869a6C73c9B9404a3e826DFA07E` |
| TokenB     | `0x8370b856eA384D7237C6CBA5f3F4421012170152` |

---



