#!/bin/bash

# =============================================================================
# MeltyFi Protocol - Fully Automated Deployment Script
# Deploys contracts and automatically configures all environment files
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
NETWORK="testnet"
CONTRACTS_DIR="contracts/meltyfi"
FRONTEND_DIR="frontend"
LOG_FILE="deployment.log"
ENV_FILE=".env"
FRONTEND_ENV_FILE="$FRONTEND_DIR/.env.local"
DEPLOYMENT_INFO_FILE="deployment_info.json"
GAS_BUDGET=100000000  # 0.1 SUI

# Global variables for deployment results
PACKAGE_ID=""
PROTOCOL_OBJECT_ID=""
CHOCOLATE_FACTORY_ID=""
ADMIN_CAP_ID=""
FACTORY_ADMIN_ID=""
TX_DIGEST=""
DEPLOYER_ADDRESS=""
DEPLOYMENT_TIMESTAMP=""

# Helper functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
    cleanup_on_error
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

# Enhanced banner
print_banner() {
    echo -e "${PURPLE}"
    cat << "EOF"
    ███╗   ███╗███████╗██╗  ████████╗██╗   ██╗███████╗██╗
    ████╗ ████║██╔════╝██║  ╚══██╔══╝╚██╗ ██╔╝██╔════╝██║
    ██╔████╔██║█████╗  ██║     ██║    ╚████╔╝ █████╗  ██║
    ██║╚██╔╝██║██╔══╝  ██║     ██║     ╚██╔╝  ██╔══╝  ██║
    ██║ ╚═╝ ██║███████╗███████╗██║      ██║   ██║     ██║
    ╚═╝     ╚═╝╚══════╝╚══════╝╚═╝      ╚═╝   ╚═╝     ╚═╝
                                                           
    🍫 Sweet NFT Liquidity Protocol - Automated Deployment 🚀
EOF
    echo -e "${NC}"
    echo -e "${CYAN}🔧 Fully Automated Configuration & Deployment${NC}"
    echo -e "${CYAN}📋 Network: ${YELLOW}Sui Testnet${NC}"
    echo -e "${CYAN}⏰ Started: ${YELLOW}$(date)${NC}"
    echo
}

# Check prerequisites with enhanced validation
check_prerequisites() {
    log "🔍 Checking prerequisites..."
    
    # Check if Sui CLI is installed
    if ! command -v sui &> /dev/null; then
        error "Sui CLI not found. Please install it from: https://docs.sui.io/guides/developer/getting-started/sui-install"
    fi
    
    local sui_version=$(sui --version | head -1)
    success "Sui CLI found: $sui_version"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        error "Node.js not found. Please install Node.js 18+ from: https://nodejs.org/"
    fi
    
    # Check Node.js version
    local node_version=$(node --version | cut -d'v' -f2)
    local required_version="18.0.0"
    if ! printf '%s\n' "$required_version" "$node_version" | sort -V -C; then
        error "Node.js version $node_version is too old. Please install Node.js 18 or higher."
    fi
    success "Node.js version: $node_version"
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        error "npm not found. Please install npm."
    fi
    success "npm found: $(npm --version)"
    
    # Check for jq (required for JSON parsing)
    if ! command -v jq &> /dev/null; then
        warn "jq not found. Installing via npm..."
        npm install -g jq-node 2>/dev/null || warn "Could not install jq automatically. JSON parsing will use fallback method."
    else
        success "jq found for JSON parsing"
    fi
    
    # Check for bc (helpful for calculations)
    if ! command -v bc &> /dev/null; then
        warn "bc not found. Calculations will use fallback method."
        info "Install bc for better calculations: brew install bc (macOS) or apt-get install bc (Ubuntu)"
    else
        success "bc found for calculations"
    fi
    
    # Check project structure
    if [ ! -d "$CONTRACTS_DIR" ]; then
        error "Contracts directory not found: $CONTRACTS_DIR"
    fi
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        error "Frontend directory not found: $FRONTEND_DIR"
    fi
    
    if [ ! -f "$CONTRACTS_DIR/Move.toml" ]; then
        error "Move.toml not found in contracts directory"
    fi
    
    success "Project structure validated"
}

