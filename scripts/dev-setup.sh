#!/bin/bash
# Quick development environment setup

echo "🚀 Starting MeltyFi development environment..."

# Start Sui local validator in background
sui-test-validator &
VALIDATOR_PID=0
echo "📡 Local Sui validator started (PID: )"

# Build contracts
cd contracts/meltyfi
echo "🔨 Building Move contracts..."
sui move build --dev

# Start frontend development server
cd ../../frontend
echo "🌐 Starting Next.js development server..."
npm run dev &
FRONTEND_PID=0

echo "✅ Development environment ready!"
echo "- Sui validator running at http://localhost:9000"  
echo "- Frontend running at http://localhost:3000"
echo "- To stop: kill  "
