#!/bin/bash

# Enhanced Sui Environment Setup Script for MeltyFi - TESTNET
# Comprehensive setup with error handling and validation for testnet

set -e  # Exit on any error

echo "🔧 Setting up Sui testnet environment for MeltyFi..."

# Colors and formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/../sui_setup.log"

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: $1" >> "$LOG_FILE"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') SUCCESS: $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: $1" >> "$LOG_FILE"
}

print_step() {
    echo -e "${PURPLE}🔄 $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') STEP: $1" >> "$LOG_FILE"
}

print_header() {
    echo -e "${BOLD}${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    🍫 MeltyFi Setup                        ║"
    echo "║             Sui Testnet Environment Configuration          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Initialize logging
echo "Sui testnet environment setup started at $(date)" > "$LOG_FILE"

# Error handling
handle_error() {
    print_error "Setup failed at step: $1"
    print_info "Check the log file for details: $LOG_FILE"
    print_info "Common solutions:"
    print_info "1. Ensure Sui CLI is properly installed"
    print_info "2. Check your internet connection"
    print_info "3. Try running the script again"
    exit 1
}

# Trap errors
trap 'handle_error "Unknown error"' ERR

# Prerequisites check
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if Sui CLI is installed
    if ! command -v sui &> /dev/null; then
        print_error "Sui CLI not found!"
        echo
        print_info "Please install Sui CLI first:"
        echo -e "${YELLOW}cargo install --locked --git https://github.com/MystenLabs/sui.git --branch testnet sui${NC}"
        echo
        print_info "Or use the install script:"
        echo -e "${YELLOW}curl -fsSL https://github.com/MystenLabs/sui/raw/main/scripts/install.sh | bash${NC}"
        exit 1
    fi
    
    # Check if jq is available (for JSON parsing)
    if ! command -v jq &> /dev/null; then
        print_warning "jq not found. Installing would improve balance checking."
        print_info "Install with: apt-get install jq (Ubuntu) or brew install jq (macOS)"
    fi
    
    # Display Sui version
    local sui_version=$(sui --version 2>/dev/null | head -1)
    print_status "Sui CLI found: $sui_version"
}

# Configure Sui client for testnet
configure_sui_client() {
    print_step "Configuring Sui client for testnet..."
    
    # Add testnet environment (check if it exists first)
    print_info "Configuring testnet environment..."
    if sui client envs 2>/dev/null | grep -q "testnet"; then
        print_info "Testnet environment already exists"
    else
        print_info "Adding testnet environment..."
        if sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443; then
            print_status "Testnet environment added"
        else
            handle_error "Failed to add testnet environment"
        fi
    fi
    
    # Switch to testnet
    print_info "Switching to testnet..."
    if sui client switch --env testnet; then
        print_status "Switched to testnet"
    else
        handle_error "Failed to switch to testnet"
    fi
    
    # Verify environment
    local current_env=$(sui client active-env 2>/dev/null || echo "unknown")
    if [ "$current_env" = "testnet" ]; then
        print_status "Successfully configured for testnet"
    else
        print_warning "Current environment: $current_env (expected: testnet)"
    fi
}

# Create or verify address
setup_address() {
    print_step "Setting up Sui address..."
    
    # Check for existing addresses
    print_info "Checking for existing addresses..."
    local addresses=$(sui client addresses 2>/dev/null || echo "")
    
    if echo "$addresses" | grep -q "0x"; then
        print_status "Existing address found"
        local address_count=$(echo "$addresses" | grep -c "0x" || echo "0")
        print_info "Found $address_count address(es)"
    else
        print_info "No addresses found. Creating new address..."
        if sui client new-address ed25519; then
            print_status "New ed25519 address created"
        else
            handle_error "Failed to create new address"
        fi
    fi
    
    # Display active address
    local active_address=$(sui client active-address 2>/dev/null || echo "unknown")
    if [ "$active_address" != "unknown" ]; then
        print_status "Active address: $active_address"
    else
        handle_error "No active address found"
    fi
}

