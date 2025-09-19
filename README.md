# MintTestCoin on Aptos Testnet

A Move package that defines a test coin with dynamic metadata management and minting capabilities.

## Features

- **Dynamic Metadata Management**: Update coin name, symbol, decimals, and mintable status
- **Minting Control**: Pause/resume minting functionality
- **Flexible Minting**: Mint to self or any recipient address
- **Admin Controls**: Module address controls all administrative functions
- **Error Handling**: Comprehensive error codes for different scenarios

## Prerequisites
- Install Aptos CLI.
- Have a funded testnet account (faucet).

## Setup
```bash
# Configure your Aptos profile
aptos init --network testnet --profile mint_profile --assume-yes

# Check your account address
aptos account list --profile mint_profile | cat
```

Locate your account address (e.g., 0xabc...). You will use it as the named address `MintToken` when publishing.

## Publish
```bash
# From repo root
aptos move publish \
  --named-addresses MintToken=$(aptos config show-profiles --json | jq -r '.Result["mint_profile"].account') \
  --profile mint_profile \
  --assume-yes
```

If you prefer, replace the `--named-addresses` value with your hex address directly, e.g. `MintToken=0xabc...`.

## Initialize the coin
Run the `init_module` entry function once from the module/publisher account.
```bash
aptos move run --function-id "MintToken::mint_test_coin::init_module" \
  --profile mint_profile --assume-yes
```

## Minting Functions

### Mint to self (caller)
```bash
aptos move run --function-id "MintToken::mint_test_coin::mint" \
  --args u64:1000000 \
  --profile mint_profile --assume-yes
```
**Note**: Minting will fail if the contract is paused (see metadata management below).

### Mint to another address (admin only)
```bash
RECIPIENT=0x<hex>
aptos move run --function-id "MintToken::mint_test_coin::mint_to" \
  --args address:$RECIPIENT u64:1000000 \
  --profile mint_profile --assume-yes
```
**Note**: Only the module address can call this function.

## Metadata Management

The contract now supports dynamic metadata updates. Only the module address can modify metadata.

### Update coin metadata
```bash
# Update name, symbol, decimals, and mintable status
aptos move run --function-id "MintToken::mint_test_coin::update_metadata" \
  --args string:"My Token" string:"MTK" u8:8 bool:true \
  --profile mint_profile --assume-yes
```

### Pause/Resume minting
```bash
# Pause minting
aptos move run --function-id "MintToken::mint_test_coin::set_mintable" \
  --args bool:false \
  --profile mint_profile --assume-yes

# Resume minting
aptos move run --function-id "MintToken::mint_test_coin::set_mintable" \
  --args bool:true \
  --profile mint_profile --assume-yes
```

### View current metadata
```bash
# Get current metadata (name, symbol, decimals, is_mintable)
aptos move run --function-id "MintToken::mint_test_coin::get_metadata" \
  --profile mint_profile --assume-yes

# Check if minting is currently allowed
aptos move run --function-id "MintToken::mint_test_coin::is_mintable" \
  --profile mint_profile --assume-yes
```

## Check balances
```bash
OWNER=$(aptos config show-profiles --json | jq -r '.Result["mint_profile"].account')
aptos account balance --account $OWNER --profile mint_profile | cat
```

## Notes
- **Permissions**: Module address `MintToken` controls `mint_to` and all metadata management functions. Anyone can call `mint` on their own after `init_module` is executed by the module address.
- **Dynamic Metadata**: The contract supports updating coin name, symbol, decimals, and mintable status after deployment.
- **Minting Control**: Minting can be paused/resumed by the module address. All minting functions will fail when paused.
- **Default Values**: Initial decimals: 6, Symbol: USDC, Name: USDC Coin, Mintable: true.
- **Error Codes**: 
  - `1`: Non-module address calling init_module
  - `2`: Non-module address calling mint_to
  - `3`: Non-module address calling update_metadata
  - `4`: Non-module address calling set_mintable
  - `5`: Attempting to mint when paused