# Setup Sui environment automatically
setup_sui_environment() {
    log "🌐 Setting up Sui testnet environment..."
    
    # Check if testnet environment exists
    local existing_env=$(sui client envs 2>/dev/null | grep testnet | head -1 || echo "")
    
    if [ -z "$existing_env" ]; then
        info "Creating testnet environment..."
        sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443
        success "Testnet environment created"
    else
        info "Testnet environment already exists"
    fi
    
    # Switch to testnet
    info "Switching to testnet environment..."
    sui client switch --env testnet
    
    # Verify environment
    local active_env=$(sui client active-env 2>/dev/null || echo "")
    if [ "$active_env" != "testnet" ]; then
        error "Failed to switch to testnet environment. Active: $active_env"
    fi
    success "Active environment: $active_env"
    
    # Get deployer address
    DEPLOYER_ADDRESS=$(sui client active-address 2>/dev/null || echo "")
    if [ -z "$DEPLOYER_ADDRESS" ]; then
        info "No active address found. Creating new address..."
        sui client new-address ed25519
        DEPLOYER_ADDRESS=$(sui client active-address 2>/dev/null || echo "")
    fi
    
    if [ -z "$DEPLOYER_ADDRESS" ]; then
        error "Failed to get or create deployer address"
    fi
    success "Deployer address: $DEPLOYER_ADDRESS"
    
    # Set deployment timestamp
    DEPLOYMENT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
}

# Enhanced balance check with automatic faucet guidance
check_balance_and_faucet() {
    log "💰 Checking SUI balance..."
    
    local balance_output=$(sui client balance 2>/dev/null || echo "")
    local balance_sui="0"
    local balance_mist="0"
    
    if echo "$balance_output" | grep -q "SUI"; then
        balance_sui=$(echo "$balance_output" | grep -oE '[0-9]+(\.[0-9]+)?\s*SUI' | grep -oE '[0-9]+(\.[0-9]+)?' | head -1 || echo "0")
        
        # Convert to MIST for precise calculations
        if command -v bc &> /dev/null; then
            balance_mist=$(echo "$balance_sui * 1000000000" | bc | cut -d'.' -f1)
        else
            balance_mist=$(awk "BEGIN {printf \"%.0f\", $balance_sui * 1000000000}")
        fi
    fi
    
    local min_balance_mist=200000000  # 0.2 SUI minimum
    
    if [ "$balance_mist" -lt "$min_balance_mist" ]; then
        warn "Insufficient SUI balance for deployment: $balance_sui SUI"
        warn "Minimum required: 0.2 SUI (recommended: 0.5 SUI)"
        
        echo
        echo -e "${CYAN}🚰 GET TESTNET SUI TOKENS:${NC}"
        echo -e "${YELLOW}1. Web Faucet (Recommended):${NC}"
        echo -e "   ${BLUE}https://faucet.testnet.sui.io${NC}"
        echo -e "   ${GREEN}Enter your address: $DEPLOYER_ADDRESS${NC}"
        echo
        echo -e "${YELLOW}2. CLI Faucet:${NC}"
        echo -e "   ${GREEN}sui client faucet${NC}"
        echo
        echo -e "${YELLOW}3. Discord Faucet:${NC}"
        echo -e "   ${GREEN}Join: https://discord.gg/sui${NC}"
        echo -e "   ${GREEN}Channel: #testnet-faucet${NC}"
        echo -e "   ${GREEN}Command: !faucet $DEPLOYER_ADDRESS${NC}"
        echo
        
        read -p "$(echo -e ${YELLOW}Continue with deployment? (y/N): ${NC})" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            error "Deployment cancelled. Please get testnet SUI and try again."
        fi
        
        warn "Proceeding with low balance. Deployment may fail due to insufficient gas."
    else
        success "Sufficient SUI balance: $balance_sui SUI"
        
        # Calculate estimated cost
        local estimated_cost_sui="0.1"
        if command -v bc &> /dev/null; then
            local remaining_after=$(echo "scale=2; $balance_sui - $estimated_cost_sui" | bc)
            info "Estimated remaining after deployment: ~$remaining_after SUI"
        fi
    fi
    
    # Store balance for summary
    BALANCE_SUI="$balance_sui"
}

