# Build Production APK for SkillLink

## Current Build Status
The production APK build has been initiated. It may take 5-10 minutes to complete depending on your system.

## Check Build Progress

Open a terminal in the `frontend` directory and the build should still be running. Wait for it to complete.

Once done, you'll see:
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (XX.XMB)
```

## APK Location

After successful build, your APK will be at:
```
frontend/build/app/outputs/flutter-apk/app-release.apk
```

## Current Configuration

**App Details:**
- **Package Name:** `com.tongitech.skill_link_gh`
- **Version:** 1.0.0+1
- **Signing:** Debug keys (suitable for testing, NOT for Play Store)

## For Play Store Release (Proper Signing)

To create a properly signed APK for Google Play Store:

### Step 1: Generate Upload Keystore

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Save this information securely:**
- Keystore password
- Key alias: `upload`
- Key password

### Step 2: Create key.properties

Create `frontend/android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:/path/to/upload-keystore.jks
```

**⚠️ IMPORTANT:** Add `key.properties` to `.gitignore` - NEVER commit this file!

### Step 3: Update build.gradle.kts

Replace the signing configuration in `frontend/android/app/build.gradle.kts`:

```kotlin
// Add this before android block
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### Step 4: Build Signed APK

```bash
cd frontend
flutter build apk --release
```

### Step 5: Build App Bundle (Recommended for Play Store)

```bash
flutter build appbundle --release
```

The app bundle will be at:
```
frontend/build/app/outputs/bundle/release/app-release.aab
```

## Testing the APK

### Install on Device

```bash
# Via ADB
adb install frontend/build/app/outputs/flutter-apk/app-release.apk

# Or transfer to phone and install manually
```

### Share APK

The APK file can be:
- Shared via WhatsApp, email, or cloud storage
- Uploaded to Firebase App Distribution
- Distributed via APKPure, APKMirror (for testing)

## APK vs App Bundle

**APK (app-release.apk):**
- ✅ Can be installed directly on any Android device
- ✅ Good for testing and direct distribution
- ❌ Larger file size (contains all architectures)
- ❌ Not optimized for Play Store

**App Bundle (app-release.aab):**
- ✅ Required for Google Play Store (since Aug 2021)
- ✅ Smaller downloads (Google generates optimized APKs)
- ✅ Supports dynamic delivery
- ❌ Cannot be installed directly (Play Store only)

## Pre-Launch Checklist

Before distributing:

- [ ] Test on multiple devices (different Android versions)
- [ ] Verify all features work (reels, booking, messaging, payments)
- [ ] Check Firebase configuration is correct
- [ ] Test as both artisan and client
- [ ] Verify admin panel access
- [ ] Test payment integration (Paystack)
- [ ] Check location permissions and maps
- [ ] Test video upload and compression
- [ ] Verify push notifications work
- [ ] Check app doesn't crash on startup

## Version Management

To update version for new releases, edit `frontend/pubspec.yaml`:

```yaml
version: 1.0.1+2  # Format: major.minor.patch+buildNumber
```

Then rebuild:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## Troubleshooting

### Build Fails

```bash
# Clean and retry
flutter clean
flutter pub get
flutter build apk --release --verbose
```

### APK Too Large

```bash
# Build split APKs per architecture
flutter build apk --split-per-abi
```

This creates 3 APKs:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit Intel)

### Signing Errors

- Verify `key.properties` path is correct
- Check keystore password is correct
- Ensure keystore file exists

## Distribution Options

### 1. Direct Distribution (Current APK)
- Share APK file directly
- Users enable "Install from Unknown Sources"
- Good for beta testing

### 2. Firebase App Distribution
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Deploy
firebase appdistribution:distribute frontend/build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups testers
```

### 3. Google Play Store
- Create developer account ($25 one-time fee)
- Upload app bundle (`.aab` file)
- Complete store listing
- Submit for review

### 4. Alternative App Stores
- Amazon Appstore
- Samsung Galaxy Store
- Huawei AppGallery

## Current Build Command

The build was started with:
```bash
cd frontend
flutter clean
flutter pub get
flutter build apk --release
```

**Wait for it to complete, then check:**
```
frontend/build/app/outputs/flutter-apk/app-release.apk
```

## Next Steps

1. ✅ Wait for current build to complete
2. ⏳ Test the APK on your device
3. ⏳ If satisfied, create proper signing keys for Play Store
4. ⏳ Build signed app bundle
5. ⏳ Submit to Google Play Store

---

**Note:** The current APK is signed with debug keys. It works perfectly for testing and direct distribution, but you'll need proper signing for Play Store submission.
