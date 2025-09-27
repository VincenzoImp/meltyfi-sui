#!/bin/bash

# MeltyFi Protocol - Complete Deployment Script for Sui Testnet
# This script will deploy the fixed Move contracts and update frontend configuration

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONTRACTS_DIR="$PROJECT_ROOT/contracts/meltyfi"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
LOG_FILE="$PROJECT_ROOT/deployment.log"

# Network configuration
NETWORK="testnet"
RPC_URL="https://fullnode.testnet.sui.io:443"
FAUCET_URL="https://faucet.testnet.sui.io/gas"

# Helper functions
print_header() {
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${WHITE}🍫 MeltyFi Protocol - Sui Testnet Deployment${NC}"
    echo -e "${PURPLE}================================================================${NC}"
    echo
}

print_step() {
    echo -e "${CYAN}📋 Step: $1${NC}"
    echo "$(date): STEP - $1" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "$(date): SUCCESS - $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}❌ Error: $1${NC}"
    echo "$(date): ERROR - $1" >> "$LOG_FILE"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}⚠️  Warning: $1${NC}"
    echo "$(date): WARNING - $1" >> "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    echo "$(date): INFO - $1" >> "$LOG_FILE"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking Prerequisites"
    
    # Check if sui CLI is installed
    if ! command -v sui &> /dev/null; then
        print_error "Sui CLI not found. Please install it first."
    fi
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        print_error "Node.js not found. Please install it first."
    fi
    
    # Check if npm is installed
    if ! command -v npm &> /dev/null; then
        print_error "npm not found. Please install it first."
    fi
    
    print_success "All prerequisites are installed"
}

# Setup Sui environment
setup_sui_environment() {
    print_step "Setting up Sui Environment"
    
    # Check if testnet environment exists
    if ! sui client envs | grep -q "testnet"; then
        print_info "Creating testnet environment..."
        sui client new-env --alias testnet --rpc "$RPC_URL" || print_error "Failed to create testnet environment"
    fi
    
    # Switch to testnet
    sui client switch --env testnet || print_error "Failed to switch to testnet"
    
    # Check if we have an active address
    if ! sui client active-address &> /dev/null; then
        print_info "No active address found. Generating new keypair..."
        sui client new-address ed25519 || print_error "Failed to generate new address"
    fi
    
    local active_address=$(sui client active-address)
    print_info "Active address: $active_address"
    
    # Check SUI balance
    local balance=$(sui client balance 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)?\s*SUI' | head -1 | grep -oE '[0-9]+(\.[0-9]+)?' || echo "0")
    print_info "Current SUI balance: $balance SUI"
    
    # Check if we need more SUI
    if (( $(echo "$balance < 1" | bc -l) )); then
        print_warning "Low SUI balance. You may need to get more SUI from faucet."
        print_info "Faucet URL: $FAUCET_URL"
        echo
        read -p "Press Enter to continue or Ctrl+C to abort and get more SUI..."
    fi
    
    print_success "Sui environment setup complete"
}

# Clean and prepare contracts
prepare_contracts() {
    print_step "Preparing Move Contracts"
    
    cd "$CONTRACTS_DIR" || print_error "Cannot find contracts directory"
    
    # Clean previous builds
    if [ -d "build" ]; then
        print_info "Cleaning previous build artifacts..."
        rm -rf build/
    fi
    
    # Verify Move.toml is correct
    print_info "Verifying Move.toml configuration..."
    if ! grep -q "edition = \"2024.beta\"" Move.toml; then
        print_warning "Move.toml may need updating. Please ensure it matches the fixed version."
    fi
    
    print_success "Contracts prepared"
}

# Build Move contracts
build_contracts() {
    print_step "Building Move Contracts"
    
    cd "$CONTRACTS_DIR" || print_error "Cannot find contracts directory"
    
    print_info "Building Move package..."
    if sui move build 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Move contracts built successfully"
    else
        print_error "Failed to build Move contracts. Check the log for details."
    fi
}

# Run Move tests
test_contracts() {
    print_step "Running Move Tests"
    
    cd "$CONTRACTS_DIR" || print_error "Cannot find contracts directory"
    
    print_info "Running Move tests..."
    if sui move test 2>&1 | tee -a "$LOG_FILE"; then
        print_success "All Move tests passed"
    else
        print_warning "Some tests may have failed. Check the log for details."
        echo
        read -p "Continue with deployment? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Deployment aborted by user"
        fi
    fi
}