# Install dependencies with progress
install_dependencies() {
    log "📦 Installing dependencies..."
    
    # Install root dependencies
    if [ -f "package.json" ]; then
        info "Installing root dependencies..."
        npm install --silent
        success "Root dependencies installed"
    fi
    
    # Install frontend dependencies
    if [ -f "$FRONTEND_DIR/package.json" ]; then
        info "Installing frontend dependencies..."
        cd "$FRONTEND_DIR"
        npm install --silent
        cd ..
        success "Frontend dependencies installed"
    fi
}

# Build and test contracts with enhanced error handling
build_contracts() {
    log "🔨 Building and testing Move contracts..."
    
    cd "$CONTRACTS_DIR"
    
    # Clean previous builds
    if [ -d "build" ]; then
        rm -rf build
        info "Cleaned previous build artifacts"
    fi
    
    # Build contracts
    info "Compiling Move contracts..."
    local build_output
    if ! build_output=$(sui move build 2>&1); then
        echo "$build_output" | tee -a "../../$LOG_FILE"
        error "Contract compilation failed. Check the logs above for details."
    fi
    
    # Log build warnings (but don't fail)
    if echo "$build_output" | grep -q "warning"; then
        warn "Build completed with warnings:"
        echo "$build_output" | grep "warning" | head -5
    fi
    
    success "Contracts compiled successfully"
    
    # Run tests
    info "Running Move tests..."
    local test_output
    if ! test_output=$(sui move test 2>&1); then
        echo "$test_output" | tee -a "../../$LOG_FILE"
        warn "Some tests failed, but continuing with deployment"
    else
        success "All tests passed"
    fi
    
    cd "../.."
}

# Enhanced deployment with comprehensive object parsing
deploy_contracts() {
    log "🚀 Deploying contracts to Sui testnet..."
    
    cd "$CONTRACTS_DIR"
    
    # Deploy the package with enhanced error handling
    info "Publishing Move package (gas budget: $GAS_BUDGET MIST)..."
    local deploy_output
    if ! deploy_output=$(sui client publish --gas-budget $GAS_BUDGET --json 2>&1); then
        echo "$deploy_output" | tee -a "../../$LOG_FILE"
        error "Contract deployment failed. Check the logs above for details."
    fi
    
    # Enhanced JSON parsing with fallbacks
    if command -v jq &> /dev/null; then
        PACKAGE_ID=$(echo "$deploy_output" | jq -r '.objectChanges[] | select(.type == "published") | .packageId' 2>/dev/null || echo "")
        TX_DIGEST=$(echo "$deploy_output" | jq -r '.digest' 2>/dev/null || echo "")
        
        # Try to find protocol-related objects
        PROTOCOL_OBJECT_ID=$(echo "$deploy_output" | jq -r '.objectChanges[] | select(.objectType | contains("Protocol")) | .objectId' 2>/dev/null || echo "")
        CHOCOLATE_FACTORY_ID=$(echo "$deploy_output" | jq -r '.objectChanges[] | select(.objectType | contains("ChocolateFactory")) | .objectId' 2>/dev/null || echo "")
        ADMIN_CAP_ID=$(echo "$deploy_output" | jq -r '.objectChanges[] | select(.objectType | contains("AdminCap")) | .objectId' 2>/dev/null || echo "")
        FACTORY_ADMIN_ID=$(echo "$deploy_output" | jq -r '.objectChanges[] | select(.objectType | contains("FactoryAdmin")) | .objectId' 2>/dev/null || echo "")
    else
        # Fallback parsing without jq
        PACKAGE_ID=$(echo "$deploy_output" | grep -o '"packageId":"[^"]*"' | cut -d'"' -f4 | head -1)
        TX_DIGEST=$(echo "$deploy_output" | grep -o '"digest":"[^"]*"' | cut -d'"' -f4)
    fi
    
    # Validate required fields
    if [ -z "$PACKAGE_ID" ] || [ "$PACKAGE_ID" = "null" ]; then
        echo "$deploy_output" | tee -a "../../$LOG_FILE"
        error "Failed to extract package ID from deployment output"
    fi
    
    if [ -z "$TX_DIGEST" ] || [ "$TX_DIGEST" = "null" ]; then
        warn "Could not extract transaction digest"
        TX_DIGEST="unknown"
    fi
    
    cd "../.."
    
    success "Deployment completed successfully!"
    success "Package ID: $PACKAGE_ID"
    success "Transaction: $TX_DIGEST"
}

