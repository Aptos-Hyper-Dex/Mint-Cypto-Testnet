# MintTestCoin on Aptos Testnet

A minimal Move package that defines a test coin and entry functions to mint.

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

## Mint to self (caller)
```bash
aptos move run --function-id "MintToken::mint_test_coin::mint" \
  --args u64:1000000 \
  --profile mint_profile --assume-yes
```
Here `6` decimals are used, so 1 token = 1_000_000 units.

## Mint to another address (admin only)
```bash
RECIPIENT=0x<hex>
aptos move run --function-id "MintToken::mint_test_coin::mint_to" \
  --args address:$RECIPIENT u64:1000000 \
  --profile mint_profile --assume-yes
```

## Check balances
```bash
OWNER=$(aptos config show-profiles --json | jq -r '.Result["mint_profile"].account')
aptos account balance --account $OWNER --profile mint_profile | cat
```

## Notes
- Module address `MintToken` controls `mint_to`. Anyone can call `mint` on their own after `init_module` is executed by the module address.
- Decimals: 6. Symbol: MINT. Name: Mint Test Coin.