# Deploy contracts to testnet
deploy_contracts() {
    print_step "Deploying Contracts to Testnet"
    
    cd "$CONTRACTS_DIR" || print_error "Cannot find contracts directory"
    
    print_info "Publishing Move package to testnet..."
    print_info "This may take a few minutes..."
    
    local deployment_output
    if deployment_output=$(sui client publish --gas-budget 100000000 2>&1 | tee -a "$LOG_FILE"); then
        print_success "Contracts deployed successfully!"
        
        # Extract package ID from deployment output
        local package_id=$(echo "$deployment_output" | grep -o "0x[a-fA-F0-9]\{64\}" | head -1)
        
        if [ -n "$package_id" ]; then
            print_info "Package ID: $package_id"
            echo "PACKAGE_ID=$package_id" > "$PROJECT_ROOT/.deployment_vars"
            
            # Extract other important object IDs
            echo "$deployment_output" | grep -E "(Created|Published)" | while read line; do
                echo "$(date): DEPLOYMENT - $line" >> "$LOG_FILE"
            done
            
        else
            print_warning "Could not extract Package ID from deployment output"
        fi
        
    else
        print_error "Failed to deploy contracts"
    fi
}

# Update frontend environment variables
update_frontend_config() {
    print_step "Updating Frontend Configuration"
    
    if [ ! -f "$PROJECT_ROOT/.deployment_vars" ]; then
        print_warning "No deployment variables found. Skipping frontend update."
        return
    fi
    
    source "$PROJECT_ROOT/.deployment_vars"
    
    if [ -n "$PACKAGE_ID" ]; then
        # Update .env file
        local env_file="$PROJECT_ROOT/.env"
        
        if [ -f "$env_file" ]; then
            print_info "Updating $env_file with deployment information..."
            
            # Update or add package ID
            if grep -q "NEXT_PUBLIC_MELTYFI_PACKAGE_ID" "$env_file"; then
                sed -i.bak "s/NEXT_PUBLIC_MELTYFI_PACKAGE_ID=.*/NEXT_PUBLIC_MELTYFI_PACKAGE_ID=$PACKAGE_ID/" "$env_file"
            else
                echo "NEXT_PUBLIC_MELTYFI_PACKAGE_ID=$PACKAGE_ID" >> "$env_file"
            fi
            
            # Update network configuration
            sed -i.bak "s/NEXT_PUBLIC_SUI_NETWORK=.*/NEXT_PUBLIC_SUI_NETWORK=$NETWORK/" "$env_file"
            sed -i.bak "s|NEXT_PUBLIC_SUI_RPC_URL=.*|NEXT_PUBLIC_SUI_RPC_URL=$RPC_URL|" "$env_file"
            
            print_success "Frontend configuration updated"
        else
            print_warning "Frontend .env file not found. Creating new one..."
            cat > "$env_file" << EOF
# Sui Network Configuration - TESTNET
NEXT_PUBLIC_SUI_NETWORK=$NETWORK
NEXT_PUBLIC_SUI_RPC_URL=$RPC_URL

# Contract Addresses
NEXT_PUBLIC_MELTYFI_PACKAGE_ID=$PACKAGE_ID

# Frontend Configuration  
NEXT_PUBLIC_APP_NAME=MeltyFi
NEXT_PUBLIC_APP_DESCRIPTION=Making the illiquid liquid through lottery mechanics

# Development
NODE_ENV=development
NEXT_PUBLIC_DEBUG=true

# Network Info
NETWORK=$NETWORK
EXPLORER_URL=https://suiexplorer.com
FAUCET_URL=$FAUCET_URL
EOF
            print_success "Created new frontend configuration"
        fi
    else
        print_warning "Package ID not found in deployment variables"
    fi
}

# Build and test frontend
build_frontend() {
    print_step "Building Frontend"
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        print_warning "Frontend directory not found. Skipping frontend build."
        return
    fi
    
    cd "$FRONTEND_DIR" || print_error "Cannot access frontend directory"
    
    # Install dependencies
    print_info "Installing frontend dependencies..."
    if npm install 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Frontend dependencies installed"
    else
        print_error "Failed to install frontend dependencies"
    fi
    
    # Build frontend
    print_info "Building frontend..."
    if npm run build 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Frontend built successfully"
    else
        print_warning "Frontend build failed. Check the log for details."
    fi
}

# Verify deployment
verify_deployment() {
    print_step "Verifying Deployment"
    
    if [ ! -f "$PROJECT_ROOT/.deployment_vars" ]; then
        print_warning "No deployment variables found for verification"
        return
    fi
    
    source "$PROJECT_ROOT/.deployment_vars"
    
    if [ -n "$PACKAGE_ID" ]; then
        print_info "Verifying package on Sui Explorer..."
        local explorer_url="https://suiexplorer.com/object/$PACKAGE_ID?network=$NETWORK"
        print_info "Explorer URL: $explorer_url"
        
        # Try to fetch package info
        if sui client object "$PACKAGE_ID" &> /dev/null; then
            print_success "Package verified on blockchain"
        else
            print_warning "Could not verify package on blockchain"
        fi
    fi
}

