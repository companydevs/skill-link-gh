@echo off
echo ========================================
echo SkillLink APK Build Status Checker
echo ========================================
echo.

cd frontend

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo [SUCCESS] APK Build Complete!
    echo.
    echo APK Location:
    echo %CD%\build\app\outputs\flutter-apk\app-release.apk
    echo.
    
    for %%A in ("build\app\outputs\flutter-apk\app-release.apk") do (
        set size=%%~zA
        set /a sizeMB=!size! / 1048576
        echo APK Size: !sizeMB! MB
    )
    echo.
    echo You can now:
    echo 1. Install on device: adb install build\app\outputs\flutter-apk\app-release.apk
    echo 2. Share the APK file with testers
    echo 3. Upload to Firebase App Distribution
    echo.
    pause
) else (
    echo [WAITING] APK not found yet...
    echo.
    echo The build may still be in progress.
    echo Check your terminal where you ran "flutter build apk --release"
    echo.
    echo Expected location:
    echo %CD%\build\app\outputs\flutter-apk\app-release.apk
    echo.
    pause
)
