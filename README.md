# BRIX Donation dApp - Smart Contracts

A Web3 donation platform built on Polygon (Amoy Testnet) using Hardhat and TypeScript.

## 🚀 Features

- **Smart Contract (Donate.sol)**: Supports item creation and donations with an automatic 10% platform fee split.
- **TypeScript Support**: Full Typechain integration for strictly typed contract interactions.
- **pnpm**: Fast and efficient package management.
- **Robust Tooling**: Prettier, ESLint, Solhint, and Husky (Conventional Commits).
- **CI/CD**: Automatic testing and deployment via GitHub Actions.

## 🛠 Prerequisites

- Node.js (v20+)
- pnpm

## 📦 Installation

```bash
pnpm install
```

Set up your `.env` file based on the provided placeholders:

```env
PRIVATE_KEY="your_wallet_private_key"
POLYGON_AMOY_RPC_URL="https://polygon-amoy.drpc.org"
ETHERSCAN_API_KEY="your_polygonscan_api_key"
```

## 📜 Available Commands

### Development

- `pnpm run compile`: Compile smart contracts and generate typings.
- `pnpm run test`: Run the full test suite.
- `pnpm run coverage`: Generate code coverage report.

### Quality Control

- `pnpm run lint`: Run ESLint and Solhint checks.
- `pnpm run format`: Format the codebase using Prettier.
- `pnpm run format:check`: Verify code formatting.

### Deployment & Verification

- `pnpm run deploy:amoy`: Deploy the `Donate` contract to Polygon Amoy.
- `pnpm run verify:amoy <CONTRACT_ADDRESS> <ARGUMENTS>`: Verify contract source code on Polygonscan.

## 🌐 Deployment (CI/CD)

The project includes a GitHub Action for manual deployment:

1. Go to **Actions** -> **Deploy Smart Contracts**.
2. Click **Run workflow**.
3. _Requires `PRIVATE_KEY` and `POLYGON_AMOY_RPC_URL` to be set in GitHub Repository Secrets._

## 🙏 Special Thanks

Special thanks to the **[Polygon Community Discord](https://discord.gg/0xpolygoncommunity)** for helping provide free testnet MATIC from the Polygon Amoy faucet (check the `#pol-faucet` channel).