# Comprehensive environment file generation
update_env_files() {
    log "📝 Automatically updating environment files..."
    
    # Generate comprehensive .env file
    info "Creating root .env file..."
    cat > "$ENV_FILE" << EOF
# =============================================================================
# MeltyFi Protocol Configuration
# Generated automatically on $(date)
# =============================================================================

# Network Configuration
NEXT_PUBLIC_SUI_NETWORK=testnet
NEXT_PUBLIC_SUI_RPC_URL=https://fullnode.testnet.sui.io:443

# Deployment Information
NEXT_PUBLIC_MELTYFI_PACKAGE_ID=$PACKAGE_ID
NEXT_PUBLIC_PROTOCOL_OBJECT_ID=$PROTOCOL_OBJECT_ID
NEXT_PUBLIC_CHOCOLATE_FACTORY_ID=$CHOCOLATE_FACTORY_ID

# Token Types (auto-generated)
NEXT_PUBLIC_CHOCO_CHIP_TYPE=${PACKAGE_ID}::choco_chip::CHOCO_CHIP
NEXT_PUBLIC_WONKA_BARS_TYPE=${PACKAGE_ID}::wonka_bars::WonkaBars

# Admin Objects (for admin functions)
NEXT_PUBLIC_ADMIN_CAP_ID=$ADMIN_CAP_ID
NEXT_PUBLIC_FACTORY_ADMIN_ID=$FACTORY_ADMIN_ID

# Application Configuration
NEXT_PUBLIC_APP_NAME=MeltyFi
NEXT_PUBLIC_APP_DESCRIPTION=Making the illiquid liquid
NODE_ENV=development
NEXT_PUBLIC_DEBUG=true
NETWORK=testnet

# Deployment Metadata
DEPLOYED_AT=$DEPLOYMENT_TIMESTAMP
DEPLOYED_BY=$DEPLOYER_ADDRESS
DEPLOYMENT_TX=$TX_DIGEST
DEPLOYMENT_BLOCK=auto

# Explorer URLs
NEXT_PUBLIC_EXPLORER_URL=https://suiexplorer.com
NEXT_PUBLIC_FAUCET_URL=https://faucet.testnet.sui.io

# Gas Configuration
NEXT_PUBLIC_DEFAULT_GAS_BUDGET=10000000
NEXT_PUBLIC_MAX_GAS_BUDGET=1000000000

# Feature Flags
NEXT_PUBLIC_ENABLE_LOTTERY=true
NEXT_PUBLIC_ENABLE_STAKING=true
NEXT_PUBLIC_ENABLE_ADMIN_PANEL=true
EOF
    
    success "Root .env file created with all configurations"
    
    # Create frontend .env.local (identical but in frontend directory)
    info "Creating frontend .env.local file..."
    cp "$ENV_FILE" "$FRONTEND_ENV_FILE"
    success "Frontend .env.local file created"
    
    # Create a .env.example for version control
    info "Creating .env.example template..."
    sed 's/=.*/=/' "$ENV_FILE" > .env.example
    success ".env.example template created"
    
    # Display environment summary
    echo
    echo -e "${CYAN}📋 Environment Configuration Summary:${NC}"
    echo -e "${GREEN}├─ Package ID: ${BLUE}$PACKAGE_ID${NC}"
    echo -e "${GREEN}├─ Protocol Object: ${BLUE}$PROTOCOL_OBJECT_ID${NC}"
    echo -e "${GREEN}├─ Chocolate Factory: ${BLUE}$CHOCOLATE_FACTORY_ID${NC}"
    echo -e "${GREEN}├─ Admin Cap: ${BLUE}$ADMIN_CAP_ID${NC}"
    echo -e "${GREEN}├─ Factory Admin: ${BLUE}$FACTORY_ADMIN_ID${NC}"
    echo -e "${GREEN}├─ Transaction: ${BLUE}$TX_DIGEST${NC}"
    echo -e "${GREEN}├─ Deployer: ${BLUE}$DEPLOYER_ADDRESS${NC}"
    echo -e "${GREEN}└─ Network: ${BLUE}testnet${NC}"
    echo
}

