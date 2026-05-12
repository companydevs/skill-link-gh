@echo off
REM Deploy Firestore Rules Script for Windows
REM This script deploys the Firestore security rules to fix the Messages tab issue

echo 🔥 Deploying Firestore Security Rules...
echo.

REM Check if Firebase CLI is installed
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Firebase CLI is not installed!
    echo Install it with: npm install -g firebase-tools
    exit /b 1
)

REM Deploy rules
echo Deploying firestore.rules...
firebase deploy --only firestore:rules

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Firestore rules deployed successfully!
    echo.
    echo Next steps:
    echo 1. Run the Flutter app: cd frontend ^&^& flutter run
    echo 2. Tap the Messages tab
    echo 3. Check the console for debug logs
) else (
    echo.
    echo ❌ Failed to deploy Firestore rules
    echo Check the error message above
    exit /b 1
)
