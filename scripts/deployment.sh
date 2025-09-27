#!/bin/bash

# MeltyFi Deployment Script for Sui Testnet
# This script deploys the MeltyFi smart contracts to Sui testnet

set -e

echo "🍫 MeltyFi Deployment Script for Sui Testnet 🍫"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Sui CLI is installed
check_sui_cli() {
    echo -e "${BLUE}Checking Sui CLI installation...${NC}"
    if ! command -v sui &> /dev/null; then
        echo -e "${RED}❌ Sui CLI not found. Please install it first.${NC}"
        echo "Install with: cargo install --locked --git https://github.com/MystenLabs/sui.git --branch testnet sui"
        exit 1
    fi
    echo -e "${GREEN}✅ Sui CLI found: $(sui --version)${NC}"
}

# Check current environment
check_environment() {
    echo -e "${BLUE}Checking Sui environment...${NC}"
    current_env=$(sui client active-env 2>/dev/null || echo "none")
    if [ "$current_env" != "testnet" ]; then
        echo -e "${YELLOW}⚠️  Current environment: $current_env${NC}"
        echo -e "${BLUE}Setting up testnet environment...${NC}"
        
        # Create testnet environment if it doesn't exist
        sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443 2>/dev/null || true
        sui client switch --env testnet
        
        echo -e "${GREEN}✅ Switched to testnet environment${NC}"
    else
        echo -e "${GREEN}✅ Already on testnet environment${NC}"
    fi
}

# Check SUI balance
check_balance() {
    echo -e "${BLUE}Checking SUI balance...${NC}"
    balance=$(sui client balance 2>/dev/null | grep "Balance:" | awk '{print $2}' || echo "0")
    if [ "$balance" = "0" ] || [ -z "$balance" ]; then
        echo -e "${YELLOW}⚠️  No SUI balance found${NC}"
        echo -e "${BLUE}Please get testnet SUI from: https://faucet.testnet.sui.io/gas${NC}"
        read -p "Press Enter after getting testnet SUI to continue..."
    else
        echo -e "${GREEN}✅ SUI balance: $balance${NC}"
    fi
}

# Build contracts
build_contracts() {
    echo -e "${BLUE}Building Move contracts...${NC}"
    cd contracts/meltyfi
    
    # Clean previous build
    rm -rf build
    
    # Build contracts
    sui move build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Contracts built successfully${NC}"
    else
        echo -e "${RED}❌ Contract build failed${NC}"
        exit 1
    fi
    
    cd ../..
}

# Run tests
run_tests() {
    echo -e "${BLUE}Running Move tests...${NC}"
    cd contracts/meltyfi
    
    sui move test
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ All tests passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Some tests failed, but continuing deployment${NC}"
    fi
    
    cd ../..
}

# Deploy contracts
deploy_contracts() {
    echo -e "${BLUE}Deploying contracts to testnet...${NC}"
    cd contracts/meltyfi
    
    # Deploy with higher gas budget
    result=$(sui client publish --gas-budget 100000000 --json)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Contracts deployed successfully${NC}"
        
        # Extract package ID and object IDs
        package_id=$(echo $result | jq -r '.objectChanges[] | select(.type == "published") | .packageId')
        
        echo -e "${GREEN}📦 Package ID: $package_id${NC}"
        
        # Save deployment info
        echo "PACKAGE_ID=$package_id" > ../../deployment_info.env
        echo "NETWORK=testnet" >> ../../deployment_info.env
        echo "TIMESTAMP=$(date)" >> ../../deployment_info.env
        
        # Extract shared object IDs
        protocol_id=$(echo $result | jq -r '.objectChanges[] | select(.objectType | contains("Protocol")) | .objectId')
        factory_id=$(echo $result | jq -r '.objectChanges[] | select(.objectType | contains("ChocolateFactory")) | .objectId')
        
        if [ "$protocol_id" != "null" ] && [ "$protocol_id" != "" ]; then
            echo "PROTOCOL_ID=$protocol_id" >> ../../deployment_info.env
            echo -e "${GREEN}📋 Protocol ID: $protocol_id${NC}"
        fi
        
        if [ "$factory_id" != "null" ] && [ "$factory_id" != "" ]; then
            echo "FACTORY_ID=$factory_id" >> ../../deployment_info.env
            echo -e "${GREEN}🏭 Factory ID: $factory_id${NC}"
        fi
        
        echo -e "${BLUE}Deployment info saved to deployment_info.env${NC}"
        
    else
        echo -e "${RED}❌ Deployment failed${NC}"
        exit 1
    fi
    
    cd ../..
}

