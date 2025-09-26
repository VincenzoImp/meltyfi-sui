#!/bin/bash

# MeltyFi Deployment Script
# This script handles the complete deployment process for MeltyFi on Sui

set -e  # Exit on any error

echo "🍫 Starting MeltyFi Deployment Process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
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
    
    if ! command -v npm &> /dev/null; then
        print_error "npm not found. Please install npm."
        exit 1
    fi
    
    print_status "All prerequisites installed"
}

# Setup Sui environment
setup_sui() {
    print_info "Setting up Sui environment..."
    
    # Check if wallet exists
    if ! sui client addresses &> /dev/null; then
        print_info "No Sui wallet found. Creating new address..."
        sui client new-address ed25519
    fi
    
    # Switch to devnet
    sui client switch --env devnet
    
    # Get current address
    CURRENT_ADDRESS=$(sui client active-address)
    print_info "Active address: $CURRENT_ADDRESS"
    
    # Check balance
    BALANCE=$(sui client balance --json | jq -r '.[] | select(.coinType == "0x2::sui::SUI") | .totalBalance // "0"')
    print_info "Current SUI balance: $BALANCE MIST"
    
    if [ "$BALANCE" -lt "1000000000" ]; then  # Less than 1 SUI
        print_warning "Low SUI balance. You may need testnet SUI for deployment."
        print_info "Get testnet SUI from: https://discord.gg/sui (use !faucet $CURRENT_ADDRESS in #devnet-faucet)"
    fi
}

# Install dependencies
install_dependencies() {
    print_info "Installing dependencies..."
    
    # Install root dependencies
    if [ -f "package.json" ]; then
        npm install
        print_status "Root dependencies installed"
    fi
    
    # Install frontend dependencies
    if [ -d "frontend" ]; then
        cd frontend
        npm install
        cd ..
        print_status "Frontend dependencies installed"
    fi
}

# Build and test contracts
build_contracts() {
    print_info "Building Move contracts..."
    
    cd contracts/meltyfi
    
    # Build contracts
    sui move build --dev
    print_status "Contracts built successfully"
    
    # Run tests
    print_info "Running contract tests..."
    sui move test
    print_status "All tests passed"
    
    cd ../..
}

# Deploy contracts to devnet
deploy_contracts() {
    print_info "Deploying contracts to devnet..."
    
    cd contracts/meltyfi
    
    # Deploy with higher gas budget
    DEPLOY_OUTPUT=$(sui client publish --gas-budget 100000000 --json)
    
    if [ $? -eq 0 ]; then
        print_status "Contracts deployed successfully!"
        
        # Extract important information from deployment
        PACKAGE_ID=$(echo "$DEPLOY_OUTPUT" | jq -r '.objectChanges[] | select(.type == "published") | .packageId')
        
        print_info "Package ID: $PACKAGE_ID"
        
        # Find created objects
        echo "$DEPLOY_OUTPUT" | jq -r '.objectChanges[] | select(.type == "created") | "Created: \(.objectType) at \(.objectId)"'
        
        # Update environment variables
        cd ../..
        
        # Update .env file
        if [ -f ".env" ]; then
            # Backup original .env
            cp .env .env.backup
            
            # Update package ID
            sed -i.bak "s/^NEXT_PUBLIC_MELTYFI_PACKAGE_ID=.*/NEXT_PUBLIC_MELTYFI_PACKAGE_ID=$PACKAGE_ID/" .env
            
            # Update type definitions
            sed -i.bak "s/^NEXT_PUBLIC_CHOCO_CHIP_TYPE=.*/NEXT_PUBLIC_CHOCO_CHIP_TYPE=${PACKAGE_ID}::choco_chip::CHOCO_CHIP/" .env
            sed -i.bak "s/^NEXT_PUBLIC_WONKA_BARS_TYPE=.*/NEXT_PUBLIC_WONKA_BARS_TYPE=${PACKAGE_ID}::wonka_bars::WonkaBars/" .env
            
            print_status "Environment variables updated"
        else
            print_warning ".env file not found. Creating new one..."
            cat > .env << EOF
# Sui Configuration
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
EOF
            print_status "New .env file created"
        fi
        
        # Save deployment info
        cat > deployment-info.json << EOF
{
  "network": "devnet",
  "packageId": "$PACKAGE_ID",
  "deployedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "deployer": "$(sui client active-address)",
  "transactionDigest": "$(echo "$DEPLOY_OUTPUT" | jq -r '.digest')"
}
EOF
        print_status "Deployment info saved to deployment-info.json"
        
    else
        print_error "Contract deployment failed!"
        exit 1
    fi
    
    cd ../..
}

