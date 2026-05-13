/* eslint-disable max-len */
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import axios from "axios";

const db = getFirestore();

const PAYSTACK_SECRET_KEY =
  process.env.PAYSTACK_SECRET_KEY ||
  "sk_test_b85aba8a00d7e9d05a806d08c440af48193823b7";
const PAYSTACK_BASE_URL = "https://api.paystack.co";

// ─── Helpers ─────────────────────────────────────────────────────────────────

function generateReference(prefix: string): string {
  const ts = Date.now().toString().slice(-8);
  const rand = Math.random().toString(36).substring(2, 7).toUpperCase();
  return `${prefix}_${ts}_${rand}`;
}

async function getOrCreateWallet(uid: string): Promise<FirebaseFirestore.DocumentReference> {
  const ref = db.collection("wallets").doc(uid);
  const snap = await ref.get();
  if (!snap.exists) {
    await ref.set({balance: 0, createdAt: FieldValue.serverTimestamp()});
  }
  return ref;
}

// ─── initiateWalletTopUp ─────────────────────────────────────────────────────

/**
 * Initiates a Paystack payment to top up the user's wallet.
 * Returns { paymentUrl, reference }
 */
export const initiateWalletTopUp = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const uid = request.auth.uid;
  const amount = request.data?.amount as number;

  if (!amount || isNaN(amount) || amount < 1) {
    throw new HttpsError("invalid-argument", "amount must be >= 1 GHS");
  }

  // Fetch user email
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) {
    throw new HttpsError("not-found", "User profile not found");
  }
  const email: string = userDoc.data()?.email ?? `${uid}@wallet.skilllink.gh`;

  const reference = generateReference("WTOPUP");
  const amountInKobo = Math.round(amount * 100); // Paystack uses smallest currency unit

  // Create a pending transaction record first
  const walletRef = await getOrCreateWallet(uid);
  await walletRef.collection("transactions").add({
    type: "topUp",
    status: "pending",
    amount,
    description: `Wallet top-up of GHS ${amount.toFixed(2)}`,
    reference,
    createdAt: FieldValue.serverTimestamp(),
  });

  // Initialize Paystack transaction
  let paystackRes;
  try {
    paystackRes = await axios.post(
      `${PAYSTACK_BASE_URL}/transaction/initialize`,
      {
        email,
        amount: amountInKobo,
        reference,
        callback_url: "skilllink://wallet/topup",
        metadata: {
          uid,
          type: "wallet_topup",
          custom_fields: [
            {display_name: "Type", variable_name: "type", value: "Wallet Top-Up"},
          ],
        },
        channels: ["card", "bank", "ussd", "mobile_money", "bank_transfer"],
      },
      {
        headers: {
          Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
          "Content-Type": "application/json",
        },
      }
    );
  } catch (err: any) {
    console.error("Paystack init error:", err?.response?.data ?? err?.message);
    throw new HttpsError("internal", "Payment gateway error. Try again.");
  }

  if (!paystackRes.data?.status) {
    throw new HttpsError("internal", paystackRes.data?.message ?? "Paystack error");
  }

  return {
    paymentUrl: paystackRes.data.data.authorization_url as string,
    reference,
  };
});

// ─── verifyWalletTopUp ───────────────────────────────────────────────────────

/**
 * Verifies a Paystack top-up payment and credits the wallet.
 * Returns { success: boolean }
 */
export const verifyWalletTopUp = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const uid = request.auth.uid;
  const reference = request.data?.reference as string;

  if (!reference) {
    throw new HttpsError("invalid-argument", "reference is required");
  }

  // Verify with Paystack
  let paystackRes;
  try {
    paystackRes = await axios.get(
      `${PAYSTACK_BASE_URL}/transaction/verify/${reference}`,
      {headers: {Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`}}
    );
  } catch (err: any) {
    console.error("Paystack verify error:", err?.response?.data ?? err?.message);
    throw new HttpsError("internal", "Could not verify payment");
  }

  const txData = paystackRes.data?.data;
  const paid = txData?.status === "success";
  const amountGHS = (txData?.amount ?? 0) / 100;

  // Find the pending transaction doc
  const walletRef = await getOrCreateWallet(uid);
  const txSnap = await walletRef
    .collection("transactions")
    .where("reference", "==", reference)
    .limit(1)
    .get();

  if (txSnap.empty) {
    throw new HttpsError("not-found", "Transaction record not found");
  }

  const txDoc = txSnap.docs[0];

  // Guard against double-crediting
  if (txDoc.data().status === "success") {
    return {success: true}; // already processed
  }

  if (paid) {
    // Credit wallet atomically
    await db.runTransaction(async (t) => {
      t.update(walletRef, {
        balance: FieldValue.increment(amountGHS),
        updatedAt: FieldValue.serverTimestamp(),
      });
      t.update(txDoc.ref, {
        status: "success",
        amount: amountGHS,
        paidAt: FieldValue.serverTimestamp(),
      });
    });
  } else {
    await txDoc.ref.update({status: "failed"});
  }

  return {success: paid};
});

// ─── payWithWallet ───────────────────────────────────────────────────────────

/**
 * Deducts from the user's wallet balance to pay for a booking.
 * Returns { success: boolean }
 */
export const payWithWallet = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const uid = request.auth.uid;
  const {bookingId, amount} = request.data as {bookingId: string; amount: number};

  if (!bookingId || !amount || amount <= 0) {
    throw new HttpsError("invalid-argument", "bookingId and amount are required");
  }

  const walletRef = await getOrCreateWallet(uid);

  // Verify booking exists and belongs to user
  const bookingDoc = await db.collection("bookings").doc(bookingId).get();
  if (!bookingDoc.exists) {
    throw new HttpsError("not-found", "Booking not found");
  }
  if (bookingDoc.data()?.clientId !== uid) {
    throw new HttpsError("permission-denied", "Not your booking");
  }

  const reference = generateReference("WPAY");

  // Atomic deduct + record
  try {
    await db.runTransaction(async (t) => {
      const walletSnap = await t.get(walletRef);
      const balance: number = walletSnap.data()?.balance ?? 0;

      if (balance < amount) {
        throw new HttpsError("failed-precondition", "Insufficient wallet balance");
      }

      t.update(walletRef, {
        balance: FieldValue.increment(-amount),
        updatedAt: FieldValue.serverTimestamp(),
      });

      const txRef = walletRef.collection("transactions").doc();
      t.set(txRef, {
        type: "payment",
        status: "success",
        amount,
        description: `Payment for booking ${bookingId}`,
        reference,
        bookingId,
        createdAt: FieldValue.serverTimestamp(),
      });

      t.update(db.collection("bookings").doc(bookingId), {
        paymentStatus: "success",
        paymentMethod: "wallet",
        paymentReference: reference,
        status: "confirmed",
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    console.error("payWithWallet error:", err);
    throw new HttpsError("internal", "Payment failed. Try again.");
  }

  return {success: true, reference};
});

// ─── initiateWithdrawal ──────────────────────────────────────────────────────

/**
 * Artisan requests a withdrawal to mobile money or bank account.
 * Deducts from balance immediately, creates a pending payout record.
 * Returns { success: boolean, withdrawalId: string }
 */
export const initiateWithdrawal = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const uid = request.auth.uid;
  const {amount, method, accountNumber, accountName, network, bankCode, bankName} =
    request.data as {
      amount: number;
      method: "mobile_money" | "bank_transfer";
      accountNumber: string;
      accountName: string;
      network?: string;   // MTN, Vodafone, AirtelTigo
      bankCode?: string;
      bankName?: string;
    };

  // Validate inputs
  if (!amount || amount < 10) {
    throw new HttpsError("invalid-argument", "Minimum withdrawal is GHS 10");
  }
  if (!accountNumber || !accountName) {
    throw new HttpsError("invalid-argument", "Account details are required");
  }
  if (method === "mobile_money" && !network) {
    throw new HttpsError("invalid-argument", "Mobile network is required");
  }
  if (method === "bank_transfer" && !bankCode) {
    throw new HttpsError("invalid-argument", "Bank is required");
  }

  const walletRef = await getOrCreateWallet(uid);
  const reference = generateReference("WDRAW");

  // Atomic: check balance, deduct, create withdrawal record
  let withdrawalId = "";
  try {
    await db.runTransaction(async (t) => {
      const walletSnap = await t.get(walletRef);
      const balance: number = walletSnap.data()?.balance ?? 0;

      if (balance < amount) {
        throw new HttpsError(
          "failed-precondition",
          `Insufficient balance. Available: GHS ${balance.toFixed(2)}`
        );
      }

      // Deduct from wallet
      t.update(walletRef, {
        balance: FieldValue.increment(-amount),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Record withdrawal transaction
      const txRef = walletRef.collection("transactions").doc();
      t.set(txRef, {
        type: "withdrawal",
        status: "pending",
        amount,
        description: `Withdrawal to ${method === "mobile_money" ? `${network} ${accountNumber}` : `${bankName} ${accountNumber}`}`,
        reference,
        createdAt: FieldValue.serverTimestamp(),
      });

      // Create payout record for admin tracking
      const payoutRef = db.collection("payouts").doc();
      withdrawalId = payoutRef.id;
      t.set(payoutRef, {
        userId: uid,
        amount,
        method,
        accountNumber,
        accountName,
        network: network ?? null,
        bankCode: bankCode ?? null,
        bankName: bankName ?? null,
        reference,
        status: "pending",   // pending | processing | completed | failed
        adminNote: "",
        requestedAt: FieldValue.serverTimestamp(),
        processedAt: null,
      });
    });
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    console.error("initiateWithdrawal error:", err);
    throw new HttpsError("internal", "Withdrawal failed. Try again.");
  }

  // Attempt Paystack transfer (mobile money)
  if (method === "mobile_money") {
    try {
      // Create transfer recipient
      const recipientRes = await axios.post(
        `${PAYSTACK_BASE_URL}/transferrecipient`,
        {
          type: "mobile_money",
          name: accountName,
          account_number: accountNumber,
          bank_code: network === "MTN" ? "MTN" : network === "Vodafone" ? "VOD" : "ATL",
          currency: "GHS",
        },
        {headers: {Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`}}
      );

      const recipientCode = recipientRes.data?.data?.recipient_code;
      if (recipientCode) {
        // Initiate transfer
        await axios.post(
          `${PAYSTACK_BASE_URL}/transfer`,
          {
            source: "balance",
            amount: Math.round(amount * 100),
            recipient: recipientCode,
            reason: `SkillLink withdrawal - ${reference}`,
            reference,
          },
          {headers: {Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`}}
        );

        // Update payout status to processing
        await db.collection("payouts").doc(withdrawalId).update({
          status: "processing",
          recipientCode,
        });
      }
    } catch (paystackErr: any) {
      console.error("Paystack transfer error:", paystackErr?.response?.data ?? paystackErr?.message);
      // Don't fail — admin can process manually
      await db.collection("payouts").doc(withdrawalId).update({
        adminNote: "Paystack auto-transfer failed. Manual processing required.",
      });
    }
  }

  return {success: true, withdrawalId, reference};
});

// ─── getWithdrawalHistory ────────────────────────────────────────────────────

/**
 * Returns the artisan's withdrawal history.
 */
export const getWithdrawalHistory = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const uid = request.auth.uid;
  const snap = await db
    .collection("payouts")
    .where("userId", "==", uid)
    .orderBy("requestedAt", "desc")
    .limit(20)
    .get();

  return {
    withdrawals: snap.docs.map((d) => ({id: d.id, ...d.data()})),
  };
});
