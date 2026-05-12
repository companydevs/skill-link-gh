#!/bin/bash

# Deploy Firestore Rules Script
# This script deploys the Firestore security rules to fix the Messages tab issue

echo "🔥 Deploying Firestore Security Rules..."
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null
then
    echo "❌ Firebase CLI is not installed!"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

# Check if logged in
if ! firebase projects:list &> /dev/null
then
    echo "❌ Not logged in to Firebase!"
    echo "Run: firebase login"
    exit 1
fi

# Deploy rules
echo "Deploying firestore.rules..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Firestore rules deployed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Run the Flutter app: cd frontend && flutter run"
    echo "2. Tap the Messages tab"
    echo "3. Check the console for debug logs"
else
    echo ""
    echo "❌ Failed to deploy Firestore rules"
    echo "Check the error message above"
    exit 1
fi
