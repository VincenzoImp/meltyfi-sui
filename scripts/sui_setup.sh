#!/bin/bash

# Quick Sui Environment Setup Script
# Run this before the main deployment script

echo "🔧 Setting up Sui environment..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 1: Configure Sui client
print_info "Configuring Sui client..."

# Add devnet environment
print_info "Adding devnet environment..."
sui client new-env --alias devnet --rpc https://fullnode.devnet.sui.io:443

# Switch to devnet
print_info "Switching to devnet..."
sui client switch --env devnet

# Step 2: Create address if needed
print_info "Checking for existing addresses..."
if ! sui client addresses 2>/dev/null | grep -q "0x"; then
    print_info "No addresses found. Creating new address..."
    sui client new-address ed25519
else
    print_status "Address already exists"
fi

# Step 3: Display current configuration
print_status "Sui environment setup complete!"
print_info "Current configuration:"
echo "Environment: $(sui client active-env 2>/dev/null || echo 'unknown')"
echo "Address: $(sui client active-address 2>/dev/null || echo 'unknown')"

# Step 4: Check balance and provide faucet instructions
CURRENT_ADDRESS=$(sui client active-address 2>/dev/null || echo "")
if [ -n "$CURRENT_ADDRESS" ]; then
    print_info "Getting testnet SUI tokens..."
    print_info "Address: $CURRENT_ADDRESS"
    
    # Try to get balance
    BALANCE=$(sui client balance --json 2>/dev/null | jq -r '.[] | select(.coinType == "0x2::sui::SUI") | .totalBalance // "0"' 2>/dev/null || echo "0")
    
    if [ "$BALANCE" -eq "0" ]; then
        print_warning "No SUI balance found. Getting testnet tokens..."
        print_info "Please get testnet SUI from Discord:"
        print_info "1. Join Sui Discord: https://discord.gg/sui"
        print_info "2. Go to #devnet-faucet channel"
        print_info "3. Use command: !faucet $CURRENT_ADDRESS"
        print_info ""
        print_info "Alternatively, use the web faucet:"
        print_info "https://faucet.devnet.sui.io/gas"
        print_info ""
        
        read -p "$(echo -e ${YELLOW}Press Enter after getting testnet SUI tokens...${NC})"
        
        # Check balance again
        BALANCE=$(sui client balance --json 2>/dev/null | jq -r '.[] | select(.coinType == "0x2::sui::SUI") | .totalBalance // "0"' 2>/dev/null || echo "0")
        if [ "$BALANCE" -gt "0" ]; then
            print_status "SUI tokens received! Balance: $((BALANCE / 1000000000)) SUI"
        else
            print_warning "No SUI tokens detected. You may need to wait a moment or try again."
        fi
    else
        print_status "Current balance: $((BALANCE / 1000000000)) SUI"
    fi
fi

print_status "Setup complete! You can now run the deployment script."
print_info "Run: ./scripts/deployment_script.sh"