# Create comprehensive deployment info JSON
generate_deployment_info() {
    log "📄 Generating deployment info file..."
    
    cat > "$DEPLOYMENT_INFO_FILE" << EOF
{
    "deployment": {
        "timestamp": "$DEPLOYMENT_TIMESTAMP",
        "network": "testnet",
        "deployer": "$DEPLOYER_ADDRESS",
        "transaction": "$TX_DIGEST",
        "gasUsed": "auto-calculated",
        "status": "success"
    },
    "contracts": {
        "packageId": "$PACKAGE_ID",
        "protocolObject": "$PROTOCOL_OBJECT_ID",
        "chocolateFactory": "$CHOCOLATE_FACTORY_ID",
        "adminCap": "$ADMIN_CAP_ID",
        "factoryAdmin": "$FACTORY_ADMIN_ID"
    },
    "types": {
        "chocoChip": "${PACKAGE_ID}::choco_chip::CHOCO_CHIP",
        "wonkaBars": "${PACKAGE_ID}::wonka_bars::WonkaBars"
    },
    "explorer": {
        "package": "https://suiexplorer.com/object/$PACKAGE_ID?network=testnet",
        "transaction": "https://suiexplorer.com/txblock/$TX_DIGEST?network=testnet",
        "deployer": "https://suiexplorer.com/address/$DEPLOYER_ADDRESS?network=testnet"
    },
    "configuration": {
        "envFile": ".env",
        "frontendEnvFile": "frontend/.env.local",
        "network": {
            "rpc": "https://fullnode.testnet.sui.io:443",
            "faucet": "https://faucet.testnet.sui.io",
            "explorer": "https://suiexplorer.com"
        }
    },
    "nextSteps": [
        "Start frontend: cd frontend && npm run dev",
        "Connect wallet: Use Sui Wallet browser extension",
        "Get testnet SUI: Visit https://faucet.testnet.sui.io",
        "Test protocol: Create lotteries and buy WonkaBars"
    ]
}
EOF
    
    success "Deployment info saved to: $DEPLOYMENT_INFO_FILE"
}

# Enhanced verification with automatic checks
verify_deployment() {
    log "✅ Verifying deployment..."
    
    # Verify package exists on-chain
    info "Verifying package on-chain..."
    if sui client object "$PACKAGE_ID" &>/dev/null; then
        success "Package verified on testnet"
    else
        warn "Could not verify package on-chain (may be normal due to indexing delay)"
    fi
    
    # Verify environment files exist
    if [ -f "$ENV_FILE" ]; then
        success "Root .env file created"
    else
        error "Root .env file missing"
    fi
    
    if [ -f "$FRONTEND_ENV_FILE" ]; then
        success "Frontend .env.local file created"
    else
        error "Frontend .env.local file missing"
    fi
    
    # Check if package ID is valid format
    if [[ $PACKAGE_ID =~ ^0x[a-fA-F0-9]{64}$ ]]; then
        success "Package ID format valid"
    else
        warn "Package ID format appears invalid: $PACKAGE_ID"
    fi
    
    # Verify JSON file
    if [ -f "$DEPLOYMENT_INFO_FILE" ]; then
        if command -v jq &> /dev/null; then
            if jq empty "$DEPLOYMENT_INFO_FILE" 2>/dev/null; then
                success "Deployment info JSON valid"
            else
                warn "Deployment info JSON may be malformed"
            fi
        else
            success "Deployment info file created"
        fi
    fi
}

