# 🚨 IMMEDIATE SECURITY ACTIONS - DO THIS NOW!

## ⚠️ YOUR API KEYS ARE PUBLICLY EXPOSED ON GITHUB!

GitHub detected these keys in your public repository:
- Google Maps API Key
- Firebase API Keys (Android & Web)

**ANYONE can use these keys right now to:**
- Make unlimited Google Maps API calls (cost you money)
- Access your Firebase project
- Potentially access user data

---

## 🔴 STEP 1: REVOKE KEYS (DO THIS FIRST - 5 MINUTES)

### A. Google Maps API Key

1. Go to: https://console.cloud.google.com/google/maps-apis/credentials
2. Find key: `...ZWc` (ends with ZWc)
3. Click the ⋮ menu → **Delete**
4. Create NEW key with restrictions:
   - **Application restrictions**: Android apps
   - **API restrictions**: Maps SDK for Android, Geocoding API, Distance Matrix API
   - **Android app restrictions**: Add your package name and SHA-1 fingerprint

### B. Firebase Android Key

1. Go to: https://console.firebase.google.com/project/skill-link-gh/settings/general
2. Scroll to "Your apps" → Android app
3. Click ⚙️ → Download new `google-services.json`
4. Replace the file locally (DO NOT commit yet!)

### C. Firebase Web Key

1. Same Firebase Console page
2. Web app section
3. Regenerate config
4. Update locally (DO NOT commit!)

---

## 🔴 STEP 2: RESTRICT API KEYS (CRITICAL - 5 MINUTES)

### Google Maps API Restrictions:

**Application Restrictions:**
- Select: "Android apps"
- Add your SHA-1 fingerprint:
  ```bash
  # Get your SHA-1
  cd frontend/android
  ./gradlew signingReport
  ```

**API Restrictions:**
- Enable ONLY these APIs:
  - ✅ Maps SDK for Android
  - ✅ Geocoding API
  - ✅ Distance Matrix API
  - ✅ Places API
  - ❌ Disable all others

**Usage Quotas:**
- Set daily quota: 1,000 requests/day (adjust based on needs)
- Set monthly budget alert: $50/month

### Firebase API Restrictions:

**In Firebase Console:**
1. Go to Authentication → Settings
2. Add authorized domains:
   - `skilllink-gh-web.web.app`
   - `localhost` (for development)
3. Remove any unknown domains

**In Google Cloud Console:**
1. Go to: https://console.cloud.google.com/apis/credentials
2. Find Firebase API keys
3. Add HTTP referrer restrictions:
   - `https://skilllink-gh-web.web.app/*`
   - `http://localhost:*` (development only)

---

## 🔴 STEP 3: REMOVE FROM GITHUB (10 MINUTES)

### Option A: Simple Fix (Recommended if few commits)

1. **Remove keys from code:**
   ```bash
   # Open these files and replace keys with placeholders
   # frontend/lib/firebase_options.dart
   # frontend/android/app/src/main/AndroidManifest.xml
   # frontend/lib/presentation/booking_tracking_screen/booking_tracking_screen.dart
   # And others found in grep search
   ```

2. **Update .gitignore:**
   Already done ✅ (check your `.gitignore` file)

3. **Commit and push:**
   ```bash
   git add .
   git commit -m "security: remove exposed API keys"
   git push origin main
   ```

### Option B: Remove from Git History (If many commits)

Run the script:
```bash
remove-keys-from-history.bat
```

---

## 🔴 STEP 4: USE ENVIRONMENT VARIABLES (15 MINUTES)

### For Flutter (frontend):

1. **Create `frontend/lib/config/api_keys.dart`:**
   ```dart
   class ApiKeys {
     static const String googleMapsApiKey = String.fromEnvironment(
       'GOOGLE_MAPS_API_KEY',
       defaultValue: 'YOUR_DEV_KEY_HERE',
     );
   }
   ```

2. **Update AndroidManifest.xml:**
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="${GOOGLE_MAPS_API_KEY}" />
   ```

3. **Update build.gradle:**
   ```gradle
   android {
       defaultConfig {
           manifestPlaceholders = [
               GOOGLE_MAPS_API_KEY: project.findProperty("GOOGLE_MAPS_API_KEY") ?: ""
           ]
       }
   }
   ```

4. **Create `frontend/android/local.properties`:**
   ```properties
   GOOGLE_MAPS_API_KEY=your_new_key_here
   ```

5. **Add to `.gitignore`:**
   Already done ✅

### For Admin Panel (Node.js):

1. **Create `admin_panel/.env`:**
   ```bash
   VITE_FIREBASE_API_KEY=your_new_key_here
   VITE_FIREBASE_AUTH_DOMAIN=skill-link-gh.firebaseapp.com
   VITE_FIREBASE_PROJECT_ID=skill-link-gh
   ```

2. **Update `admin_panel/src/lib/firebase.ts`:**
   ```typescript
   const firebaseConfig = {
     apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
     authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
     projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
   };
   ```

---

## 🔴 STEP 5: MONITOR FOR UNAUTHORIZED USAGE (5 MINUTES)

### Google Cloud Console:

1. Go to: https://console.cloud.google.com/apis/dashboard
2. Check "Metrics" for unusual spikes
3. Set up billing alerts: https://console.cloud.google.com/billing

### Firebase Console:

1. Go to: https://console.firebase.google.com/project/skill-link-gh/usage
2. Check Authentication, Firestore, Storage usage
3. Set up budget alerts

---

## ✅ VERIFICATION CHECKLIST

After completing all steps:

- [ ] Old Google Maps API key deleted
- [ ] New Google Maps API key created with restrictions
- [ ] Firebase keys regenerated
- [ ] API restrictions applied (authorized domains, HTTP referrers)
- [ ] Keys removed from all code files
- [ ] `.gitignore` updated
- [ ] Environment variables setup complete
- [ ] Code committed without keys
- [ ] Git history cleaned (if needed)
- [ ] Monitoring/alerts configured
- [ ] No unusual API usage detected

---

## 📞 IF YOU'VE BEEN CHARGED

If you see unexpected charges from Google Cloud:

1. Contact Google Cloud Billing Support: https://cloud.google.com/support
2. Explain that your API key was compromised
3. Request a refund for fraudulent usage
4. Show evidence: GitHub security alert, timeline of key rotation

Google usually refunds charges from compromised keys if you act quickly!

---

## 🔐 PREVENT FUTURE LEAKS

1. **Use git-secrets:**
   ```bash
   # Install git-secrets
   git secrets --install
   git secrets --register-aws
   git secrets --add 'AIza[0-9A-Za-z_-]{35}'
   ```

2. **Use pre-commit hooks:**
   Install tools that scan for secrets before commits

3. **Never commit:**
   - `google-services.json`
   - `GoogleService-Info.plist`
   - `.env` files
   - Any file with "secret", "key", "password" in the name

---

## ⏰ TIME ESTIMATE

- Revoke keys: 5 min ⚠️ URGENT
- Restrict keys: 5 min ⚠️ URGENT
- Remove from GitHub: 10 min
- Setup env variables: 15 min
- Monitor usage: 5 min

**Total: ~40 minutes to secure your project**

---

**DO THIS NOW! Every minute your keys are public, you're at risk!**
