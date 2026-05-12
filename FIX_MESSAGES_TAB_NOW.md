# Fix Messages Tab - Quick Start

## The Problem
Messages tab no dey work (not showing up or not functioning).

## The Solution (2 Steps)

### Step 1: Deploy Firestore Rules
Open your terminal in the project root and run:

**Windows (PowerShell or CMD):**
```bash
firebase deploy --only firestore:rules
```

**Mac/Linux:**
```bash
firebase deploy --only firestore:rules
```

**Alternative (using helper script):**
- Windows: Double-click `deploy-firestore-rules.bat`
- Mac/Linux: Run `bash deploy-firestore-rules.sh`

### Step 2: Test the App
```bash
cd frontend
flutter run
```

Then:
1. Tap the Messages tab (4th icon in bottom bar)
2. It should now work! 🎉

## What If It Still Doesn't Work?

Check the Flutter console for error messages:
- Look for lines starting with 🔄, 💬, or ❌
- Share those lines with me

## Common Issues

### "Firebase CLI not found"
Install it:
```bash
npm install -g firebase-tools
```

### "Not logged in to Firebase"
Login:
```bash
firebase login
```

### "Permission denied" error in app
Make sure you completed Step 1 (deploy rules).

### Messages tab shows "No messages yet"
This is **correct**! The tab is working. You just don't have any conversations yet.
- Tap "Find Artisans" to start a conversation

## Need More Help?
Read the detailed guide: `DEBUG_MESSAGES_TAB.md`

---

**TL;DR**: Run `firebase deploy --only firestore:rules` then test the app.
