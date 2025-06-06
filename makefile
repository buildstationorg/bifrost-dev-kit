-include .env

build:
	forge build

test-all:
	forge test -vvvv

deploy-mainnet:
	forge script script/Deploy.s.sol --rpc-url ${BASE_RPC} --account dev --sender ${SENDER} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

deploy-testnet:
	forge script script/Deploy.s.sol --rpc-url ${BASE_SEPOLIA_RPC} --account dev --sender ${SENDER} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

deploy-all-contracts-on-all-networks:
	forge script script/DeployAllContracts.s.sol --slow --multi --broadcast --account dev --sender ${SENDER} --verify -vvvv

deploy-l2slpx-bsc-testnet:
	forge script script/DeployL2SlpxContracts.s.sol --rpc-url ${BSC_TESTNET_RPC_URL} --account dev --sender ${SENDER} --broadcast --with-gas-price 5000000000 --verify --verifier etherscan --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

setup-l2slpx-bsc-testnet:
	forge script script/SetupL2SlpxContracts.s.sol --rpc-url ${BSC_TESTNET_RPC_URL} --account dev --sender ${SENDER} --broadcast -vvvv

deploy-l2slpx-unichain-with-create3:
	forge script script/DeployL2SlpxContracts.s.sol --rpc-url ${UNICHAIN_SEPOLIA_RPC_URL} --account dev --sender ${SENDER} --broadcast --verify --etherscan-api-key ${UNICHAIN_SEPOLIA_ETHERSCAN_API_KEY} -vvvv

deploy-l2slpx-unichain-sepolia:
	forge script script/DeployL2SlpxContracts.s.sol --rpc-url ${UNICHAIN_SEPOLIA_RPC_URL} --account dev --sender ${SENDER} --broadcast --verify --verifier etherscan --verifier-url "https://api-sepolia.uniscan.xyz/api" --verifier-api-key ${UNICHAIN_SEPOLIA_ETHERSCAN_API_KEY} -vvvv

setup-l2slpx-unichain-sepolia:
	forge script script/SetupL2SlpxContracts.s.sol --rpc-url ${UNICHAIN_SEPOLIA_RPC_URL} --account dev --sender ${SENDER} --broadcast -vvvv

deploy-l2slpx-base-sepolia:
	forge script script/DeployL2SlpxContracts.s.sol --rpc-url ${BASE_SEPOLIA_RPC_URL} --account dev --sender ${SENDER} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

deploy-l2slpx-arbitrum-sepolia:
	forge script script/DeployL2SlpxContracts.s.sol --rpc-url ${ARBITRUM_SEPOLIA_RPC_URL} --account dev --sender ${SENDER} --broadcast --verify --verifier etherscan --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

setup-l2slpx-arbitrum-sepolia:
	forge script script/SetupL2SlpxContracts.s.sol --rpc-url ${ARBITRUM_SEPOLIA_RPC_URL} --account dev --sender ${SENDER} --broadcast -vvvv

setup-all-contracts-on-all-networks:
	forge script script/SetupAllContracts.s.sol --slow --multi --broadcast --account dev --sender ${SENDER} -vvvv

interact:
	forge script script/Interactions.s.sol --rpc-url ${BASE_SEPOLIA_RPC} --account dev --sender ${SENDER} --broadcast -vvvv

verify-contract:
	forge verify-contract --chain-id ${CHAIN_ID} --num-of-optimizations 200 --watch --constructor-args $(cast abi-encode "constructor(address)" ${OWNER_ADDRESS}) --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version v0.8.28+commit.7893614a ${CONTRACT_ADDRESS} src/L2Slpx/L2Slpx.sol:L2Slpx

deploy-yield-delegation-vault-base-sepolia:
	forge script script/DeployYieldDelegationVault.s.sol --rpc-url ${BASE_SEPOLIA_RPC_URL} --account dev --sender ${SENDER} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv