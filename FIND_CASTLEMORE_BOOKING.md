# Find Castlemore's Missing Booking

## The Problem

- ✅ **Sympul Shop** (client) booked Masonry service on 2026-07-23 → Shows in their bookings
- ❌ **CastleMore** (artisan) completed the work → Does NOT show in their bookings

**Root Cause**: The booking document's `artisanId` field is likely **empty** or **wrong**.

---

## Step 1: Find the Booking in Firestore Console

1. Go to: https://console.firebase.google.com/project/skill-link-gh/firestore/databases/-default-/data/~2Fbookings

2. Look for a booking with:
   - **serviceTitle**: `Masonry`
   - **scheduledDate**: `2026-07-23`
   - **scheduledTime**: `11:00 AM`
   - **totalWithFees**: `17424.00`
   - **status**: `completed`

3. Click on the booking document ID

---

## Step 2: Check the artisanId Field

The booking document should look like:

```
artisanId: "7zs2TWPgPkcwdXLiXOJyqdvOXAG3"  ← Castlemore's UID
clientId: "<sympul_shop_uid>"
serviceTitle: "Masonry"
scheduledDate: "2026-07-23"
scheduledTime: "11:00 AM"
status: "completed"
bookingReference: "BK-..."
totalWithFees: 17424
```

---

## Step 3: Diagnose the Problem

### ❌ **Problem A: artisanId is Empty or Missing**

```
artisanId: ""  ← EMPTY!
or
(field doesn't exist at all)
```

**Why**: When Sympul Shop created the booking, the artisan selection didn't work properly.

**Fix**:
1. In Firestore Console, click on the booking document
2. If `artisanId` field exists but is empty:
   - Click the **Edit** icon next to the field
   - Change value to: `7zs2TWPgPkcwdXLiXOJyqdvOXAG3`
   - Click **Update**

3. If `artisanId` field doesn't exist:
   - Click **Add Field**
   - Field name: `artisanId`
   - Field type: `string`
   - Value: `7zs2TWPgPkcwdXLiXOJyqdvOXAG3`
   - Click **Add**

---

### ❌ **Problem B: artisanId has Wrong UID**

```
artisanId: "xyz789abc"  ← Not Castlemore's UID
```

**Why**: Booking was created for a different artisan (or test data).

**Fix**:
1. Click the **Edit** icon next to `artisanId` field
2. Change value to: `7zs2TWPgPkcwdXLiXOJyqdvOXAG3`
3. Click **Update**

---

### ❌ **Problem C: Castlemore is the Client, Not Artisan**

```
artisanId: "<someone_else>"
clientId: "7zs2TWPgPkcwdXLiXOJyqdvOXAG3"  ← Castlemore as client
```

**Why**: Castlemore BOOKED someone else's service (they're the client, not the artisan doing the work).

**Fix**: This is expected! Castlemore won't see this in their "artisan bookings" because they didn't do the work. They'll see it in their "client bookings" instead.

---

### ❌ **Problem D: Status is Not "completed"**

```
status: "in_progress"  ← Not completed yet
```

**Why**: The completion flow (QR scan or manual completion) didn't update the status.

**Fix**:
1. Click the **Edit** icon next to `status` field
2. Change value to: `completed`
3. Click **Update**

---

## Step 4: Test After Fix

1. **Close the app completely** (kill the process from app switcher)
2. **Reopen the app**
3. Log in as **CastleMore**
4. Go to **Profile → Bookings → Completed** tab
5. You should now see the Masonry booking ✅

---

## Step 5: Verify the Fix Worked

Check the logs in Android Studio / Xcode console:

```
🔍 Loading bookings for user: 7zs2TWPgPkcwdXLiXOJyqdvOXAG3
🔍 Role from Firestore: artisan
🔍 Will query field: artisanId
🔄 Getting user bookings: artisan
🔍 Querying bookings where artisanId == 7zs2TWPgPkcwdXLiXOJyqdvOXAG3
🔍 Found 1 booking documents  ← Should be 1 or more
📋 Booking <id>: status=completed, artisanId=7zs2TWPgPkcwdXLiXOJyqdvOXAG3
✅ Retrieved 1 bookings
```

If you see `Found 1 booking documents` → **FIXED!** ✅

If you still see `Found 0 booking documents` → artisanId is still wrong or empty.

---

## What to Send Back

**Please copy and paste the booking document fields here:**

Go to Firestore Console → find the Masonry booking → copy all fields (like you did for Castlemore's user document).

Example format:
```
artisanId: "7zs2TWPgPkcwdXLiXOJyqdvOXAG3"
clientId: "abc123xyz"
serviceTitle: "Masonry"
scheduledDate: "2026-07-23"
scheduledTime: "11:00 AM"
status: "completed"
bookingReference: "BK-123456"
totalWithFees: 17424
createdAt: July 23, 2026...
updatedAt: July 23, 2026...
```

Once you paste it, I can tell you **exactly** what's wrong and how to fix it.

---

## Quick Summary

**The Query**: `bookings.where('artisanId', '==', '7zs2TWPgPkcwdXLiXOJyqdvOXAG3')`

**What's Needed**: A booking document with:
- `artisanId`: `"7zs2TWPgPkcwdXLiXOJyqdvOXAG3"` (Castlemore's UID)
- `status`: `"completed"`

**If artisanId is wrong/empty** → No match → Empty list → "No bookings yet"

**Fix artisanId in Firestore** → Query matches → Booking appears ✅
