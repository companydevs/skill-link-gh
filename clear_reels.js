/**
 * Clear All Reels from Firestore
 * 
 * This script deletes all documents from the 'reels' collection
 * Use this to clean up test/development reels before production
 * 
 * Usage: node clear_reels.js
 */

const admin = require('firebase-admin');
const readline = require('readline');

// Initialize Firebase Admin
const serviceAccount = require('./backend/firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Create readline interface for confirmation
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function clearReels() {
  try {
    console.log('\n🔍 Checking reels collection...\n');
    
    // Get all reels
    const reelsSnapshot = await db.collection('reels').get();
    const totalReels = reelsSnapshot.size;
    
    if (totalReels === 0) {
      console.log('✅ No reels found. Collection is already empty.\n');
      rl.close();
      process.exit(0);
      return;
    }
    
    console.log(`📊 Found ${totalReels} reels in the collection\n`);
    
    // Show sample of reels to be deleted
    console.log('Sample of reels to be deleted:');
    console.log('─'.repeat(60));
    
    reelsSnapshot.docs.slice(0, 5).forEach((doc, index) => {
      const data = doc.data();
      console.log(`${index + 1}. ID: ${doc.id}`);
      console.log(`   Artisan: ${data.artisanName || 'Unknown'}`);
      console.log(`   Caption: ${(data.caption || '').substring(0, 50)}...`);
      console.log(`   Created: ${data.createdAt?.toDate?.() || 'Unknown'}`);
      console.log('');
    });
    
    if (totalReels > 5) {
      console.log(`... and ${totalReels - 5} more reels\n`);
    }
    
    console.log('─'.repeat(60));
    console.log('\n⚠️  WARNING: This action cannot be undone!\n');
    
    // Ask for confirmation
    rl.question('Are you sure you want to delete ALL reels? (yes/no): ', async (answer) => {
      if (answer.toLowerCase() === 'yes') {
        console.log('\n🗑️  Deleting reels...\n');
        
        // Delete in batches of 500 (Firestore limit)
        const batchSize = 500;
        let deletedCount = 0;
        
        while (true) {
          const snapshot = await db.collection('reels').limit(batchSize).get();
          
          if (snapshot.empty) {
            break;
          }
          
          const batch = db.batch();
          snapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
          });
          
          await batch.commit();
          deletedCount += snapshot.size;
          
          console.log(`   Deleted ${deletedCount} / ${totalReels} reels...`);
          
          // Small delay to avoid rate limiting
          await new Promise(resolve => setTimeout(resolve, 100));
        }
        
        console.log('\n✅ Successfully deleted all reels!\n');
        console.log('📝 Summary:');
        console.log(`   Total reels deleted: ${deletedCount}`);
        console.log(`   Collection: reels`);
        console.log(`   Status: Empty and ready for production reels\n`);
        
      } else {
        console.log('\n❌ Operation cancelled. No reels were deleted.\n');
      }
      
      rl.close();
      process.exit(0);
    });
    
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error('\nFull error:', error);
    rl.close();
    process.exit(1);
  }
}

// Run the script
clearReels();
