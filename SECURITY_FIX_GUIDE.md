# 🚨 SECURITY FIX: Remove Exposed API Keys from Git History

## The Problem

Google detected exposed API keys in your public GitHub repository. Even if you remove them now, they're still visible in Git commit history.

## IMMEDIATE ACTIONS

### 1. Revoke All Exposed Keys

**Google Maps API Key (PRIORITY 1):**
- Key: AIzaSyCeGxqoYlPBqAXDX5JMp89wwJfmQEM-ZWc
- Action: Delete and regenerate
- URL: https://console.cloud.google.com/google/maps-apis/credentials

**Firebase API Keys (PRIORITY 1):**
- Android: AIzaSyBQBpe_XlRPEcuTZKTz3YNJ8QwvnPLdAoc
- Web: AIzaSyAz-79s5Gi7H1iA61awMSC47KemjDmBLFk
- Action: Regenerate in Firebase Console
- URL: https://console.firebase.google.com/project/skill-link-gh/settings/general

### 2. Remove Keys from Git History

Option A: Use BFG Repo-Cleaner (Recommended - Fast)

# Install BFG (Windows)
# Download from: https://rtyley.github.io/bfg-repo-cleaner/

# Clone a fresh copy
git clone --mirror https://github.com/companydevs/skill-link-gh.git

# Remove all API keys from history
java -jar bfg.jar --replace-text passwords.txt skill-link-gh.git

# passwords.txt contains:
# AIzaSyCeGxqoYlPBqAXDX5JMp89wwJfmQEM-ZWc
# AIzaSyBQBpe_XlRPEcuTZKTz3YNJ8QwvnPLdAoc
# AIzaSyAz-79s5Gi7H1iA61awMSC47KemjDmBLFk

# Clean up
cd skill-link-gh.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push to GitHub
git push --force


Option B: Use git-filter-repo (Alternative)

# Install git-filter-repo
pip install git-filter-repo

# Replace all occurrences
git filter-repo --replace-text passwords.txt

# passwords.txt format:
# AIzaSyCeGxqoYlPBqAXDX5JMp89wwJfmQEM-ZWc==>YOUR_NEW_MAPS_KEY
# AIzaSyBQBpe_XlRPEcuTZKTz3YNJ8QwvnPLdAoc==>YOUR_NEW_FIREBASE_KEY
# AIzaSyAz-79s5Gi7H1iA61awMSC47KemjDmBLFk==>YOUR_NEW_WEB_KEY

# Force push
git push origin --force --all


### 3. Add .gitignore Rules

Add to `.gitignore`:

# Firebase configuration
google-services.json
GoogleService-Info.plist
firebase_options.dart

# Environment variables
.env
.env.local
.env.production

# API keys
**/api_keys.dart
**/secrets.dart


### 4. Use Environment Variables

Never hardcode API keys again. Use environment variables instead.

