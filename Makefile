-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit && forge install transmissions11/solmate@v6 --no-commit && forge install OpenZeppelin/openzeppelin-contracts@v4.9.6 --no-commit   

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

deploy-sepolia:
	@forge script script/RaffleDeployer.s.sol:RaffleDeployer --rpc-url $(SEPOLIA_RPC_URL) --account myaccount --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

fund-subscription-sepolia:
	@forge script script/Interactions.s.sol:SubscriptionFunder --rpc-url $(SEPOLIA_RPC_URL) --account myaccount --broadcast

deploy:
	@forge script script/RaffleDeployer.s.sol:RaffleDeployer $(NETWORK_ARGS)

create-subscription:
	@forge script script/Interactions.s.sol:SubscriptionCreater $(NETWORK_ARGS)

add-consumer:
	@forge script script/Interactions.s.sol:ConsumerAdder $(NETWORK_ARGS)

fund-subscription:
	@forge script script/Interactions.s.sol:SubscriptionFunder $(NETWORK_ARGS)

test-sepolia:
	@forge test -vvvvv --fork-url $(SEPOLIA_RPC_URL)

test-mainnet:
	@forge test -vvvv --fork-url $(MAINNET_RPC_URL)

snapshot: 
	@forge snapshot -vvvv

save-private-key:
	@cast wallet import defaultKey --interactive

show-wallets:
	@cast wallet list

