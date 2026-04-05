/* eslint-disable linebreak-style */
import {onCall} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {HttpsError} from "firebase-functions/v2/https";
import admin from "firebase-admin";

const firestore = admin.firestore();
const RESEND_API_KEY = defineSecret("RESEND_API_KEY");

export const resendVerificationCode = onCall(
  {secrets: [RESEND_API_KEY], region: "us-central1"},
  async (request) => {
    const {email} = request.data as { email: string };
    if (!email) {
      throw new HttpsError("invalid-argument", "Email is required");
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const now = admin.firestore.Timestamp.now();
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 30 * 60 * 1000)
    );

    // Save OTP to Firestore first
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

    // Send via Resend
    const apiKey = RESEND_API_KEY.value();
    console.log("Sending OTP to:", email, "| API key present:", !!apiKey);

    // DEV MODE: whitelist — onboarding@resend.dev only delivers to verified emails
    const ALLOWED_EMAILS = [
      "surajmohammedbwoy@gmail.com",
      "surajmohammedbwoy1000@gmail.com",
    ];
    const deliverTo = ALLOWED_EMAILS.includes(email) ? email : ALLOWED_EMAILS[0];
    console.log(`Delivering OTP to: ${deliverTo} (requested: ${email})`);

    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "SkillLink GH <onboarding@resend.dev>",
        to: [deliverTo],
        subject: "Your SkillLink GH verification code",
        html: `
          <div style="max-width:480px;margin:0 auto;padding:32px;
            font-family:Arial,sans-serif;text-align:center;">
            <h2 style="margin-bottom:8px;">Verify your email</h2>
            <p style="color:#666;margin-bottom:24px;">
              Enter this code in the app. It expires in 30 minutes.
            </p>
            <div style="font-size:40px;font-weight:bold;
              letter-spacing:12px;color:#1a1a1a;padding:16px;
              background:#f5f5f5;border-radius:8px;">
              ${code}
            </div>
            <p style="color:#999;font-size:12px;margin-top:24px;">
              If you didn't request this, ignore this email.
            </p>
          </div>`,
      }),
    });

    const responseText = await response.text();
    console.log("Resend response status:", response.status);
    console.log("Resend response body:", responseText);

    if (!response.ok) {
      // Clean up the saved OTP since email failed
      await docRef.delete();
      throw new HttpsError(
        "internal",
        `Email sending failed (${response.status}): ${responseText}`
      );
    }

    return {success: true, message: "OTP sent successfully"};
  }
);