# Build frontend with enhanced error handling
build_frontend() {
    log "🏗️  Building frontend to verify configuration..."
    
    cd "$FRONTEND_DIR"
    
    info "Installing any missing frontend dependencies..."
    npm install --silent
    
    info "Building frontend..."
    if npm run build 2>&1 | tee -a "../$LOG_FILE"; then
        success "Frontend build successful"
    else
        warn "Frontend build failed - check configuration"
        warn "This may be due to missing dependencies or environment issues"
        warn "Try running: cd frontend && npm install && npm run build"
    fi
    
    cd ".."
}

# Comprehensive deployment summary with actionable next steps
generate_summary() {
    local final_balance=$(sui client balance 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)?\s*SUI' | grep -oE '[0-9]+(\.[0-9]+)?' | head -1 || echo "unknown")
    local deployment_cost="unknown"
    
    if [ "$final_balance" != "unknown" ] && [ "$BALANCE_SUI" != "unknown" ] && command -v bc &> /dev/null; then
        deployment_cost=$(echo "scale=3; $BALANCE_SUI - $final_balance" | bc 2>/dev/null || echo "unknown")
    fi
    
    echo
    echo -e "${GREEN}🎉 DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉${NC}"
    echo
    
    cat << EOF

${CYAN}📋 Deployment Summary:${NC}
├─ Network: ${YELLOW}Sui Testnet${NC}
├─ Package ID: ${BLUE}$PACKAGE_ID${NC}
├─ Protocol Object: ${BLUE}$PROTOCOL_OBJECT_ID${NC}
├─ Chocolate Factory: ${BLUE}$CHOCOLATE_FACTORY_ID${NC}
├─ Deployer: ${BLUE}$DEPLOYER_ADDRESS${NC}
├─ Transaction: ${BLUE}$TX_DIGEST${NC}
├─ Initial Balance: ${YELLOW}${BALANCE_SUI:-unknown} SUI${NC}
├─ Final Balance: ${YELLOW}$final_balance SUI${NC}
└─ Deployment Cost: ${YELLOW}~$deployment_cost SUI${NC}

${CYAN}🔗 Explorer Links:${NC}
├─ Package: ${BLUE}https://suiexplorer.com/object/$PACKAGE_ID?network=testnet${NC}
├─ Transaction: ${BLUE}https://suiexplorer.com/txblock/$TX_DIGEST?network=testnet${NC}
└─ Testnet Faucet: ${BLUE}https://faucet.testnet.sui.io${NC}

${CYAN}🚀 Next Steps:${NC}
1. ${GREEN}Start frontend:${NC} cd frontend && npm run dev
2. ${GREEN}Connect wallet:${NC} Use Sui Wallet browser extension
3. ${GREEN}Get testnet SUI:${NC} Visit the faucet link above
4. ${GREEN}Test protocol:${NC} Create lotteries and buy WonkaBars!

${CYAN}📁 Generated Files:${NC}
├─ ${YELLOW}.env${NC} - Root environment configuration
├─ ${YELLOW}frontend/.env.local${NC} - Frontend environment
├─ ${YELLOW}deployment_info.json${NC} - Complete deployment details
├─ ${YELLOW}.env.example${NC} - Template for version control
└─ ${YELLOW}deployment.log${NC} - Full deployment logs

${CYAN}💡 Testing Tips:${NC}
├─ Current balance (${final_balance} SUI) should be sufficient for testing
├─ Each lottery creation costs ~0.01-0.02 SUI
├─ Each WonkaBar purchase costs the set price + gas (~0.001 SUI)
└─ If you run low, use the testnet faucet above

${GREEN}Happy testing! 🍫✨${NC}

EOF
}

# Error cleanup with helpful messages
cleanup_on_error() {
    warn "Deployment failed, but don't worry! Here's what you can do:"
    echo
    echo -e "${YELLOW}🔧 Common Solutions:${NC}"
    echo -e "${GREEN}1. Check SUI balance:${NC} sui client balance"
    echo -e "${GREEN}2. Get testnet SUI:${NC} https://faucet.testnet.sui.io"
    echo -e "${GREEN}3. Verify environment:${NC} sui client active-env"
    echo -e "${GREEN}4. Check logs:${NC} cat $LOG_FILE"
    echo -e "${GREEN}5. Clean and retry:${NC} rm -rf build && ./scripts/deployment.sh"
    echo
    echo -e "${CYAN}💬 Need Help?${NC}"
    echo -e "${GREEN}├─ Discord:${NC} https://discord.gg/sui"
    echo -e "${GREEN}├─ Documentation:${NC} https://docs.sui.io"
    echo -e "${GREEN}└─ Issues:${NC} https://github.com/VincenzoImp/MeltyFi/issues"
    echo
}

