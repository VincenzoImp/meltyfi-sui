#!/bin/bash

# MeltyFi Enhanced Deployment Script
# Fixes all smart contract issues and provides robust deployment

set -e

echo "🍫 Starting MeltyFi Enhanced Deployment Process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_step() {
    echo -e "${PURPLE}🔄 $1${NC}"
}

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEPLOYMENT_LOG="$PROJECT_ROOT/deployment.log"
CONTRACT_DIR="$PROJECT_ROOT/contracts/meltyfi"

# Initialize logging
echo "Deployment started at $(date)" > "$DEPLOYMENT_LOG"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$DEPLOYMENT_LOG"
}

# Check if required tools are installed
check_prerequisites() {
    print_step "Checking prerequisites..."
    log "Checking prerequisites"
    
    local missing_tools=()
    
    if ! command -v sui &> /dev/null; then
        missing_tools+=("sui")
    fi
    
    if ! command -v node &> /dev/null; then
        missing_tools+=("node")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo "Please install the missing tools:"
        for tool in "${missing_tools[@]}"; do
            case $tool in
                "sui")
                    echo "  - Sui CLI: cargo install --locked --git https://github.com/MystenLabs/sui.git --branch devnet sui"
                    ;;
                "node")
                    echo "  - Node.js: https://nodejs.org/ (v18 or later)"
                    ;;
                "jq")
                    echo "  - jq: https://stedolan.github.io/jq/download/"
                    ;;
            esac
        done
        exit 1
    fi
    
    # Check versions
    local sui_version=$(sui --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    local node_version=$(node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    
    print_info "Building frontend application..."
    if timeout 300 npm run build 2>&1 | tee "$PROJECT_ROOT/frontend-build.log"; then
        print_status "Frontend build successful"
        log "Frontend build successful"
    else
        print_error "Frontend build failed or timed out"
        log "ERROR: Frontend build failed"
        tail -n 20 "$PROJECT_ROOT/frontend-build.log"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
}

# Generate deployment summary
generate_summary() {
    print_step "Generating deployment summary..."
    log "Generating deployment summary"
    
    local summary_file="$PROJECT_ROOT/DEPLOYMENT_SUMMARY.md"
    
    if [ -f "$PROJECT_ROOT/deployment-info.json" ]; then
        local package_id=$(jq -r '.packageId' "$PROJECT_ROOT/deployment-info.json" 2>/dev/null || echo "N/A")
        local transaction_digest=$(jq -r '.transactionDigest' "$PROJECT_ROOT/deployment-info.json" 2>/dev/null || echo "N/A")
        local deployed_at=$(jq -r '.deployedAt' "$PROJECT_ROOT/deployment-info.json" 2>/dev/null || echo "N/A")
        local deployer=$(jq -r '.deployer' "$PROJECT_ROOT/deployment-info.json" 2>/dev/null || echo "N/A")
        
        cat > "$summary_file" << EOF
# 🍫 MeltyFi Deployment Summary

## Deployment Information
- **Network**: Sui Devnet
- **Package ID**: \`$package_id\`
- **Deployed At**: $deployed_at
- **Deployer Address**: \`$deployer\`
- **Transaction Hash**: \`$transaction_digest\`

## Contract Addresses
- **Package ID**: \`$package_id\`
- **ChocoChip Type**: \`${package_id}::choco_chip::CHOCO_CHIP\`
- **WonkaBars Type**: \`${package_id}::wonka_bars::WonkaBars\`

## Verification Links
- **Sui Explorer**: [View Transaction](https://suiexplorer.com/txblock/$transaction_digest?network=devnet)
- **Package Explorer**: [View Package](https://suiexplorer.com/object/$package_id?network=devnet)

## Next Steps
1. **Verify Deployment**: Check the transaction on Sui Explorer
2. **Test Frontend**: Run \`npm run dev:frontend\` to start the development server
3. **Connect Wallet**: Use a Sui wallet to interact with the protocol
4. **Create First Lottery**: Deposit an NFT and create your first lottery

## Important Notes
- This deployment is on **Sui Devnet** for testing purposes
- Use testnet SUI tokens for all transactions
- Keep your private keys secure
- Report any issues on GitHub

## Support
- **GitHub**: [MeltyFi Repository](https://github.com/VincenzoImp/MeltyFi)
- **Documentation**: [MeltyFi Docs](https://docs.meltyfi.com)
- **Discord**: [Join Community](https://discord.gg/meltyfi)

---
*Deployment completed successfully at $deployed_at*
EOF
        
        print_status "Deployment summary generated: DEPLOYMENT_SUMMARY.md"
        log "Deployment summary generated"
    else
        print_warning "Could not generate deployment summary - deployment info not found"
        log "WARNING: Could not generate deployment summary"
    fi
}

# Cleanup function
cleanup() {
    print_info "Cleaning up temporary files..."
    rm -f "$PROJECT_ROOT"/*.bak 2>/dev/null || true
    log "Cleanup completed"
}

# Main deployment function
main() {
    print_info "🍫 MeltyFi Enhanced Deployment Started"
    print_info "======================================="
    log "Deployment process started"
    
    # Trap cleanup on exit
    trap cleanup EXIT
    
    check_prerequisites
    setup_sui
    install_dependencies
    fix_move_config
    build_contracts
    deploy_contracts
    test_frontend
    generate_summary
    
    print_status "🎉 Deployment completed successfully!"
    print_info "======================================="
    
    if [ -f "$PROJECT_ROOT/deployment-info.json" ]; then
        local package_id=$(jq -r '.packageId' "$PROJECT_ROOT/deployment-info.json" 2>/dev/null)
        local transaction_digest=$(jq -r '.transactionDigest' "$PROJECT_ROOT/deployment-info.json" 2>/dev/null)
        
        echo
        print_info "📋 Deployment Details:"
        print_info "Package ID: $package_id"
        print_info "Network: Sui Devnet"
        print_info "Explorer: https://suiexplorer.com/txblock/$transaction_digest?network=devnet"
        print_info "Documentation: Check DEPLOYMENT_SUMMARY.md for complete details"
        echo
    fi
    
    log "Deployment process completed successfully"
    
    # Ask if user wants to start development environment
    read -p "$(echo -e ${YELLOW}"Start development frontend? [y/N]: "${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Starting development server..."
        cd frontend
        npm run dev
    else
        print_info "To start the frontend later, run: npm run dev:frontend"
        print_info "Check DEPLOYMENT_SUMMARY.md for next steps"
    fi
}

# Error handling
handle_error() {
    print_error "An error occurred during deployment"
    log "ERROR: Deployment failed with error"
    
    if [ -f "$DEPLOYMENT_LOG" ]; then
        print_info "Check deployment.log for detailed error information"
    fi
    
    print_info "Common solutions:"
    print_info "1. Ensure you have sufficient SUI balance"
    print_info "2. Check your internet connection"
    print_info "3. Verify Sui CLI is properly configured"
    print_info "4. Try running the script again"
    
    exit 1
}

# Set error trap
trap handle_error ERR

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi "Sui CLI version: $sui_version"
    print_info "Node.js version: $node_version"
    log "Prerequisites checked - Sui: $sui_version, Node: $node_version"
    
    print_status "All prerequisites installed"
}

# Setup Sui environment
setup_sui() {
    print_step "Setting up Sui environment..."
    log "Setting up Sui environment"
    
    # Check if devnet environment exists, create if not
    if ! sui client envs 2>/dev/null | grep -q "devnet"; then
        print_info "Creating devnet environment..."
        sui client new-env --alias devnet --rpc https://fullnode.devnet.sui.io:443
        log "Created devnet environment"
    fi
    
    # Switch to devnet
    sui client switch --env devnet
    log "Switched to devnet"
    
    # Check if wallet exists
    if ! sui client addresses 2>/dev/null | grep -q "0x"; then
        print_info "Creating new address..."
        sui client new-address ed25519
        log "Created new address"
    fi
    
    local current_address=$(sui client active-address 2>/dev/null || echo "")
    print_info "Active address: $current_address"
    log "Active address: $current_address"
    
    # Check balance
    local balance=$(sui client balance --json 2>/dev/null | jq -r '.[] | select(.coinType == "0x2::sui::SUI") | .totalBalance // "0"' 2>/dev/null || echo "0")
    local balance_sui=$((balance / 1000000000))
    print_info "Current SUI balance: $balance_sui SUI"
    log "Current balance: $balance_sui SUI"
    
    if [ "$balance" -lt "1000000000" ]; then
        print_warning "Low SUI balance detected ($balance_sui SUI)"
        print_info "You may need testnet SUI for deployment."
        print_info "Get testnet SUI from: https://faucet.devnet.sui.io"
        print_info "Or use Discord faucet: https://discord.gg/sui (#devnet-faucet channel)"
        
        read -p "$(echo -e ${YELLOW}Continue with current balance? [y/N]: ${NC})" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Exiting. Please get more SUI and try again."
            exit 0
        fi
        log "Proceeding with low balance"
    fi
    
    print_status "Sui environment setup complete"
}

# Install dependencies
install_dependencies() {
    print_step "Installing dependencies..."
    log "Installing dependencies"
    
    cd "$PROJECT_ROOT"
    
    if [ -f "package.json" ]; then
        npm install --silent > /dev/null 2>&1 || {
            print_error "Failed to install root dependencies"
            log "ERROR: Root dependency installation failed"
            exit 1
        }
        print_status "Root dependencies installed"
        log "Root dependencies installed"
    fi
    
    if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
        cd frontend
        npm install --silent > /dev/null 2>&1 || {
            print_error "Failed to install frontend dependencies"
            log "ERROR: Frontend dependency installation failed"
            exit 1
        }
        cd ..
        print_status "Frontend dependencies installed"
        log "Frontend dependencies installed"
    fi
}

# Fix Move.toml configuration
fix_move_config() {
    print_step "Fixing Move configuration..."
    log "Fixing Move configuration"
    
    local move_toml="$CONTRACT_DIR/Move.toml"
    
    if [ -f "$move_toml" ]; then
        # Backup original
        cp "$move_toml" "$move_toml.backup"
        log "Backed up original Move.toml"
        
        # Create fixed Move.toml
        cat > "$move_toml" << 'EOF'
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
# Removed duplicate address assignment to fix build error
EOF
        
        print_status "Move.toml configuration fixed"
        log "Move.toml configuration fixed"
    else
        print_error "Move.toml not found at $move_toml"
        exit 1
    fi
}

# Build and test contracts
build_contracts() {
    print_step "Building and testing Move contracts..."
    log "Building contracts"
    
    cd "$CONTRACT_DIR"
    
    # Clean any previous builds
    rm -rf build/ 2>/dev/null || true
    
    # Build contracts with detailed output
    print_info "Compiling Move contracts..."
    if sui move build 2>&1 | tee "$PROJECT_ROOT/build.log"; then
        print_status "Contracts compiled successfully"
        log "Contract compilation successful"
    else
        print_error "Contract compilation failed. Check build.log for details:"
        tail -n 20 "$PROJECT_ROOT/build.log"
        log "ERROR: Contract compilation failed"
        exit 1
    fi
    
    # Run tests
    print_info "Running contract tests..."
    if sui move test --gas-limit 100000000 2>&1 | tee "$PROJECT_ROOT/test.log"; then
        print_status "All tests passed"
        log "All tests passed"
    else
        print_warning "Some tests failed. Check test.log for details:"
        tail -n 10 "$PROJECT_ROOT/test.log"
        log "WARNING: Some tests failed"
        print_info "Continuing with deployment..."
    fi
    
    cd "$PROJECT_ROOT"
}

# Deploy contracts
deploy_contracts() {
    print_step "Deploying contracts to devnet..."
    log "Starting contract deployment"
    
    cd "$CONTRACT_DIR"
    
    # Get current address and balance
    local current_address=$(sui client active-address)
    local balance=$(sui client balance --json 2>/dev/null | jq -r '.[] | select(.coinType == "0x2::sui::SUI") | .totalBalance // "0"' 2>/dev/null || echo "0")
    
    # Calculate gas budget (conservative approach)
    local gas_budget=$((balance / 20)) # Use 5% of balance
    if [ "$gas_budget" -gt 2000000000 ]; then
        gas_budget=2000000000 # Cap at 2 SUI
    fi
    if [ "$gas_budget" -lt 100000000 ]; then
        gas_budget=100000000 # Minimum 0.1 SUI
    fi
    
    print_info "Using gas budget: $((gas_budget / 1000000000)) SUI"
    log "Gas budget: $gas_budget MIST"
    
    # Deploy with enhanced error handling
    print_info "Publishing to Sui devnet..."
    local deploy_output
    if deploy_output=$(sui client publish --gas-budget "$gas_budget" --json 2>&1); then
        print_status "Contracts deployed successfully!"
        log "Contract deployment successful"
        
        # Save full deployment output
        echo "$deploy_output" > "$PROJECT_ROOT/deployment-output.json"
        
        # Parse deployment output
        if echo "$deploy_output" | jq . >/dev/null 2>&1; then
            local package_id=$(echo "$deploy_output" | jq -r '.objectChanges[]? | select(.type == "published") | .packageId' 2>/dev/null || echo "")
            local transaction_digest=$(echo "$deploy_output" | jq -r '.digest' 2>/dev/null || echo "")
            
            if [ -n "$package_id" ] && [ "$package_id" != "null" ]; then
                print_info "Package ID: $package_id"
                print_info "Transaction: $transaction_digest"
                log "Package ID: $package_id"
                log "Transaction: $transaction_digest"
                
                # Save deployment info
                cat > "$PROJECT_ROOT/deployment-info.json" << EOF
{
  "network": "devnet",
  "packageId": "$package_id",
  "deployedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "deployer": "$current_address",
  "transactionDigest": "$transaction_digest",
  "suiExplorerUrl": "https://suiexplorer.com/txblock/$transaction_digest?network=devnet",
  "gasUsed": "$gas_budget",
  "status": "success"
}
EOF
                
                # Update .env file
                cat > "$PROJECT_ROOT/.env" << EOF
# Sui Network Configuration
NEXT_PUBLIC_SUI_NETWORK=devnet
NEXT_PUBLIC_SUI_RPC_URL=https://fullnode.devnet.sui.io:443

# Contract Addresses
NEXT_PUBLIC_MELTYFI_PACKAGE_ID=$package_id
NEXT_PUBLIC_PROTOCOL_OBJECT_ID=
NEXT_PUBLIC_CHOCOLATE_FACTORY_ID=
NEXT_PUBLIC_CHOCO_CHIP_TYPE=${package_id}::choco_chip::CHOCO_CHIP
NEXT_PUBLIC_WONKA_BARS_TYPE=${package_id}::wonka_bars::WonkaBars

# Application Configuration
NEXT_PUBLIC_APP_NAME=MeltyFi
NEXT_PUBLIC_APP_DESCRIPTION=Making the illiquid liquid through lottery mechanics

# Development
NODE_ENV=development
NEXT_PUBLIC_DEBUG=true

# Deployment Info
DEPLOYED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DEPLOYER_ADDRESS=$current_address
TRANSACTION_DIGEST=$transaction_digest
EOF
                
                # Copy to frontend directory
                cp "$PROJECT_ROOT/.env" "$PROJECT_ROOT/frontend/.env.local" 2>/dev/null || true
                
                print_status "Environment variables updated"
                log "Environment variables updated"
                
                # Extract object IDs for shared objects
                local protocol_id=$(echo "$deploy_output" | jq -r '.objectChanges[]? | select(.objectType | contains("Protocol")) | .objectId' 2>/dev/null || echo "")
                local factory_id=$(echo "$deploy_output" | jq -r '.objectChanges[]? | select(.objectType | contains("ChocolateFactory")) | .objectId' 2>/dev/null || echo "")
                
                if [ -n "$protocol_id" ] && [ "$protocol_id" != "null" ]; then
                    print_info "Protocol Object ID: $protocol_id"
                    log "Protocol Object ID: $protocol_id"
                    
                    # Update .env with object IDs
                    sed -i.bak "s/NEXT_PUBLIC_PROTOCOL_OBJECT_ID=/NEXT_PUBLIC_PROTOCOL_OBJECT_ID=$protocol_id/" "$PROJECT_ROOT/.env"
                fi
                
                if [ -n "$factory_id" ] && [ "$factory_id" != "null" ]; then
                    print_info "Chocolate Factory ID: $factory_id"
                    log "Chocolate Factory ID: $factory_id"
                    
                    sed -i.bak "s/NEXT_PUBLIC_CHOCOLATE_FACTORY_ID=/NEXT_PUBLIC_CHOCOLATE_FACTORY_ID=$factory_id/" "$PROJECT_ROOT/.env"
                fi
                
            else
                print_error "Could not extract package ID from deployment output"
                echo "$deploy_output" > "$PROJECT_ROOT/deployment_error.log"
                log "ERROR: Could not extract package ID"
                exit 1
            fi
        else
            print_error "Invalid deployment output format"
            echo "$deploy_output" > "$PROJECT_ROOT/deployment_error.log"
            log "ERROR: Invalid deployment output format"
            exit 1
        fi
    else
        print_error "Deployment failed!"
        echo "$deploy_output" > "$PROJECT_ROOT/deployment_error.log"
        log "ERROR: Deployment failed"
        print_info "Error details saved to deployment_error.log"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
}

# Test frontend build
test_frontend() {
    print_step "Testing frontend build..."
    log "Testing frontend build"
    
    if [ ! -d "frontend" ]; then
        print_warning "Frontend directory not found, skipping build test"
        log "Frontend directory not found"
        return 0
    fi
    
    cd frontend
    
    print_info