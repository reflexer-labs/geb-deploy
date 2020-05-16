# GEB Deploy

This repository contains the smart contract code and bash scripts for deploying the whole `geb` system and provides an initial set up.

## Deployment

### Prerequisites:

- seth/dapp (https://dapp.tools/)

### Steps:
- `export ETH_FROM=YOUR_DEPLOYMENT_ACCOUNT`
- `export ETH_PASSWORD=ACCOUNT_PASSWORD_FILE_PATH`
- `export ETH_KEYSTORE=KEYSTORE_PATH` (If not using the default one)
- `export SETH_CHAIN=<kovan || ropsten || rinkeby || mainnet>` or `export ETH_RPC_URL=YOUR_RPC_NODE_URL`
- `./bin/deploy-all`
