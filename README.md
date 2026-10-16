# Cross-Chain Rebase Token

A Foundry project for an ETH-backed rebase token that can be transferred between EVM chains with Chainlink CCIP.

## How it works

- **Deposit:** Users deposit ETH into `Vault` and receive an equal amount of `RebaseToken` (RBT).
- **Accruing balance:** Each account has an interest rate. Its displayed balance grows linearly with elapsed time; accrued interest is minted when the account next interacts with the token.
- **Redeem:** Users burn RBT to withdraw the corresponding amount of ETH from the vault. The vault needs enough ETH to cover withdrawals, including accrued rewards.
- **Interest rates:** New deposits use the current global rate. The owner can lower, but not raise, that rate. A recipient with no existing balance inherits the sender's rate on transfer.
- **Bridge:** `RebaseTokenPool` burns tokens on the source chain and mints them on the destination. The user's interest rate travels with the CCIP message.

## Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge`, `cast`)
- Git with support for submodules
- RPC access to Sepolia and Arbitrum Sepolia to run the fork-based cross-chain test

## Getting started

Clone the repository and its dependencies:

```sh
git clone --recurse-submodules <repository-url>
cd ccip-rebase-token
```

If you already cloned without submodules, initialize them with:

```sh
git submodule update --init --recursive
```

Build the contracts:

```sh
forge build
```

Run the tests:

```sh
forge test
```

The cross-chain test forks Sepolia and Arbitrum Sepolia using the `sepolia` and `arb-sepolia` RPC aliases in `foundry.toml`. Configure those aliases with RPC endpoints you control before running the fork test. Keep RPC credentials private; do not commit API keys or wallet secrets.

## Repository layout

| Path | Purpose |
| --- | --- |
| `src/RebaseToken.sol` | ERC-20 token with per-account linear interest |
| `src/Vault.sol` | Accepts ETH deposits and pays out redemptions |
| `src/RebaseTokenPool.sol` | CCIP token pool that preserves interest rates across chains |
| `src/interfaces/IRebaseToken.sol` | Token interface used by the vault and pool |
| `script/Deployer.s.sol` | Deploys the token, pool, and vault |
| `script/ConfigurePool.s.sol` | Configures a pool's remote chain, token, and rate limits |
| `script/BridgeTokens.s.sol` | Sends tokens through a CCIP router using LINK for fees |
| `test/RebaseTokenTest.t.sol` | Unit tests for interest, transfers, and vault behavior |
| `test/CrossChain.t.sol` | Fork-based CCIP bridge test |

## Deployment workflow

The scripts in `script/` are Foundry scripts. Before broadcasting transactions:

1. Configure the RPC endpoint for the target network and a funded Foundry account.
2. Deploy the token and pool with `TokenAndDeployer` in `script/Deployer.s.sol`.
3. Deploy the vault with `VaultDeployer`, passing the deployed token address.
4. Configure the local pool with the remote chain selector, pool and token addresses using `ConfigurePoolScript`.
5. Configure the corresponding remote pool, then use `BridgeTokensScript` to bridge RBT. The sender must hold RBT and enough LINK to pay the CCIP fee.

For example, Foundry scripts are invoked with `forge script <script-path>:<contract-name> --rpc-url <rpc-url> --account <account-name> --broadcast`. Review each script's `run` parameters and the target chain's CCIP network details before broadcasting. The included `bridgeToZksync.sh` is a network-specific example, not a general-purpose deployment script.

## Important considerations

- The token's displayed balance can increase without a new transfer or mint transaction. `principleBalanceOf` reports the stored token balance before unmaterialized interest.
- Interest is an accounting balance, not an automatic source of ETH. Fund the vault with sufficient ETH rewards before users redeem more than the vault's available ETH.
- Only trusted contracts should receive the token's mint-and-burn role. The vault needs it for deposits and redemptions; the pool needs it for bridging.
- Configure both pools with each other's chain selectors, pool addresses, and token addresses before sending cross-chain messages.

## License

This project is licensed under the MIT License.
