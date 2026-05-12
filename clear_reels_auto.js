/**
 * Clear All Reels from Firestore (Auto Mode)
 * 
 * This script automatically deletes all documents from the 'reels' collection
 * NO CONFIRMATION REQUIRED - Use with caution!
 * 
 * Usage: node clear_reels_auto.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./backend/firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function clearReels() {
  try {
    console.log('\n🔍 Checking reels collection...\n');
    
    // Get all reels
    const reelsSnapshot = await db.collection('reels').get();
    const totalReels = reelsSnapshot.size;
    
    if (totalReels === 0) {
      console.log('✅ No reels found. Collection is already empty.\n');
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
    console.log('\n🗑️  Deleting all reels (auto mode - no confirmation)...\n');
    
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
    
    process.exit(0);
    
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error('\nFull error:', error);
    process.exit(1);
  }
}

// Run the script
console.log('\n🔥 Clear Reels Script (Auto Mode)');
console.log('━'.repeat(60));
console.log('⚠️  This will delete ALL reels without confirmation!');
console.log('━'.repeat(60));

clearReels();