# Check balance and guide user through faucet process
check_balance_and_faucet() {
    print_step "Checking SUI balance and faucet setup..."
    
    local current_address=$(sui client active-address 2>/dev/null || echo "")
    if [ -z "$current_address" ] || [ "$current_address" = "unknown" ]; then
        print_error "No active address found"
        return 1
    fi
    
    print_info "Checking balance for address: $current_address"
    
    # Get balance with fallback if jq is not available
    local balance="0"
    if command -v jq &> /dev/null; then
        balance=$(sui client balance --json 2>/dev/null | jq -r '.[] | select(.coinType == "0x2::sui::SUI") | .totalBalance // "0"' 2>/dev/null || echo "0")
    else
        # Fallback: parse balance without jq
        local balance_output=$(sui client balance 2>/dev/null || echo "")
        if echo "$balance_output" | grep -q "SUI"; then
            balance=$(echo "$balance_output" | grep -o '[0-9]*' | head -1 || echo "0")
            # Convert to MIST (multiply by 10^9) if needed
            if [ ${#balance} -lt 10 ]; then
                balance="${balance}000000000"
            fi
        fi
    fi
    
    local balance_sui=$((balance / 1000000000))
    local balance_mist=$((balance % 1000000000))
    
    print_info "Current balance: $balance_sui.$((balance_mist / 1000000)) SUI"
    
    if [ "$balance" -eq "0" ]; then
        print_warning "No SUI balance found. You need testnet tokens to deploy contracts."
        print_info ""
        print_info "🚰 Getting testnet SUI tokens:"
        print_info "════════════════════════════════════"
        print_info "Option 1 - Web Faucet (Recommended):"
        print_info "  1. Visit: https://faucet.testnet.sui.io"
        print_info "  2. Enter your address: $current_address"
        print_info "  3. Complete captcha and request tokens"
        print_info ""
        print_info "Option 2 - Discord Faucet:"
        print_info "  1. Join Sui Discord: https://discord.gg/sui"
        print_info "  2. Go to #testnet-faucet channel"
        print_info "  3. Use command: !faucet $current_address"
        print_info ""
        print_info "Option 3 - CLI Faucet:"
        print_info "  Run: sui client faucet"
        print_info ""
        
        # Interactive faucet process
        echo -e "${YELLOW}Choose your preferred method:${NC}"
        echo "1) I'll use Web faucet"  
        echo "2) I'll use Discord faucet"
        echo "3) Use CLI faucet now"
        echo "4) Skip for now"
        
        read -p "Enter choice (1-4): " choice
        
        case $choice in
            1)
                print_info "Opening web faucet..."
                if command -v open &> /dev/null; then
                    open "https://faucet.testnet.sui.io"
                elif command -v xdg-open &> /dev/null; then
                    xdg-open "https://faucet.testnet.sui.io"
                fi
                print_info "Use address: $current_address"
                ;;
            2)
                print_info "Great! Use Discord faucet with address: $current_address"
                ;;
            3)
                print_info "Requesting tokens via CLI..."
                if sui client faucet; then
                    print_status "CLI faucet request sent"
                else
                    print_warning "CLI faucet failed, try web or Discord faucet"
                fi
                ;;
            4)
                print_warning "Skipping faucet. Remember to get SUI before deployment!"
                return 0
                ;;
            *)
                print_warning "Invalid choice. Please use web or Discord faucet manually."
                ;;
        esac
        
        if [ "$choice" != "4" ]; then
            print_info ""
            read -p "$(echo -e ${YELLOW}Press Enter after requesting SUI tokens...${NC})"
            
            # Check balance again
            print_info "Rechecking balance..."
            sleep 2  # Give some time for the transaction to process
            
            if command -v jq &> /dev/null; then
                balance=$(sui client balance --json 2>/dev/null | jq -r '.[] | select(.coinType == "0x2::sui::SUI") | .totalBalance // "0"' 2>/dev/null || echo "0")
            else
                local balance_output=$(sui client balance 2>/dev/null || echo "")
                if echo "$balance_output" | grep -q "SUI"; then
                    balance=$(echo "$balance_output" | grep -o '[0-9]*' | head -1 || echo "0")
                    if [ ${#balance} -lt 10 ]; then
                        balance="${balance}000000000"
                    fi
                fi
            fi
            
            balance_sui=$((balance / 1000000000))
            
            if [ "$balance" -gt "0" ]; then
                print_status "✨ SUI tokens received! New balance: $balance_sui SUI"
            else
                print_warning "No SUI tokens detected yet."
                print_info "Transactions may take a few moments to appear."
                print_info "You can check your balance later with: sui client balance"
            fi
        fi
    else
        print_status "✨ SUI balance available: $balance_sui SUI"
        if [ "$balance_sui" -gt 1 ]; then
            print_status "Sufficient balance for contract deployment!"
        else
            print_warning "Low balance. Consider getting more SUI for multiple transactions."
        fi
    fi
}

# Display configuration summary
display_summary() {
    print_step "Configuration Summary"
    
    local current_env=$(sui client active-env 2>/dev/null || echo "unknown")
    local current_address=$(sui client active-address 2>/dev/null || echo "unknown")
    local balance="0"
    
    if command -v jq &> /dev/null; then
        balance=$(sui client balance --json 2>/dev/null | jq -r '.[] | select(.coinType == "0x2::sui::SUI") | .totalBalance // "0"' 2>/dev/null || echo "0")
    fi
    
    local balance_sui=$((balance / 1000000000))
    
    echo
    echo -e "${BOLD}📋 Sui Configuration Summary:${NC}"
    echo "═══════════════════════════════════════"
    echo -e "Environment:  ${GREEN}$current_env${NC}"
    echo -e "Address:      ${GREEN}$current_address${NC}"
    echo -e "Balance:      ${GREEN}$balance_sui SUI${NC}"
    echo -e "RPC URL:      ${GREEN}https://fullnode.testnet.sui.io:443${NC}"
    echo "═══════════════════════════════════════"
    echo
}

# Main setup function
main() {
    print_header
    
    print_info "Starting Sui testnet environment setup for MeltyFi protocol..."
    print_info "This script will configure your Sui CLI for testnet deployment."
    echo
    
    check_prerequisites
    configure_sui_client
    setup_address
    check_balance_and_faucet
    display_summary
    
    print_status "🎉 Sui testnet environment setup complete!"
    print_info ""
    print_info "Next steps:"
    print_info "1. Run the deployment script: ./scripts/deployment.sh"
    print_info "2. Or use the project scripts: npm run deploy:testnet"
    print_info ""
    print_info "For troubleshooting, check the log: $LOG_FILE"
    
    # Save configuration to file
    local config_file="$SCRIPT_DIR/../sui-config.txt"
    cat > "$config_file" << EOF
# Sui Configuration for MeltyFi
Environment: $(sui client active-env 2>/dev/null || echo "unknown")
Address: $(sui client active-address 2>/dev/null || echo "unknown")
Setup Date: $(date)
Log File: $LOG_FILE
EOF
    
    print_info "Configuration saved to: $config_file"
}

# Cleanup function
cleanup() {
    # Remove any temporary files if created
    true
}

# Set cleanup trap
trap cleanup EXIT

# Run main function
main "$@"