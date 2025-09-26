#!/bin/bash

# MeltyFi Fixed Deployment Script
# This script handles the complete deployment process for MeltyFi on Sui with error handling

set -e  # Exit on any error

echo "🍫 Starting MeltyFi Fixed Deployment Process..."

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
    
    # Check Sui version compatibility
    SUI_VERSION=$(sui --version | head -n1 | cut -d' ' -f2)
    print_info "Sui CLI version: $SUI_VERSION"
    
    if ! command -v node &> /dev/null; then
        print_error "Node.js not found. Please install Node.js v18 or later."
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    print_info "Node.js version: $NODE_VERSION"
    
    if ! command -v npm &> /dev/null; then
        print_error "npm not found. Please install npm."
        exit 1
    fi
    
    print_status "All prerequisites installed"
}

# Setup Sui environment with better error handling
setup_sui() {
    print_info "Setting up Sui environment..."
    
    # Check if devnet environment exists, create if not
    if ! sui client envs 2>/dev/null | grep -q "devnet"; then
        print_info "Devnet environment not found. Creating..."
        if ! sui client new-env --alias devnet --rpc https://fullnode.devnet.sui.io:443 2>/dev/null; then
            print_error "Failed to create devnet environment"
            print_info "Please run: sui client new-env --alias devnet --rpc https://fullnode.devnet.sui.io:443"
            exit 1
        fi
    fi
    
    # Switch to devnet
    if ! sui client switch --env devnet 2>/dev/null; then
        print_error "Failed to switch to devnet environment"
        print_info "Available environments:"
        sui client envs 2>/dev/null || echo "None found"
        exit 1
    fi
    
    # Check if wallet exists
    if ! sui client addresses 2>/dev/null | grep -q "0x"; then
        print_info "No Sui addresses found. Creating new address..."
        if ! sui client new-address ed25519 2>/dev/null; then
            print_error "Failed to create new address"
            exit 1
        fi
    fi
    
    # Get current address
    CURRENT_ADDRESS=$(sui client active-address 2>/dev/null || echo "")
    if [ -z "$CURRENT_ADDRESS" ]; then
        print_error "Failed to get active address. Please check your Sui configuration."
        exit 1
    fi
    
    print_info "Active address: $CURRENT_ADDRESS"
    
    # Check balance with better error handling
    BALANCE_OUTPUT=$(sui client balance --json 2>/dev/null || echo '[]')
    BALANCE=$(echo "$BALANCE_OUTPUT" | jq -r '.[] | select(.coinType == "0x2::sui::SUI") | .totalBalance // "0"' 2>/dev/null || echo "0")
    
    print_info "Current SUI balance: $BALANCE MIST ($((BALANCE / 1000000000)) SUI)"
    
    if [ "$BALANCE" -lt "1000000000" ]; then  # Less than 1 SUI
        print_warning "Low SUI balance. You may need testnet SUI for deployment."
        print_info "Get testnet SUI from: https://discord.gg/sui"
        print_info "Use command: !faucet $CURRENT_ADDRESS in #devnet-faucet channel"
        
        read -p "$(echo -e ${YELLOW}Continue with low balance? [y/N]: ${NC})" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Please get more SUI tokens and run the script again."
            exit 0
        fi
    fi
}

# Install dependencies with error handling
install_dependencies() {
    print_info "Installing dependencies..."
    
    # Install root dependencies if package.json exists
    if [ -f "package.json" ]; then
        print_info "Installing root dependencies..."
        npm install --silent || {
            print_error "Failed to install root dependencies"
            exit 1
        }
        print_status "Root dependencies installed"
    fi
    
    # Install frontend dependencies
    if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
        print_info "Installing frontend dependencies..."
        cd frontend
        npm install --silent || {
            print_error "Failed to install frontend dependencies"
            exit 1
        }
        cd ..
        print_status "Frontend dependencies installed"
    fi
}