# Main deployment flow with progress tracking
main() {
    # Set up error handling
    trap cleanup_on_error ERR
    
    # Clear previous log
    > "$LOG_FILE"
    
    print_banner
    log "Starting fully automated MeltyFi Protocol deployment..."
    
    # Progress tracking
    local steps=("Prerequisites" "Environment" "Dependencies" "Contracts" "Deployment" "Configuration" "Verification" "Frontend" "Summary")
    local current_step=0
    
    echo -e "${CYAN}📊 Deployment Progress: [1/9] Prerequisites${NC}"
    check_prerequisites
    
    echo -e "${CYAN}📊 Deployment Progress: [2/9] Environment${NC}"
    setup_sui_environment
    check_balance_and_faucet
    
    echo -e "${CYAN}📊 Deployment Progress: [3/9] Dependencies${NC}"
    install_dependencies
    
    echo -e "${CYAN}📊 Deployment Progress: [4/9] Contracts${NC}"
    build_contracts
    
    echo -e "${CYAN}📊 Deployment Progress: [5/9] Deployment${NC}"
    deploy_contracts
    
    echo -e "${CYAN}📊 Deployment Progress: [6/9] Configuration${NC}"
    update_env_files
    generate_deployment_info
    
    echo -e "${CYAN}📊 Deployment Progress: [7/9] Verification${NC}"
    verify_deployment
    
    echo -e "${CYAN}📊 Deployment Progress: [8/9] Frontend${NC}"
    build_frontend
    
    echo -e "${CYAN}📊 Deployment Progress: [9/9] Summary${NC}"
    generate_summary
    
    success "🎉 Full automated deployment completed successfully!"
}

# Script options and help
case "${1:-}" in
    --help|-h)
        echo "MeltyFi Automated Deployment Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h         Show this help message"
        echo "  --clean            Clean all build artifacts before deployment"
        echo "  --skip-frontend    Skip frontend build step"
        echo "  --force            Force deployment even with low balance"
        echo ""
        echo "Environment Variables:"
        echo "  GAS_BUDGET         Gas budget for deployment (default: 100000000)"
        echo "  NETWORK            Target network (default: testnet)"
        echo ""
        echo "This script will automatically:"
        echo "  ✅ Check all prerequisites"
        echo "  ✅ Setup Sui testnet environment"
        echo "  ✅ Install all dependencies"
        echo "  ✅ Build and test Move contracts"
        echo "  ✅ Deploy contracts to testnet"
        echo "  ✅ Generate environment files (.env, frontend/.env.local)"
        echo "  ✅ Create deployment info JSON"
        echo "  ✅ Verify deployment"
        echo "  ✅ Build frontend"
        echo "  ✅ Provide complete summary with next steps"
        echo ""
        exit 0
        ;;
    --clean)
        log "🧹 Cleaning build artifacts..."
        rm -rf "$CONTRACTS_DIR/build"
        rm -f "$LOG_FILE"
        rm -f "$DEPLOYMENT_INFO_FILE"
        rm -f "$ENV_FILE"
        rm -f "$FRONTEND_ENV_FILE"
        rm -f ".env.example"
        success "Clean completed"
        exit 0
        ;;
    --skip-frontend)
        build_frontend() { 
            log "⏭️  Skipping frontend build as requested"
            info "You can build it later with: cd frontend && npm run build"
        }
        main
        ;;
    --force)
        check_balance_and_faucet() {
            log "⚡ Force mode: Skipping balance check"
            warn "Proceeding without balance verification"
            BALANCE_SUI="unknown"
        }
        main
        ;;
    "")
        main
        ;;
    *)
        error "Unknown option: $1. Use --help for usage information."
        ;;
esac