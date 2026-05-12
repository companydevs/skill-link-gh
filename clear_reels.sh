#!/bin/bash

# Clear All Reels from Firestore
# This script deletes all documents from the 'reels' collection
# Use this to clean up test/development reels before production

echo ""
echo "🔥 Clear Reels Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null
then
    echo "❌ Firebase CLI is not installed!"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null
then
    echo "❌ Node.js is not installed!"
    echo "Please install Node.js first"
    exit 1
fi

# Check if firebase-admin is installed
if ! npm list firebase-admin &> /dev/null
then
    echo "📦 Installing firebase-admin..."
    npm install firebase-admin
fi

echo "🔍 Checking Firebase connection..."
echo ""

# Run the Node.js script
node clear_reels.js

echo ""
echo "✨ Done!"
echo ""
