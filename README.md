# Task: NFT Lottery

You have to create a NFT Lottery on a Sepolia test network.
Users should be able to buy a ticket which is an actual NFT. The funds from each ticket purchase are gathered in a prize pool. After a certain period of time a random winner should be chosen. We also want to be able to update our NFT tickets in the future.

### Contracts:
## Ticket
* You should create NFT contract that represents a ticket.
    * A ticket should have simple metadata on-chain data.
        * **Bonus** * Additional data can be stored off-chain.
    * Users should be able to buy tickets.
    * Starting from a particular block people can buy tickets for limited time.
    * Funds from purchases should be stored in the contract.
        * Only the contract itself can use these funds.
    * After purchase time ends a random winner should be selected. You can complete simple random generation.
    * A function for a surprise winner should be created which will award the random generated winner with 50% of the gathered funds.

## Proxy
* A simple proxy contract should be created that should use the deployed ticket as its implementation.

## Factory
* The factory should be able to deploy proxies.
    * **Bonus** * The proxy deployment can be achieved using create2.

### Environment
* The written contracts should be deployed on a Sepolia test network environment.
* A sample purchases should be acomplished.
* For the purpose of the task a surprise winner should be selected before the time ends, collecting 50% of the gathered funds. At the end of the time another winner will collect all gathered funds left.
* **Bonus** * Write simple tests verifying the deployment and the lottery winner.

The complicity of the contracts and testing is up to you.

### What can be used:

* Solidity
* JS
* Sepolia
* Foundry
* Hardhat
* Ethers / Web3
* Any other library considered necessary


## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
