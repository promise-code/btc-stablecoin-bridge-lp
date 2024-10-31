# Bitcoin-Stablecoin Bridge with LP Integration

A secure and efficient smart contract implementation of a Bitcoin-backed stablecoin system with integrated liquidity pool functionality. This contract enables users to mint stablecoins using Bitcoin as collateral while also providing liquidity pool features for decentralized trading.

## Features

- **Collateralized Stablecoin Minting**: Mint stablecoins backed by Bitcoin collateral
- **Dynamic Collateral Ratio**: Maintain a minimum collateralization ratio of 150%
- **Liquidation Protection**: Liquidation threshold set at 130%
- **Integrated Liquidity Pool**: Provide liquidity and earn fees
- **Price Oracle Integration**: External price feed support for accurate BTC/USD pricing
- **Precision Handling**: 6 decimal places precision for accurate calculations

## Key Parameters

- Minimum Collateral Ratio: 150%
- Liquidation Ratio: 130%
- Minimum Deposit: 0.01 BTC (1,000,000 sats)
- Pool Fee Rate: 0.3%
- Price Precision: 6 decimal places
- Maximum Price: 1,000,000 USD (with 6 decimal precision)
- Maximum Mint Amount: 10,000 USD (with 6 decimal precision)

## Core Functions

### Vault Management

```clarity
(deposit-collateral (btc-amount uint))
(mint-stablecoin (amount uint))
(burn-stablecoin (amount uint))
```

### Liquidity Pool Operations

```clarity
(add-liquidity (btc-amount uint) (stable-amount uint))
(remove-liquidity (lp-tokens uint))
```

### Oracle and Administrative Functions

```clarity
(initialize (initial-price uint))
(update-price (new-price uint))
```

### Read-Only Functions

```clarity
(get-vault-details (owner principal))
(get-collateral-ratio (owner principal))
(get-pool-details)
(get-lp-details (provider principal))
```

## Error Codes

| Code | Description |
|------|-------------|
| 1000 | Not authorized |
| 1001 | Insufficient balance |
| 1002 | Invalid amount |
| 1003 | Insufficient collateral |
| 1004 | Pool empty |
| 1005 | Slippage too high |
| 1006 | Below minimum |
| 1007 | Above maximum |
| 1008 | Already initialized |
| 1009 | Not initialized |
| 1010 | Invalid price |

## Security Features

1. **Access Control**: Contract owner authentication for sensitive operations
2. **Balance Checks**: Strict validation of all balance modifications
3. **Price Validation**: Bounds checking on oracle price updates
4. **Amount Validation**: Maximum and minimum bounds on all operations
5. **Safe Math**: Overflow protection in mathematical operations

## Usage Examples

### Minting Stablecoins

1. Deposit Bitcoin collateral:
```clarity
(contract-call? .bitcoin-stablecoin-bridge deposit-collateral u1000000)
```

2. Mint stablecoins:
```clarity
(contract-call? .bitcoin-stablecoin-bridge mint-stablecoin u500000)
```

### Providing Liquidity

1. Add liquidity to the pool:
```clarity
(contract-call? .bitcoin-stablecoin-bridge add-liquidity u1000000 u50000000)
```

2. Remove liquidity:
```clarity
(contract-call? .bitcoin-stablecoin-bridge remove-liquidity u100000)
```

## Implementation Notes

- The contract uses a square root formula for calculating LP tokens to ensure fair distribution
- Collateral ratios are continuously monitored to maintain system stability
- The liquidity pool implements a constant product market maker model
- All monetary values are handled with 6 decimal places precision

## Architecture

The contract is structured around four main components:

1. **Vault System**: Manages user collateral and minted stablecoins
2. **Liquidity Pool**: Handles decentralized trading functionality
3. **Price Oracle**: Maintains up-to-date BTC/USD price information
4. **Balance Management**: Tracks user balances and total supply

## Safety Considerations

- Always ensure sufficient collateralization when minting stablecoins
- Monitor oracle prices for significant changes
- Be aware of minimum deposit requirements
- Consider potential slippage when performing liquidity operations
- Review transaction parameters before execution

## Future Improvements

1. Implement governance mechanisms for parameter updates
2. Add flash loan protection
3. Integrate multiple collateral types
4. Implement automated liquidation mechanisms
5. Add yield farming capabilities