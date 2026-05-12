@echo off
REM Clear All Reels from Firestore
REM This script deletes all documents from the 'reels' collection
REM Use this to clean up test/development reels before production

echo.
echo 🔥 Clear Reels Script
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

REM Check if Firebase CLI is installed
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Firebase CLI is not installed!
    echo Install it with: npm install -g firebase-tools
    exit /b 1
)

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Node.js is not installed!
    echo Please install Node.js first
    exit /b 1
)

REM Check if firebase-admin is installed
npm list firebase-admin >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 📦 Installing firebase-admin...
    npm install firebase-admin
)

echo 🔍 Checking Firebase connection...
echo.

REM Run the Node.js script
node clear_reels.js

echo.
echo ✨ Done!
echo.
