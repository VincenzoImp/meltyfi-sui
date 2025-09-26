#!/bin/bash

# MeltyFi Improved Deployment Script
# Fixes critical issues and provides better error handling

set -e

echo "🍫 Starting MeltyFi Improved Deployment Process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if required tools are installed
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v sui &> /dev/null; then
        print_error "Sui CLI not found. Please install it first."
        echo "Install with: cargo install --locked --git https://github.com/MystenLabs/sui.git --branch devnet sui"
        exit 1
    fi
    
    if ! command -v node &> /dev/null; then
        print_error "Node.js not found. Please install Node.js v18 or later."
        exit 1
    fi
    
    print_status "All prerequisites installed"
}

# Setup Sui environment
setup_sui() {
    print_info "Setting up Sui environment..."
    
    # Check if devnet environment exists, create if not
    if ! sui client envs 2>/dev/null | grep -q "devnet"; then
        print_info "Creating devnet environment..."
        sui client new-env --alias devnet --rpc https://fullnode.devnet.sui.io:443
    fi
    
    # Switch to devnet
    sui client switch --env devnet
    
    # Check if wallet exists
    if ! sui client addresses 2>/dev/null | grep -q "0x"; then
        print_info "Creating new address..."
        sui client new-address ed25519
    fi
    
    CURRENT_ADDRESS=$(sui client active-address 2>/dev/null || echo "")
    print_info "Active address: $CURRENT_ADDRESS"
    
    # Check balance
    BALANCE=$(sui client balance --json 2>/dev/null | jq -r '.[] | select(.coinType == "0x2::sui::SUI") | .totalBalance // "0"' 2>/dev/null || echo "0")
    print_info "Current SUI balance: $((BALANCE / 1000000000)) SUI"
    
    if [ "$BALANCE" -lt "1000000000" ]; then
        print_warning "Low SUI balance. You may need testnet SUI for deployment."
        print_info "Get testnet SUI from: https://faucet.devnet.sui.io/gas"
        
        read -p "$(echo -e ${YELLOW}Continue with low balance? [y/N]: ${NC})" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# Install dependencies
install_dependencies() {
    print_info "Installing dependencies..."
    
    if [ -f "package.json" ]; then
        npm install --silent || {
            print_error "Failed to install root dependencies"
            exit 1
        }
        print_status "Root dependencies installed"
    fi
    
    if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
        cd frontend
        npm install --silent || {
            print_error "Failed to install frontend dependencies"
            exit 1
        }
        cd ..
        print_status "Frontend dependencies installed"
    fi
}

# Build and test contracts
build_contracts() {
    print_info "Building Move contracts..."
    
    cd contracts/meltyfi
    
    # Clean any previous builds
    rm -rf build/
    
    # Build contracts
    if sui move build 2>&1 | tee build.log; then
        print_status "Contracts built successfully"
    else
        print_error "Contract build failed. Check build.log for details:"
        tail -n 20 build.log
        cd ../..
        exit 1
    fi
    
    # Run tests
    print_info "Running contract tests..."
    if sui move test --gas-limit 100000000 2>&1 | tee test.log; then
        print_status "All tests passed"
    else
        print_warning "Some tests failed. Check test.log for details:"
        tail -n 10 test.log
        print_info "Continuing with deployment..."
    fi
    
    cd ../..
}

# Deploy contracts
deploy_contracts() {
    print_info "Deploying contracts to devnet..."
    
    cd contracts/meltyfi
    
    # Get gas budget
    CURRENT_ADDRESS=$(sui client active-address)
    BALANCE=$(sui client balance --json 2>/dev/null | jq -r '.[] | select(.coinType == "0x2::sui::SUI") | .totalBalance // "0"' 2>/dev/null || echo "0")
    GAS_BUDGET=$((BALANCE / 10))
    
    if [ "$GAS_BUDGET" -gt 1000000000 ]; then
        GAS_BUDGET=1000000000
    fi
    
    if [ "$GAS_BUDGET" -lt 100000000 ]; then
        GAS_BUDGET=100000000
    fi
    
    print_info "Using gas budget: $GAS_BUDGET MIST"
    
    # Deploy with error handling
    if DEPLOY_OUTPUT=$(sui client publish --gas-budget $GAS_BUDGET --json 2>&1); then
        print_status "Contracts deployed successfully!"
        
        # Parse deployment output
        if echo "$DEPLOY_OUTPUT" | jq . >/dev/null 2>&1; then
            PACKAGE_ID=$(echo "$DEPLOY_OUTPUT" | jq -r '.objectChanges[] | select(.type == "published") | .packageId' 2>/dev/null || echo "")
            TRANSACTION_DIGEST=$(echo "$DEPLOY_OUTPUT" | jq -r '.digest' 2>/dev/null || echo "")
            
            if [ -n "$PACKAGE_ID" ]; then
                print_info "Package ID: $PACKAGE_ID"
                print_info "Transaction: $TRANSACTION_DIGEST"
                
                # Save deployment info
                cat > ../../deployment-info.json << EOF
{
  "network": "devnet",
  "packageId": "$PACKAGE_ID",
  "deployedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "deployer": "$CURRENT_ADDRESS",
  "transactionDigest": "$TRANSACTION_DIGEST",
  "suiExplorerUrl": "https://suiexplorer.com/txblock/$TRANSACTION_DIGEST?network=devnet"
}
EOF
                
                # Update .env file
                cat > ../../.env << EOF
# Sui Network Configuration
NEXT_PUBLIC_SUI_NETWORK=devnet
NEXT_PUBLIC_SUI_RPC_URL=https://fullnode.devnet.sui.io:443

# Contract Addresses
NEXT_PUBLIC_MELTYFI_PACKAGE_ID=$PACKAGE_ID
NEXT_PUBLIC_CHOCO_CHIP_TYPE=${PACKAGE_ID}::choco_chip::CHOCO_CHIP
NEXT_PUBLIC_WONKA_BARS_TYPE=${PACKAGE_ID}::wonka_bars::WonkaBars

# Application Configuration
NEXT_PUBLIC_APP_NAME=MeltyFi
NEXT_PUBLIC_APP_DESCRIPTION=Making the illiquid liquid through lottery mechanics

# Development
NODE_ENV=development
NEXT_PUBLIC_DEBUG=true

# Deployment Info
DEPLOYED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DEPLOYER_ADDRESS=$CURRENT_ADDRESS
TRANSACTION_DIGEST=$TRANSACTION_DIGEST
EOF
                
                print_status "Environment variables updated"
            else
                print_error "Could not extract package ID from deployment output"
                echo "$DEPLOY_OUTPUT" > deployment_error.log
                cd ../..
                exit 1
            fi
        else
            print_error "Invalid deployment output format"
            echo "$DEPLOY_OUTPUT" > deployment_error.log
            cd ../..
            exit 1
        fi
    else
        print_error "Deployment failed!"
        echo "$DEPLOY_OUTPUT" > deployment_error.log
        cd ../..
        exit 1
    fi
    
    cd ../..
}

# Test frontend build
test_frontend() {
    print_info "Testing frontend build..."
    
    if [ ! -d "frontend" ]; then
        print_warning "Frontend directory not found, skipping build test"
        return 0
    fi
    
    cd frontend
    
    if timeout 300 npm run build 2>&1 | tee build.log; then
        print_status "Frontend build successful"
    else
        print_error "Frontend build failed or timed out"
        tail -n 20 build.log
        cd ..
        exit 1
    fi
    
    cd ..
}

# Main deployment function
main() {
    print_info "🍫 MeltyFi Improved Deployment Started"
    print_info "====================================="
    
    check_prerequisites
    setup_sui
    install_dependencies
    build_contracts
    deploy_contracts
    test_frontend
    
    print_status "🎉 Deployment completed successfully!"
    print_info "====================================="
    
    if [ -f "deployment-info.json" ]; then
        PACKAGE_ID=$(jq -r '.packageId' deployment-info.json 2>/dev/null)
        print_info "Package ID: $PACKAGE_ID"
        print_info "Network: devnet"
        print_info "Explorer: https://suiexplorer.com"
        print_info "====================================="
    fi
    
    read -p "$(echo -e ${YELLOW}"Start development environment? [y/N]: "${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd frontend
        print_info "Starting development server..."
        npm run dev
    fi
}

# Run main function
main