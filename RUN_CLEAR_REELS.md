# Ready to Clear Reels! 🗑️

Everything is set up. Here's what to do:

## Run the Script

Open a **new terminal** (not in Kiro) and run:

```bash
node clear_reels.js
```

## What Will Happen

1. The script will connect to Firebase
2. Show you how many reels exist
3. Display a sample of reels to be deleted
4. Ask for confirmation: **Type `yes` to proceed**
5. Delete all reels in batches
6. Show a summary when complete

## Example:

```
🔍 Checking reels collection...

📊 Found 15 reels in the collection

Sample of reels to be deleted:
────────────────────────────────────────────────────────────
1. ID: abc123
   Artisan: John Doe
   Caption: Test reel for plumbing services...
   Created: Mon May 11 2026

⚠️  WARNING: This action cannot be undone!

Are you sure you want to delete ALL reels? (yes/no): 
```

**Type `yes` and press Enter** to delete all reels.

## After Deletion

✅ All test reels will be removed  
✅ Reels collection will be empty  
✅ Ready for production reels  

## Verify

Check Firebase Console:
https://console.firebase.google.com/project/skill-link-gh/firestore/databases/-default-/data/~2Freels

Should show "No documents" or empty collection.

---

**Ready?** Open a terminal and run: `node clear_reels.js`
