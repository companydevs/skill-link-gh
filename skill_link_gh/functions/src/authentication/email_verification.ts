/* eslint-disable linebreak-style */
import {onCall} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import admin from "firebase-admin";

const firestore = admin.firestore();
const RESEND_API_KEY = defineSecret("RESEND_API_KEY");

export const resendVerificationCode = onCall(
  {secrets: [RESEND_API_KEY], region: "us-central1"},
  async (request) => {
    const {email} = request.data as { email: string };
    if (!email) {
      throw new Error("Email is required");
    }

    // Generate new OTP
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const now = admin.firestore.Timestamp.now();
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 30 * 60 * 1000)
    );

    try {
      // Save in Firestore
      const docRef = firestore.collection("email_verifications").doc();
      await docRef.set({
        code,
        email,
        createdAt: now,
        expiresAt,
        status: "pending",
        used: false,
        attempts: 0,
      });

      // Send email via Resend
      const response = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${RESEND_API_KEY.value()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: "SkillLink GH <onboarding@resend.dev>",
          to: email,
          subject: "Your OTP code - SkillLinkGh",
          html: `<div style="padding:32px; text-align:center;
           font-family:Arial,sans-serif;">
            <h2>Your verification code</h2>
            <h1>${code}</h1>
            <p>Expires in 30 minutes</p>
          </div>`,
        }),
      });

      if (!response.ok) {
        const errText = await response.text();
        throw new Error("Email sending failed: " + errText);
      }

      return {success: true, message: "OTP sent"};
    } catch (err: unknown) {
      console.error(err);
      throw new Error(err instanceof Error ? err.message : String(err));
    }
  }
);
