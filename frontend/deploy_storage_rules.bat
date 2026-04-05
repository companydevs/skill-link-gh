@echo off
echo Deploying Firebase Storage rules...
firebase deploy --only storage
echo.
echo Storage rules deployed successfully!
echo.
echo Note: Make sure you have:
echo 1. Firebase CLI installed (npm install -g firebase-tools)
echo 2. Logged in to Firebase (firebase login)
echo 3. Project initialized (firebase init)
echo.
pause