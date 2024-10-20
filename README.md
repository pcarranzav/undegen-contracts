# Undegen Smart Contracts

Built at EthGlobal SF 2024.

**Undegen is a personal finance tools that uses finance research (Merton's portfolio problem) to help investors establish an optimal portfolio tuned to their risk-aversion.**

It was inspired by the book "The Missing Billionares" by James White and Victor Haghani.

## UI repo

The repo for the app is available at https://github.com/IainM22/eth-hack-ui

## Architecture

The Undegen protocol relies on the user's assets being in a Gnosis Safe.
The UndegenModule has to be added as a module to the Safe.

The user transfers a certain amount of USDC to the Safe, and
initiates a transaction on the Safe that calls the UndegenModule's rebalance() function.

The UndegenModule will then call back into the Safe (where it is allowed to execute transactions, as it is an authorized Safe Module), doing a delegatecall to the UndegenRebalancer contract that executes the necessary actions to rebalance the portfolio.

The module is needed because, as far as we could tell, you can't trigger a delegatecall directly through Pimlico, and it also allows us to keep some state (the bond maturity and amount for each Safe).

This architecture allows the rebalancing to happen without the need for any explicit approvals, and with a single transaction. The flow is still user-initiated, as the transaction to execute the rebalancing has to be executed by the Safe. The user transaction specifies the amount of each risky asset to hold, in USD, and the rest will be deposited into a long position on a USDC fixed-rate pool on [Hyperdrive](https://hyperdrive.box), that is treated as the "risk-free" asset.

For the risky assets, we use Uniswap to buy a basket of tokens.

The contract uses [Chronicle](https://chroniclelabs.org) oracles to convert between token prices and USD.

## Future improvements

- Use a more comprehensive set of risky assets (e.g. creating positions on DeFi protocols)
- Use a more diverse set of "risk-free" assets (e.g. combining several Hyperdrive pools)
- Allow rebalance() to be called automatically by a relayer authorized by the user (so that Undegen can autorebalance without user input)
- Conditionally allow rebalancing the portfolio before bonds have matured
- Slippage protection everywhere! (This hackathon version is ultra dangerous)

## Usage

The project uses both Hardhat and Foundry for convenience.

### Build

```shell
$ npm run build
```

### Test

```shell
$ npm run test
```

### Format

```shell
$ npm run lint
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## Deployments

UndegenRebalancer: https://sepolia.basescan.org/address/0xD4fD69c36B37F023Ec8338B83b4ae3b6913b3c10#code

UndegenModule: https://sepolia.basescan.org/address/0x5186c4c1E7873408378C0E72BF2c8B7580BAfa03#code
