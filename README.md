# 🍫 MeltyFi on Sui

**Making the illiquid liquid** - MeltyFi protocol reimagined on Sui blockchain with Move smart contracts.

## 🏗️ Architecture

- **Smart Contracts**: Move language on Sui blockchain
- **Frontend**: Next.js 14 with TypeScript and Tailwind CSS  
- **Wallet Integration**: Sui dApp Kit with multiple wallet support
- **State Management**: React Query for blockchain state
- **UI Components**: Radix UI with custom styling

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Start local Sui validator
npm run start:validator

# Build contracts
npm run build:contracts

# Run contract tests
npm run test:contracts

# Start frontend development server
npm run dev:frontend
```

## 📂 Project Structure

```
meltyfi-sui-migration/
├── contracts/meltyfi_protocol/     # Move smart contracts
│   ├── sources/                    # Contract source code
│   ├── tests/                      # Contract tests
│   └── Move.toml                   # Move package configuration
├── frontend/                       # Next.js frontend
│   ├── src/                        # Frontend source code
│   └── package.json
├── .env                           # Environment variables
└── package.json                   # Project scripts
```

## 🧪 Testing

```bash
# Unit tests
npm run test:contracts

# Integration tests  
npm run test:integration

# Frontend tests
cd frontend && npm test
```

## 🚀 Deployment

```bash
# Deploy to devnet
npm run deploy:devnet

# Build frontend for production
npm run build:frontend
```