# Fix Move.toml configuration
fix_move_config() {
    print_info "Checking Move.toml configuration..."
    
    cd contracts/meltyfi
    
    # Backup original Move.toml
    if [ -f "Move.toml" ]; then
        cp Move.toml Move.toml.backup
    fi
    
    # Create proper Move.toml
    cat > Move.toml << 'EOF'
[package]
name = "meltyfi"
edition = "2024.beta"
version = "1.0.0"

[dependencies]
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "framework/devnet" }

[addresses]
meltyfi = "0x0"

[dev-dependencies]

[dev-addresses]
meltyfi = "0x0"
EOF
    
    print_status "Move.toml configuration updated"
    cd ../..
}

# Build and test contracts with better error handling
build_contracts() {
    print_info "Building Move contracts..."
    
    cd contracts/meltyfi
    
    # Clean any previous builds
    rm -rf build/
    
    # Build contracts with proper error handling
    if sui move build --dev 2>&1 | tee build.log; then
        print_status "Contracts built successfully"
    else
        print_error "Contract build failed. Check build.log for details:"
        tail -n 20 build.log
        cd ../..
        exit 1
    fi
    
    # Run tests with better error reporting
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

# Deploy contracts with comprehensive error handling
deploy_contracts() {
    print_info "Deploying contracts to devnet..."
    
    cd contracts/meltyfi
    
    # Get gas budget based on balance
    CURRENT_ADDRESS=$(sui client active-address)
    BALANCE=$(sui client balance --json 2>/dev/null | jq -r '.[] | select(.coinType == "0x2::sui::SUI") | .totalBalance // "0"' 2>/dev/null || echo "0")
    GAS_BUDGET=$((BALANCE / 10))  # Use 10% of balance
    
    if [ "$GAS_BUDGET" -gt 1000000000 ]; then
        GAS_BUDGET=1000000000  # Cap at 1 SUI
    fi
    
    if [ "$GAS_BUDGET" -lt 100000000 ]; then
        GAS_BUDGET=100000000  # Minimum 0.1 SUI
    fi
    
    print_info "Using gas budget: $GAS_BUDGET MIST"
    
    # Deploy with error handling and retries
    DEPLOY_ATTEMPTS=0
    MAX_ATTEMPTS=3
    
    while [ $DEPLOY_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
        print_info "Deployment attempt $((DEPLOY_ATTEMPTS + 1))/$MAX_ATTEMPTS"
        
        if DEPLOY_OUTPUT=$(sui client publish --gas-budget $GAS_BUDGET --json 2>&1); then
            print_status "Contracts deployed successfully!"
            break
        else
            DEPLOY_ATTEMPTS=$((DEPLOY_ATTEMPTS + 1))
            print_warning "Deployment attempt $DEPLOY_ATTEMPTS failed:"
            echo "$DEPLOY_OUTPUT"
            
            if [ $DEPLOY_ATTEMPTS -lt $MAX_ATTEMPTS ]; then
                print_info "Retrying in 5 seconds..."
                sleep 5
            else
                print_error "All deployment attempts failed!"
                echo "$DEPLOY_OUTPUT" > deployment_error.log
                print_info "Error details saved to deployment_error.log"
                cd ../..
                exit 1
            fi
        fi
    done
    
    # Parse deployment output
    if echo "$DEPLOY_OUTPUT" | jq . >/dev/null 2>&1; then
        # Valid JSON output
        PACKAGE_ID=$(echo "$DEPLOY_OUTPUT" | jq -r '.objectChanges[] | select(.type == "published") | .packageId' 2>/dev/null || echo "")
        TRANSACTION_DIGEST=$(echo "$DEPLOY_OUTPUT" | jq -r '.digest' 2>/dev/null || echo "")
        
        if [ -z "$PACKAGE_ID" ]; then
            print_warning "Could not extract package ID from deployment output"
            print_info "Full deployment output:"
            echo "$DEPLOY_OUTPUT"
        else
            print_info "Package ID: $PACKAGE_ID"
            print_info "Transaction: $TRANSACTION_DIGEST"
        fi
        
        # Find created objects
        echo "$DEPLOY_OUTPUT" | jq -r '.objectChanges[] | select(.type == "created") | "Created: \(.objectType) at \(.objectId)"' 2>/dev/null || true
        
    else
        # Non-JSON output, try to parse manually
        print_warning "Non-JSON deployment output received, parsing manually..."
        PACKAGE_ID=$(echo "$DEPLOY_OUTPUT" | grep -o "Published package: 0x[a-fA-F0-9]*" | cut -d' ' -f3 || echo "")
        
        if [ -z "$PACKAGE_ID" ]; then
            print_error "Could not extract package ID from deployment output"
            echo "$DEPLOY_OUTPUT" > deployment_output.log
            print_info "Full output saved to deployment_output.log"
            cd ../..
            exit 1
        fi
        
        print_info "Package ID (parsed): $PACKAGE_ID"
    fi
    
    cd ../..
    
    # Update environment variables
    update_environment_variables "$PACKAGE_ID" "$TRANSACTION_DIGEST"
}

# Update environment variables
update_environment_variables() {
    local PACKAGE_ID="$1"
    local TRANSACTION_DIGEST="$2"
    
    print_info "Updating environment variables..."
    
    # Create or update .env file
    if [ -f ".env" ]; then
        # Backup original .env
        cp .env .env.backup.$(date +%s)
        print_info "Backed up existing .env file"
    fi
    
    # Create new .env file
    cat > .env << EOF
# Sui Network Configuration
NEXT_PUBLIC_SUI_NETWORK=devnet
NEXT_PUBLIC_SUI_RPC_URL=https://fullnode.devnet.sui.io:443

# Contract Addresses
NEXT_PUBLIC_MELTYFI_PACKAGE_ID=$PACKAGE_ID
NEXT_PUBLIC_PROTOCOL_OBJECT_ID=shared_protocol_object_id_here
NEXT_PUBLIC_CHOCOLATE_FACTORY_ID=shared_factory_object_id_here
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
DEPLOYER_ADDRESS=$(sui client active-address 2>/dev/null || echo "unknown")
TRANSACTION_DIGEST=$TRANSACTION_DIGEST
EOF
    
    print_status "Environment variables updated"
    
    # Save deployment info
    cat > deployment-info.json << EOF
{
  "network": "devnet",
  "packageId": "$PACKAGE_ID",
  "deployedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "deployer": "$(sui client active-address 2>/dev/null || echo "unknown")",
  "transactionDigest": "$TRANSACTION_DIGEST",
  "suiExplorerUrl": "https://suiexplorer.com/txblock/$TRANSACTION_DIGEST?network=devnet"
}
EOF
    print_status "Deployment info saved to deployment-info.json"
}

# Test frontend build
test_frontend() {
    print_info "Testing frontend build..."
    
    if [ ! -d "frontend" ]; then
        print_warning "Frontend directory not found, skipping build test"
        return 0
    fi
    
    cd frontend
    
    # Check if all required files exist
    if [ ! -f "package.json" ] || [ ! -f "next.config.js" ]; then
        print_error "Frontend configuration files missing"
        cd ..
        exit 1
    fi
    
    # Build frontend with timeout
    print_info "Building frontend (this may take a few minutes)..."
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

# Start development environment
start_dev_environment() {
    print_info "Starting development environment..."
    
    # Check if port 3000 is available
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Port 3000 is in use. Frontend will use an alternative port."
    fi
    
    # Start frontend in background
    cd frontend
    nohup npm run dev > ../frontend.log 2>&1 &
    FRONTEND_PID=$!
    cd ..
    
    # Give frontend time to start
    sleep 3
    
    # Check if frontend started successfully
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        print_status "Development environment started!"
        print_info "Frontend PID: $FRONTEND_PID"
        
        # Try to detect the actual port
        sleep 2
        PORT=$(lsof -Pi :3000-3010 -sTCP:LISTEN -t 2>/dev/null | head -1 | xargs -I {} lsof -Pi {} -sTCP:LISTEN | grep LISTEN | head -1 | sed 's/.*:\([0-9]*\).*/\1/' || echo "3000")
        print_info "Frontend available at: http://localhost:$PORT"
        
        # Save PIDs for cleanup
        echo $FRONTEND_PID > .dev-pids
    else
        print_error "Failed to start frontend. Check frontend.log for details."
        exit 1
    fi
}

# Cleanup function
cleanup() {
    print_info "Cleaning up..."
    
    if [ -f ".dev-pids" ]; then
        while read -r pid; do
            if [ -n "$pid" ] && ps -p "$pid" > /dev/null 2>&1; then
                kill "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
                print_info "Stopped process $pid"
            fi
        done < .dev-pids
        rm .dev-pids
    fi
    
    # Clean up any remaining node processes
    pkill -f "next dev" 2>/dev/null || true
}

# Validate deployment
validate_deployment() {
    print_info "Validating deployment..."
    
    if [ ! -f "deployment-info.json" ]; then
        print_error "deployment-info.json not found"
        return 1
    fi
    
    PACKAGE_ID=$(jq -r '.packageId' deployment-info.json 2>/dev/null || echo "")
    if [ -z "$PACKAGE_ID" ] || [ "$PACKAGE_ID" = "null" ]; then
        print_error "Invalid package ID in deployment info"
        return 1
    fi
    
    # Verify package exists on chain
    print_info "Verifying package on chain: $PACKAGE_ID"
    if sui client object "$PACKAGE_ID" --json >/dev/null 2>&1; then
        print_status "Package verified on chain"
    else
        print_error "Package not found on chain"
        return 1
    fi
    
    # Check if .env file has correct values
    if [ -f ".env" ]; then
        ENV_PACKAGE_ID=$(grep "NEXT_PUBLIC_MELTYFI_PACKAGE_ID" .env | cut -d'=' -f2)
        if [ "$ENV_PACKAGE_ID" = "$PACKAGE_ID" ]; then
            print_status "Environment variables correctly configured"
        else
            print_warning "Environment variables may be incorrect"
        fi
    fi
    
    return 0
}

# Generate deployment summary
generate_summary() {
    print_info "Generating deployment summary..."
    
    cat > deployment-summary.md << EOF
# MeltyFi Deployment Summary

## Deployment Details
- **Date**: $(date)
- **Network**: devnet
- **Package ID**: \`$(jq -r '.packageId' deployment-info.json 2>/dev/null || echo "N/A")\`
- **Transaction**: \`$(jq -r '.transactionDigest' deployment-info.json 2>/dev/null || echo "N/A")\`
- **Deployer**: \`$(jq -r '.deployer' deployment-info.json 2>/dev/null || echo "N/A")\`

## Explorer Links
- **Package**: [View on Sui Explorer](https://suiexplorer.com/object/$(jq -r '.packageId' deployment-info.json 2>/dev/null || echo "N/A")?network=devnet)
- **Transaction**: [View on Sui Explorer]($(jq -r '.suiExplorerUrl' deployment-info.json 2>/dev/null || echo "N/A"))

## Next Steps
1. Update shared object IDs in .env file after initialization
2. Test the frontend application
3. Create your first lottery
4. Monitor the application logs

## Useful Commands
\`\`\`bash
# Start development server
cd frontend && npm run dev

# Check contract on chain
sui client object $(jq -r '.packageId' deployment-info.json 2>/dev/null || echo "PACKAGE_ID")

# View logs
tail -f frontend.log
\`\`\`

## Support
If you encounter issues, please check:
- Sui CLI is properly configured
- Network connection is stable
- Gas balance is sufficient
- Environment variables are correct
EOF
    
    print_status "Deployment summary saved to deployment-summary.md"
}

# Main deployment function
main() {
    print_info "🍫 MeltyFi Fixed Deployment Started"
    print_info "====================================="
    
    # Set up cleanup trap
    trap cleanup EXIT INT TERM
    
    # Run deployment steps
    check_prerequisites
    setup_sui
    install_dependencies
    fix_move_config
    build_contracts
    deploy_contracts
    test_frontend
    
    # Validate deployment
    if validate_deployment; then
        generate_summary
        print_status "🎉 Deployment completed successfully!"
        print_info "====================================="
        print_info "Package ID: $(jq -r '.packageId' deployment-info.json 2>/dev/null)"
        print_info "Network: devnet"
        print_info "Explorer: https://suiexplorer.com"
        print_info "Summary: deployment-summary.md"
        print_info "====================================="
    else
        print_error "Deployment validation failed"
        exit 1
    fi
    
    # Ask if user wants to start dev environment
    read -p "$(echo -e ${YELLOW}"Start development environment? [y/N]: "${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_dev_environment
        
        print_status "🚀 MeltyFi is now running!"
        print_info "Check deployment-summary.md for links and next steps"
        print_info "Press Ctrl+C to stop all services"
        
        # Wait for user to stop
        while true; do
            if ! ps -p $(cat .dev-pids 2>/dev/null | head -1) > /dev/null 2>&1; then
                print_warning "Frontend process stopped unexpectedly"
                break
            fi
            sleep 5
        done
    else
        print_info "To start development environment later, run:"
        print_info "cd frontend && npm run dev"
    fi
}

# Health check function
health_check() {
    print_info "Running health check..."
    
    # Check Sui connection
    if sui client active-address >/dev/null 2>&1; then
        print_status "Sui client connection OK"
    else
        print_error "Sui client connection failed"
        return 1
    fi
    
    # Check if package exists (if deployed)
    if [ -f "deployment-info.json" ]; then
        validate_deployment
    else
        print_info "No deployment found"
    fi
    
    # Check frontend dependencies
    if [ -d "frontend/node_modules" ]; then
        print_status "Frontend dependencies OK"
    else
        print_warning "Frontend dependencies not installed"
    fi
    
    print_status "Health check completed"
}

# Command line argument handling
case "${1:-}" in
    "contracts")
        print_info "Building and deploying contracts only..."
        check_prerequisites
        setup_sui
        fix_move_config
        build_contracts
        deploy_contracts
        validate_deployment && generate_summary
        ;;
    "frontend")
        print_info "Building frontend only..."
        install_dependencies
        test_frontend
        ;;
    "dev")
        print_info "Starting development environment only..."
        if [ ! -f ".env" ]; then
            print_error "No .env file found. Please deploy contracts first."
            exit 1
        fi
        start_dev_environment
        print_info "Press Ctrl+C to stop all services"
        while true; do
            if ! ps -p $(cat .dev-pids 2>/dev/null | head -1) > /dev/null 2>&1; then
                break
            fi
            sleep 5
        done
        ;;
    "clean")
        print_info "Cleaning up development processes and build files..."
        cleanup
        rm -rf frontend/.next frontend/build contracts/meltyfi/build
        rm -f frontend.log *.log
        print_status "Cleanup completed"
        ;;
    "health")
        health_check
        ;;
    "help"|"-h"|"--help")
        print_info "MeltyFi Deployment Script Usage:"
        print_info "  $0                - Full deployment process"
        print_info "  $0 contracts      - Build and deploy contracts only"
        print_info "  $0 frontend       - Build frontend only"
        print_info "  $0 dev            - Start development environment"
        print_info "  $0 clean          - Clean up processes and build files"
        print_info "  $0 health         - Run health check"
        print_info "  $0 help           - Show this help message"
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown command: $1"
        print_info "Use '$0 help' for usage information"
        exit 1
        ;;
esac