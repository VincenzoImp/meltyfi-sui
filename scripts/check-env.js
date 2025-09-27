const fs = require('fs');
const path = require('path');

function checkEnvironmentConfiguration() {
    console.log('🔍 Checking MeltyFi environment configuration...\n');

    const envFile = path.join(process.cwd(), '.env.local');
    const envExampleFile = path.join(process.cwd(), '.env.example');

    // Check if environment files exist
    const hasEnvFile = fs.existsSync(envFile);
    const hasEnvExample = fs.existsSync(envExampleFile);

    console.log(`📄 .env.local file: ${hasEnvFile ? '✅ Found' : '❌ Missing'}`);
    console.log(`📄 .env.example file: ${hasEnvExample ? '✅ Found' : '❌ Missing'}`);

    if (!hasEnvFile) {
        console.log('\n⚠️  Environment file missing. Creating from example...');
        if (hasEnvExample) {
            fs.copyFileSync(envExampleFile, envFile);
            console.log('✅ Created .env.local from .env.example');
        } else {
            createDefaultEnvFile(envFile);
            console.log('✅ Created default .env.local file');
        }
    }

    // Read and validate environment variables
    const envContent = fs.readFileSync(envFile, 'utf8');
    const envVars = parseEnvFile(envContent);

    console.log('\n🔧 Environment Variables Status:');

    const requiredVars = {
        'NEXT_PUBLIC_SUI_NETWORK': 'Network configuration',
        'NEXT_PUBLIC_SUI_RPC_URL': 'RPC endpoint',
        'NEXT_PUBLIC_MELTYFI_PACKAGE_ID': 'Contract package ID',
        'NEXT_PUBLIC_PROTOCOL_OBJECT_ID': 'Protocol object ID',
        'NEXT_PUBLIC_CHOCOLATE_FACTORY_ID': 'Chocolate factory ID',
        'NEXT_PUBLIC_CHOCO_CHIP_TYPE': 'ChocoChip token type',
        'NEXT_PUBLIC_WONKA_BAR_TYPE': 'WonkaBar token type'
    };

    let allConfigured = true;
    let contractsConfigured = true;

    Object.entries(requiredVars).forEach(([key, description]) => {
        const value = envVars[key];
        const isConfigured = value && value.trim() !== '' && !value.includes('your_') && !value.includes('0x123');

        if (key.includes('PACKAGE_ID') || key.includes('OBJECT_ID') || key.includes('FACTORY_ID') || key.includes('TYPE')) {
            contractsConfigured = contractsConfigured && isConfigured;
        }

        allConfigured = allConfigured && isConfigured;

        console.log(`  ${isConfigured ? '✅' : '❌'} ${key}: ${description}`);
        if (!isConfigured && value) {
            console.log(`     Current: ${value.slice(0, 50)}${value.length > 50 ? '...' : ''}`);
        }
    });

    console.log('\n📊 Configuration Summary:');
    console.log(`  Network: ${envVars.NEXT_PUBLIC_SUI_NETWORK || 'Not set'}`);
    console.log(`  RPC URL: ${envVars.NEXT_PUBLIC_SUI_RPC_URL || 'Not set'}`);
    console.log(`  Contracts: ${contractsConfigured ? '✅ Configured' : '❌ Not configured'}`);

    if (!contractsConfigured) {
        console.log('\n🚀 Next Steps:');
        console.log('  1. Deploy contracts to testnet:');
        console.log('     npm run deploy:full');
        console.log('  2. Or manually run:');
        console.log('     ./scripts/deployment.sh');
        console.log('  3. Contract addresses will be automatically updated in .env.local');
        console.log('\n💡 Need testnet SUI? Visit: https://faucet.testnet.sui.io');
    } else {
        console.log('\n✅ All environment variables are properly configured!');
        console.log('   You can now run: npm run dev');
    }

    return { allConfigured, contractsConfigured };
}

function parseEnvFile(content) {
    const vars = {};
    content.split('\n').forEach(line => {
        const trimmed = line.trim();
        if (trimmed && !trimmed.startsWith('#')) {
            const [key, ...valueParts] = trimmed.split('=');
            if (key && valueParts.length > 0) {
                vars[key.trim()] = valueParts.join('=').trim();
            }
        }
    });
    return vars;
}

function createDefaultEnvFile(filePath) {
    const defaultContent = `# MeltyFi Protocol - Sui Testnet Configuration
# Copy this file to .env.local and update with your deployed contract addresses

# Network Configuration
NEXT_PUBLIC_SUI_NETWORK=testnet
NEXT_PUBLIC_SUI_RPC_URL=https://fullnode.testnet.sui.io:443

# Contract Addresses (to be filled after deployment)
NEXT_PUBLIC_MELTYFI_PACKAGE_ID=
NEXT_PUBLIC_PROTOCOL_OBJECT_ID=
NEXT_PUBLIC_CHOCOLATE_FACTORY_ID=
NEXT_PUBLIC_ADMIN_CAP_ID=
NEXT_PUBLIC_FACTORY_ADMIN_ID=

# Token Types (auto-generated after deployment)
NEXT_PUBLIC_CHOCO_CHIP_TYPE=
NEXT_PUBLIC_WONKA_BAR_TYPE=

# Application Configuration
NEXT_PUBLIC_APP_NAME=MeltyFi
NEXT_PUBLIC_APP_DESCRIPTION=Sweet NFT Liquidity Protocol
NEXT_PUBLIC_DEBUG=true
NODE_ENV=development

# Explorer URLs
NEXT_PUBLIC_EXPLORER_URL=https://suiexplorer.com
`;

    fs.writeFileSync(filePath, defaultContent);
}

// Run the check if this script is executed directly
if (require.main === module) {
    checkEnvironmentConfiguration();
}

module.exports = { checkEnvironmentConfiguration };
