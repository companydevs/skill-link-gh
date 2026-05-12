#!/bin/bash

echo "========================================"
echo "SkillLink APK Build Status Checker"
echo "========================================"
echo ""

cd frontend

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$APK_PATH" ]; then
    echo "[SUCCESS] APK Build Complete!"
    echo ""
    echo "APK Location:"
    echo "$(pwd)/$APK_PATH"
    echo ""
    
    SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo "APK Size: $SIZE"
    echo ""
    
    echo "You can now:"
    echo "1. Install on device: adb install $APK_PATH"
    echo "2. Share the APK file with testers"
    echo "3. Upload to Firebase App Distribution"
    echo ""
else
    echo "[WAITING] APK not found yet..."
    echo ""
    echo "The build may still be in progress."
    echo "Check your terminal where you ran 'flutter build apk --release'"
    echo ""
    echo "Expected location:"
    echo "$(pwd)/$APK_PATH"
    echo ""
fi