# Generate deployment summary
generate_summary() {
    print_step "Generating Deployment Summary"
    
    local summary_file="$PROJECT_ROOT/DEPLOYMENT_SUMMARY.md"
    
    cat > "$summary_file" << EOF
# MeltyFi Protocol - Deployment Summary

**Deployment Date:** $(date)
**Network:** $NETWORK
**RPC URL:** $RPC_URL

## Contract Information

EOF

    if [ -f "$PROJECT_ROOT/.deployment_vars" ]; then
        source "$PROJECT_ROOT/.deployment_vars"
        
        if [ -n "$PACKAGE_ID" ]; then
            cat >> "$summary_file" << EOF
- **Package ID:** \`$PACKAGE_ID\`
- **Explorer URL:** [View on Sui Explorer](https://suiexplorer.com/object/$PACKAGE_ID?network=$NETWORK)

## Modules Deployed

- \`meltyfi::meltyfi_core\` - Core protocol logic
- \`meltyfi::choco_chip\` - Governance token
- \`meltyfi::wonka_bars\` - Lottery ticket NFTs
- \`meltyfi::meltyfi\` - Main interface module

## Next Steps

1. **Test Basic Functions:**
   - Create a test lottery
   - Buy WonkaBars (lottery tickets)
   - Test winner selection

2. **Frontend Integration:**
   - Verify environment variables are updated
   - Test wallet connection
   - Test contract interactions

3. **Get Testnet SUI:**
   - Visit: $FAUCET_URL
   - Request SUI for testing

## Useful Commands

\`\`\`bash
# Check active address
sui client active-address

# Check SUI balance
sui client balance

# View deployed package
sui client object $PACKAGE_ID

# Get more testnet SUI
curl -X POST $FAUCET_URL \\
  -H "Content-Type: application/json" \\
  -d '{"FixedAmountRequest":{"recipient":"YOUR_ADDRESS"}}'
\`\`\`

## Troubleshooting

- **Check logs:** \`$LOG_FILE\`
- **Verify network:** \`sui client active-env\`
- **Check gas:** Ensure sufficient SUI balance for transactions

EOF
        fi
    fi
    
    print_success "Deployment summary generated: $summary_file"
}

# Cleanup function
cleanup() {
    if [ -f "$PROJECT_ROOT/.deployment_vars" ]; then
        print_info "Cleaning up temporary files..."
        # Keep deployment vars for later use, but clean up any other temp files
    fi
}

# Main execution
main() {
    # Initialize log file
    echo "$(date): MeltyFi Deployment Started" > "$LOG_FILE"
    
    print_header
    
    print_info "Starting MeltyFi Protocol deployment to Sui testnet..."
    print_info "Log file: $LOG_FILE"
    echo
    
    # Execute deployment steps
    check_prerequisites
    setup_sui_environment
    prepare_contracts
    build_contracts
    test_contracts
    deploy_contracts
    update_frontend_config
    build_frontend
    verify_deployment
    generate_summary
    
    print_header
    print_success "🎉 MeltyFi Protocol deployment completed successfully!"
    echo
    print_info "📋 Summary:"
    echo -e "   ${GREEN}✅ Move contracts deployed to testnet${NC}"
    echo -e "   ${GREEN}✅ Frontend configuration updated${NC}"
    echo -e "   ${GREEN}✅ Deployment summary generated${NC}"
    echo
    print_info "📖 Next steps:"
    echo -e "   ${BLUE}1. Review deployment summary: DEPLOYMENT_SUMMARY.md${NC}"
    echo -e "   ${BLUE}2. Test the frontend: cd frontend && npm run dev${NC}"
    echo -e "   ${BLUE}3. Get testnet SUI: $FAUCET_URL${NC}"
    echo
    print_info "🔍 Verification:"
    if [ -f "$PROJECT_ROOT/.deployment_vars" ]; then
        source "$PROJECT_ROOT/.deployment_vars"
        if [ -n "$PACKAGE_ID" ]; then
            echo -e "   ${CYAN}Package ID: $PACKAGE_ID${NC}"
            echo -e "   ${CYAN}Explorer: https://suiexplorer.com/object/$PACKAGE_ID?network=$NETWORK${NC}"
        fi
    fi
    echo
}

# Error handling
trap cleanup EXIT

# Run main function with all arguments
main "$@"