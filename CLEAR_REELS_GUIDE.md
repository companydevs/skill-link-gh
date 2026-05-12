# Clear Reels - Production Preparation Guide

## Overview

This guide helps you safely delete all test/development reels from Firestore before uploading production reels.

## ⚠️ Important Warnings

1. **This action is IRREVERSIBLE** - Deleted reels cannot be recovered
2. **Backup first** if you need to keep any test data
3. **All reels will be deleted** - there's no selective deletion
4. **Comments and likes** on reels will remain in the database (orphaned)

## Prerequisites

- Node.js installed
- Firebase Admin SDK access
- `firebase-service-account.json` in the `backend` folder

## Method 1: Using the Script (Recommended)

### Step 1: Install Dependencies

```bash
npm install firebase-admin
```

### Step 2: Run the Clear Script

**Windows:**
```bash
clear_reels.bat
```

**Mac/Linux:**
```bash
bash clear_reels.sh
```

**Or directly with Node:**
```bash
node clear_reels.js
```

### Step 3: Confirm Deletion

The script will:
1. Show you how many reels exist
2. Display a sample of reels to be deleted
3. Ask for confirmation (type `yes` to proceed)
4. Delete all reels in batches
5. Show a summary when complete

### Example Output:

```
🔍 Checking reels collection...

📊 Found 15 reels in the collection

Sample of reels to be deleted:
────────────────────────────────────────────────────────────
1. ID: abc123
   Artisan: John Doe
   Caption: Test reel for plumbing services...
   Created: Mon May 11 2026

... and 10 more reels

────────────────────────────────────────────────────────────

⚠️  WARNING: This action cannot be undone!

Are you sure you want to delete ALL reels? (yes/no): yes

🗑️  Deleting reels...

   Deleted 15 / 15 reels...

✅ Successfully deleted all reels!

📝 Summary:
   Total reels deleted: 15
   Collection: reels
   Status: Empty and ready for production reels
```

## Method 2: Using Firebase Console (Manual)

If you prefer a visual approach:

1. Go to [Firebase Console](https://console.firebase.google.com/project/skill-link-gh/firestore)
2. Navigate to Firestore Database
3. Find the `reels` collection
4. Click on each document and delete it
5. **Note**: This is tedious for many reels!

## Method 3: Using Firebase CLI

```bash
# Delete the entire collection (requires Firebase CLI)
firebase firestore:delete reels --recursive --yes
```

## After Clearing Reels

### Verify Deletion

1. Check Firebase Console → Firestore → `reels` collection
2. Should show "No documents" or collection shouldn't exist
3. Open your app and go to Reels tab - should show empty state

### Upload Production Reels

Now you can upload production-ready reels:

1. **From the app**: Use the create reel feature
2. **Bulk upload**: Use a script to upload multiple reels
3. **Manual**: Add documents directly in Firebase Console

## Optional: Clean Up Related Data

You may also want to clean up:

### 1. Reel Comments
```javascript
// Add to clear_reels.js if needed
const reelsSnapshot = await db.collection('reels').get();
for (const doc of reelsSnapshot.docs) {
  const commentsSnapshot = await doc.ref.collection('comments').get();
  const batch = db.batch();
  commentsSnapshot.docs.forEach(comment => batch.delete(comment.ref));
  await batch.commit();
}
```

### 2. User Interactions (Likes, Views)
If you're tracking reel interactions separately, you may want to clear those too.

### 3. Storage Files
Reel videos are stored in Firebase Storage. To delete them:

```bash
# List all reel videos
gsutil ls gs://skill-link-gh.appspot.com/reels/

# Delete all reel videos (CAREFUL!)
gsutil -m rm -r gs://skill-link-gh.appspot.com/reels/**
```

**⚠️ WARNING**: This will delete the actual video files!

## Troubleshooting

### Error: "Cannot find module 'firebase-admin'"
```bash
npm install firebase-admin
```

### Error: "Service account file not found"
Make sure `backend/firebase-service-account.json` exists.

### Error: "Permission denied"
Check that your service account has Firestore write permissions.

### Script hangs or times out
- Check your internet connection
- Verify Firebase project is accessible
- Try deleting in smaller batches

## Safety Checklist

Before running the script:

- [ ] Backed up any reels you want to keep
- [ ] Confirmed this is the correct Firebase project
- [ ] Verified you have the service account file
- [ ] Understand this action is irreversible
- [ ] Ready to upload production reels

## Quick Start (TL;DR)

```bash
# Install dependencies
npm install firebase-admin

# Run the script
node clear_reels.js

# Type 'yes' when prompted

# Verify in Firebase Console
```

---

**Project**: skill-link-gh  
**Collection**: reels  
**Action**: Delete all documents  
**Reversible**: ❌ No  
**Backup**: Recommended before proceeding