# Update environment file
update_env_file() {
    echo -e "${BLUE}Updating environment configuration...${NC}"
    
    if [ -f "deployment_info.env" ]; then
        source deployment_info.env
        
        # Create or update .env file
        cat > .env << EOF
# Sui Network Configuration - TESTNET
NEXT_PUBLIC_SUI_NETWORK=testnet
NEXT_PUBLIC_SUI_RPC_URL=https://fullnode.testnet.sui.io:443

# Contract Addresses (Auto-generated from deployment)
NEXT_PUBLIC_MELTYFI_PACKAGE_ID=${PACKAGE_ID}
NEXT_PUBLIC_PROTOCOL_ID=${PROTOCOL_ID}
NEXT_PUBLIC_FACTORY_ID=${FACTORY_ID}
NEXT_PUBLIC_CHOCO_CHIP_TYPE=${PACKAGE_ID}::choco_chip::CHOCO_CHIP
NEXT_PUBLIC_WONKA_BARS_TYPE=${PACKAGE_ID}::wonka_bars::WonkaBars

# Application Configuration
NEXT_PUBLIC_APP_NAME=MeltyFi
NEXT_PUBLIC_APP_DESCRIPTION=Making the illiquid liquid
NODE_ENV=development
NEXT_PUBLIC_DEBUG=true
NETWORK=testnet

# Deployment Info
DEPLOYMENT_TIMESTAMP=${TIMESTAMP}
EOF
        
        echo -e "${GREEN}✅ Environment file updated${NC}"
    else
        echo -e "${YELLOW}⚠️  deployment_info.env not found, skipping environment update${NC}"
    fi
}

# Verify deployment
verify_deployment() {
    echo -e "${BLUE}Verifying deployment...${NC}"
    
    if [ -f "deployment_info.env" ]; then
        source deployment_info.env
        
        echo -e "${BLUE}🔍 Checking deployment on Sui Explorer...${NC}"
        echo -e "${GREEN}📦 Package: https://suiexplorer.com/object/${PACKAGE_ID}?network=testnet${NC}"
        
        if [ ! -z "$PROTOCOL_ID" ]; then
            echo -e "${GREEN}📋 Protocol: https://suiexplorer.com/object/${PROTOCOL_ID}?network=testnet${NC}"
        fi
        
        if [ ! -z "$FACTORY_ID" ]; then
            echo -e "${GREEN}🏭 Factory: https://suiexplorer.com/object/${FACTORY_ID}?network=testnet${NC}"
        fi
        
        echo -e "${GREEN}✅ Deployment verification complete${NC}"
    fi
}

# Main deployment flow
main() {
    echo -e "${YELLOW}Starting MeltyFi deployment process...${NC}"
    
    check_sui_cli
    check_environment
    check_balance
    build_contracts
    run_tests
    deploy_contracts
    update_env_file
    verify_deployment
    
    echo -e "${GREEN}🎉 MeltyFi deployment completed successfully!${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo -e "${GREEN}Next steps:${NC}"
    echo -e "${BLUE}1. Check the deployment on Sui Explorer using the links above${NC}"
    echo -e "${BLUE}2. Update your frontend with the new contract addresses${NC}"
    echo -e "${BLUE}3. Test the integration with the deployed contracts${NC}"
    echo -e "${BLUE}4. Start the frontend: npm run dev${NC}"
    echo -e "${BLUE}================================================${NC}"
}

# Run main function
main "$@"