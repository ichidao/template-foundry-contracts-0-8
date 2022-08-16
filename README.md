# Introduction

This is a forge template repo so you can easily get started with Foundry with Solidity 0.8.  To use this as a template do the following:

```bash
forge init --template https://github.com/ichidao/template-foundry-contracts-0-8 project_name
```

Below is instructions for using this developing and using Foundry/forge with this project.

## Getting Started

Note that this is a template repository targeting Solidity 0.8 and you should create new repos and target this as a template.

Install and update foundry.

```bash
curl -L https://foundry.paradigm.xyz/ | bash
foundryup
```

Select the correct solidity version:

```bash
solc-select use 0.8.16
```

Install dependencies, set env vars and test.

```bash
git clone git@github.com:ichidao/foundry-contracts.git
cd foundry-contracts
forge install
export MAINNET_RPC_URL=https://mainnet.infura.io/v3/REPLACE_ME
export ETHERSCAN_API_KEY=REPLACE_ME
forge test -vvv --etherscan-api-key $ETHERSCAN_API_KEY
```

## Development

### Setup

Note that dependencies are managed via git submodules and the below is purely for reference:

```bash
forge install foundry-rs/forge-std
forge install transmissions11/solmate
forge install OpenZeppelin/openzeppelin-contracts@v4.7.3
```

### Building

```bash
forge build
```

### Testing

```bash
forge test -vvv --etherscan-api-key $ETHERSCAN_API_KEY
forge test -vvv --match-test "testName" --etherscan-api-key $ETHERSCAN_API_KEY
```

### Analyzing

```bash
pip3 install slither-analyzer
pip3 install solc-select
solc-select install 0.8.16
solc-select use 0.8.16
slither src/contracts/Contract.sol
```

### Test Deploy to Forked Mainnet

```bash
export ALICE=0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
anvil --fork-url https://mainnet.infura.io/v3/$INFURA_ID

# --------------------------------------------------
# Deploy via scripting, not verification won't
# work in a forked environment
# --------------------------------------------------
forge script script/DeployContract.mainnet.s.sol:DeployContract \
  --fork-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  -vvvv \
  --sender $ALICE

# --------------------------------------------------
# Deploy directly via creating, these do the same
# but the above scripting is easier
# Note verification won't work in a forked env.
# --------------------------------------------------
forge create --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/contracts/Contract.sol:Contract \
  --etherscan-api-key $ETHERSCAN_API_KEY \
```

### Test Deploy to Goerli

Have a test MetaMask wellet and switch it to Goerli.

Use [https://goerlifaucet.com/](https://goerlifaucet.com/) to send some Goerli ETH.

```bash
export SENDER=<Account address, for ex. a MetaMask test account address>

# --------------------------------------------------
# Deploy the contract via the Forge scripting
# --------------------------------------------------
forge script script/DeployContract.goerli.s.sol:DeployContract \
  --rpc-url https://goerli.infura.io/v3/$INFURA_ID \
  -i 1 \
  --optimize \
  --optimizer-runs 200 \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  -vvvv \
  --sender $SENDER

# --------------------------------------------------
# If the verification fails above re-run the above
# without the --broadcast to re-check the verification
# --------------------------------------------------
forge script script/DeployContract.goerli.s.sol:DeployContract \
  --rpc-url https://goerli.infura.io/v3/$INFURA_ID \
  -i 1 \
  --optimize \
  --optimizer-runs 200 \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  -vvvv \
  --sender $SENDER

# ------------------------------------------------------
# Call forge create directly, the above is preferred
# but this works too
# ------------------------------------------------------
forge create --chain goerli \
  --force \
  --optimize \
  --optimizer-runs 200 \
  --rpc-url https://goerli.infura.io/v3/$INFURA_ID \
  --constructor-args 0x9b0757aCaCA5160CEBc3D16769E4f2bCe71BFbF2 10000 \
  -i src/contracts/Contract.sol:Contract \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --verify

# ------------------------------------------------------
# This shouldn't be necessary but if you want to directly
# verify a contract the below the script is an example
# ------------------------------------------------------
forge verify-contract --chain-id 5 \
  --num-of-optimizations 200 \
  0x54b0E44840032EdcD03a27e3a0cb77a64aD6204A src/contracts/Deploy.sol:Deploy $ETHERSCAN_API_KEY

# ------------------------------------------------------
# Manually check the status of a verification GUID
# ------------------------------------------------------
forge verify-check --chain-id 5 spzud5ksw8isuglvjg1wsxtyv8y3ab71qpsfrp42rbhdqyh65c $ETHERSCAN_API_KEY

# ------------------------------------------------------
# To manually encode the constructor args
# ------------------------------------------------------
cast abi-encode "constructor(address,uint32)" 0x9b0757aCaCA5160CEBc3D16769E4f2bCe71BFbF2 10000
```

References:

- [Verification examples](https://github.com/foundry-rs/foundry/issues/852)
- [solc versions](https://etherscan.io/solcversions)

### Debugging

```bash
forge test -vvv --debug "testName" --etherscan-api-key $ETHERSCAN_API_KEY
```

### Deployment & Verification

Inside the [`utils/`](./utils/) directory are a few preconfigured scripts that can be used to deploy and verify contracts.

Scripts take inputs from the cli, using silent mode to hide any sensitive information.

_NOTE: These scripts are required to be **executable** meaning they must be made executable by running `chmod +x ./utils/*`._

_NOTE: these scripts will prompt you for the contract name and deployed addresses (when verifying). Also, they use the `-i` flag on `forge` to ask for your private key for deployment. This uses silent mode which keeps your private key from being printed to the console (and visible in logs)._

### First time with Forge/Foundry?

See the official Foundry installation [instructions](https://github.com/foundry-rs/foundry/blob/master/README.md#installation).

Then, install the [foundry](https://github.com/foundry-rs/foundry) toolchain installer (`foundryup`) with:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

Now that you've installed the `foundryup` binary,
anytime you need to get the latest `forge` or `cast` binaries,
you can run `foundryup`.

So, simply execute:

```bash
foundryup
```

🎉 Foundry is installed! 🎉

## Troubleshooting

When deploying a contract you may see `ProviderError(JsonRpcError(JsonRpcError { code: -32000, message: "execution reverted", data: None }))`.   This could happen if you have incorrect constructor args.  For example if deploying the ICHISpotOracleUSDUniswapV3 to goerli but you are using the mainnet ICHI V2 address, this error can happen.

## License

[AGPL-3.0-only](https://github.com/abigger87/foundry-contracts/blob/master/LICENSE)

## Acknowledgements

- [femplate](https://github.com/abigger87/femplate)
- [foundry](https://github.com/foundry-rs/foundry)
- [solmate](https://github.com/Rari-Capital/solmate)
- [forge-std](https://github.com/brockelmore/forge-std)
- [forge-template](https://github.com/foundry-rs/forge-template)
- [foundry-toolchain](https://github.com/foundry-rs/foundry-toolchain)