# Test frontend build
test_frontend() {
    print_info "Testing frontend build..."
    
    cd frontend
    
    # Build frontend
    npm run build
    
    if [ $? -eq 0 ]; then
        print_status "Frontend build successful"
    else
        print_error "Frontend build failed"
        exit 1
    fi
    
    cd ..
}

# Start development environment
start_dev_environment() {
    print_info "Starting development environment..."
    
    # Check if port 3000 is available
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
        print_warning "Port 3000 is in use. Frontend will use an alternative port."
    fi
    
    # Start frontend in background
    cd frontend
    npm run dev &
    FRONTEND_PID=$!
    cd ..
    
    print_status "Development environment started!"
    print_info "Frontend PID: $FRONTEND_PID"
    print_info "Frontend will be available at http://localhost:3000 (or alternative port)"
    
    # Save PIDs for cleanup
    echo $FRONTEND_PID > .dev-pids
}

# Cleanup function
cleanup() {
    print_info "Cleaning up..."
    
    if [ -f ".dev-pids" ]; then
        while read pid; do
            if ps -p $pid > /dev/null 2>&1; then
                kill $pid
                print_info "Stopped process $pid"
            fi
        done < .dev-pids
        rm .dev-pids
    fi
}

# Main deployment function
main() {
    print_info "🍫 MeltyFi Deployment Started"
    print_info "================================"
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Run deployment steps
    check_prerequisites
    setup_sui
    install_dependencies
    build_contracts
    deploy_contracts
    test_frontend
    
    print_status "🎉 Deployment completed successfully!"
    print_info "================================"
    print_info "Package ID: $(grep NEXT_PUBLIC_MELTYFI_PACKAGE_ID .env | cut -d'=' -f2)"
    print_info "Network: devnet"
    print_info "Explorer: https://suiexplorer.com"
    print_info "================================"
    
    # Ask if user wants to start dev environment
    read -p "$(echo -e ${YELLOW}Start development environment? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_dev_environment
        
        print_status "🚀 MeltyFi is now running!"
        print_info "Press Ctrl+C to stop all services"
        
        # Wait for user to stop
        wait
    else
        print_info "To start development environment later, run:"
        print_info "cd frontend && npm run dev"
    fi
}

# Command line argument handling
case "${1:-}" in
    "contracts")
        print_info "Building and deploying contracts only..."
        check_prerequisites
        setup_sui
        build_contracts
        deploy_contracts
        ;;
    "frontend")
        print_info "Building frontend only..."
        install_dependencies
        test_frontend
        ;;
    "dev")
        print_info "Starting development environment only..."
        start_dev_environment
        wait
        ;;
    "clean")
        print_info "Cleaning up development processes..."
        cleanup
        ;;
    "")
        main
        ;;
    *)
        print_info "Usage: $0 [contracts|frontend|dev|clean]"
        print_info "  contracts  - Build and deploy contracts only"
        print_info "  frontend   - Build frontend only"
        print_info "  dev        - Start development environment"
        print_info "  clean      - Clean up running processes"
        print_info "  (no args)  - Full deployment process"
        ;;
esac