#!/bin/bash

# Sui Environment Validation Script for MeltyFi - TESTNET
# Validates that Sui environment is properly configured for testnet

echo "🔍 Validating Sui testnet environment for MeltyFi deployment..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0
WARNINGS=0

print_test() {
    echo -e "${BLUE}🧪 Testing: $1${NC}"
}

print_pass() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
    ((PASSED++))
}

print_fail() {
    echo -e "${RED}❌ FAIL: $1${NC}"
    ((FAILED++))
}

print_warn() {
    echo -e "${YELLOW}⚠️  WARN: $1${NC}"
    ((WARNINGS++))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Test 1: Sui CLI Installation
print_test "Sui CLI installation"
if command -v sui &> /dev/null; then
    SUI_VERSION=$(sui --version | head -1)
    print_pass "Sui CLI found: $SUI_VERSION"
else
    print_fail "Sui CLI not found"
    print_info "Install with: cargo install --locked --git https://github.com/MystenLabs/sui.git --branch testnet sui"
fi

# Test 2: Active Environment
print_test "Active environment configuration"
ACTIVE_ENV=$(sui client active-env 2>/dev/null || echo "")
if [ "$ACTIVE_ENV" = "testnet" ]; then
    print_pass "Active environment: testnet"
elif [ -n "$ACTIVE_ENV" ]; then
    print_warn "Active environment: $ACTIVE_ENV (expected: testnet)"
    print_info "Switch with: sui client switch --env testnet"
else
    print_fail "No active environment found"
    print_info "Set up with: sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443"
fi

# Test 3: Active Address
print_test "Active address configuration"
ACTIVE_ADDRESS=$(sui client active-address 2>/dev/null || echo "")
if [[ $ACTIVE_ADDRESS =~ ^0x[a-fA-F0-9]{64}$ ]]; then
    print_pass "Valid active address: ${ACTIVE_ADDRESS:0:8}...${ACTIVE_ADDRESS:60:4}"
elif [ -n "$ACTIVE_ADDRESS" ]; then
    print_warn "Unusual address format: $ACTIVE_ADDRESS"
else
    print_fail "No active address found"
    print_info "Create with: sui client new-address ed25519"
fi

# Test 4: Network Connectivity
print_test "Network connectivity to Sui testnet"
if sui client balance &>/dev/null; then
    print_pass "Successfully connected to Sui testnet"
else
    print_fail "Cannot connect to Sui testnet"
    print_info "Check internet connection and RPC endpoint"
fi

# Test 5: Balance Check
print_test "SUI balance availability"
if command -v jq &> /dev/null; then
    BALANCE=$(sui client balance --json 2>/dev/null | jq -r '.[] | select(.coinType == "0x2::sui::SUI") | .totalBalance // "0"' 2>/dev/null || echo "0")
else
    # Fallback without jq
    BALANCE_OUTPUT=$(sui client balance 2>/dev/null || echo "")
    if echo "$BALANCE_OUTPUT" | grep -q "SUI"; then
        BALANCE=$(echo "$BALANCE_OUTPUT" | grep -o '[0-9]*' | head -1 || echo "0")
        # Ensure we have MIST units
        if [ ${#BALANCE} -lt 10 ]; then
            BALANCE="${BALANCE}000000000"
        fi
    else
        BALANCE="0"
    fi
fi

BALANCE_SUI=$((BALANCE / 1000000000))
if [ "$BALANCE" -gt 1000000000 ]; then
    print_pass "SUI balance: $BALANCE_SUI SUI (sufficient for deployment)"
elif [ "$BALANCE" -gt 0 ]; then
    print_warn "SUI balance: $BALANCE_SUI SUI (may be low for multiple transactions)"
    print_info "Get more SUI from: https://faucet.testnet.sui.io"
else
    print_fail "No SUI balance found"
    print_info "Get testnet SUI from web faucet or Discord"
fi

# Test 6: jq availability (optional but helpful)
print_test "JSON parsing utilities"
if command -v jq &> /dev/null; then
    print_pass "jq available for JSON parsing"
else
    print_warn "jq not found (optional but recommended)"
    print_info "Install with: apt-get install jq (Ubuntu) or brew install jq (macOS)"
fi

# Test 7: Environment variables
print_test "Environment variables"
ENV_FILE="../.env"
if [ -f "$ENV_FILE" ]; then
    if grep -q "NEXT_PUBLIC_SUI_NETWORK=testnet" "$ENV_FILE"; then
        print_pass "Environment file configured for testnet"
    else
        print_warn "Environment file exists but may not be configured for testnet"
    fi
else
    print_warn "No .env file found (will be created during deployment)"
fi

# Test 8: Move.toml validation
print_test "Move.toml configuration"
MOVE_TOML="../contracts/meltyfi/Move.toml"
if [ -f "$MOVE_TOML" ]; then
    if grep -q 'framework/testnet' "$MOVE_TOML"; then
        print_pass "Move.toml configured for testnet framework"
    else
        print_warn "Move.toml may not be using testnet framework"
        print_info "Should use: rev = \"framework/testnet\""
    fi
    
    # Check for duplicate addresses
    ADDRESS_COUNT=$(grep -c "meltyfi = " "$MOVE_TOML" 2>/dev/null || echo "0")
    if [ "$ADDRESS_COUNT" -eq 1 ]; then
        print_pass "No duplicate address assignments in Move.toml"
    else
        print_fail "Duplicate or missing address assignments found in Move.toml"
        print_info "This will cause compilation errors"
    fi
else
    print_fail "Move.toml not found"
    print_info "Expected at: $MOVE_TOML"
fi

# Test 9: Node.js availability (for frontend)
print_test "Node.js availability"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | tr -d 'v')
    if [ "$NODE_MAJOR" -ge 18 ]; then
        print_pass "Node.js $NODE_VERSION (compatible)"
    else
        print_warn "Node.js $NODE_VERSION (v18+ recommended)"
    fi
else
    print_warn "Node.js not found (needed for frontend development)"
    print_info "Install from: https://nodejs.org"
fi

# Test 10: Project structure
print_test "Project structure validation"
REQUIRED_DIRS=("../contracts/meltyfi" "../frontend" "../scripts")
MISSING_DIRS=()

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        MISSING_DIRS+=("$dir")
    fi
done

if [ ${#MISSING_DIRS[@]} -eq 0 ]; then
    print_pass "All required directories present"
else
    print_fail "Missing directories: ${MISSING_DIRS[*]}"
fi

# Test 11: Frontend configuration
print_test "Frontend configuration for testnet"
FRONTEND_ENV="../frontend/.env.local"
if [ -f "$FRONTEND_ENV" ]; then
    if grep -q "testnet" "$FRONTEND_ENV"; then
        print_pass "Frontend configured for testnet"
    else
        print_warn "Frontend may not be configured for testnet"
    fi
else
    print_warn "Frontend .env.local not found (will be created during deployment)"
fi

# Test 12: RPC endpoint validation
print_test "Testnet RPC endpoint"
if command -v curl &> /dev/null; then
    if curl -s --connect-timeout 5 "https://fullnode.testnet.sui.io:443" > /dev/null; then
        print_pass "Testnet RPC endpoint accessible"
    else
        print_warn "Cannot reach testnet RPC endpoint"
        print_info "Check internet connection or try later"
    fi
else
    print_warn "curl not available, cannot test RPC endpoint"
fi

# Summary
echo
echo "═══════════════════════════════════════"
echo "🎯 Testnet Validation Summary"
echo "═══════════════════════════════════════"
echo -e "✅ Passed:   ${GREEN}$PASSED${NC}"
echo -e "⚠️  Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "❌ Failed:   ${RED}$FAILED${NC}"
echo "═══════════════════════════════════════"

if [ "$FAILED" -eq 0 ]; then
    if [ "$WARNINGS" -eq 0 ]; then
        echo -e "${GREEN}🎉 Perfect! Your environment is ready for MeltyFi testnet deployment.${NC}"
        echo -e "${GREEN}Run: ./scripts/deployment.sh${NC}"
    else
        echo -e "${YELLOW}✨ Good! Your environment is mostly ready for testnet.${NC}"
        echo -e "${YELLOW}Address the warnings above for the best experience.${NC}"
        echo -e "${GREEN}Run: ./scripts/deployment.sh${NC}"
    fi
else
    echo -e "${RED}❌ Issues found! Please fix the failed tests before deployment.${NC}"
    echo
    echo "Quick fixes:"
    echo "1. Run setup script: ./scripts/sui_setup.sh"
    echo "2. Get testnet SUI: https://faucet.testnet.sui.io"
    echo "3. Install missing tools as indicated above"
    echo "4. Switch to testnet: sui client switch --env testnet"
fi

echo
echo "For detailed setup, run: ./scripts/sui_setup.sh"
echo "For deployment, run: ./scripts/deployment.sh"
echo "Testnet faucet: https://faucet.testnet.sui.io"