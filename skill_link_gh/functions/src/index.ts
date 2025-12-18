/**
 * Firebase Cloud Functions entry point (v2)
 */

import {setGlobalOptions} from "firebase-functions/v2";

// 🔐 Global options (cost + safety)
setGlobalOptions({
  maxInstances: 10,
  region: "us-central1",
});

/**
 * ----------------------------------------------------
 * 🔗 IMPORT FUNCTIONS FROM SUB-FILES
 * ----------------------------------------------------
 * Keep index.ts CLEAN.
 * Each feature goes in its own file.
 */
export {registerUser} from "./authentication/createUser";
export {signInUser} from "./authentication/signInUser";
export {resendVerificationCode} from "./authentication/email_verification";
export {verifyEmailCode} from "./authentication/verifyEmailCode";
export {resetPassword} from "./authentication/resetPassword";
export {checkUserStatus} from "./authentication/checkUserStatus";
export {deleteUserAccount} from "./authentication/deleteUserAccount";
export {deleteComment} from "./posts/deleteComment";


export {createPost} from "./posts/createPost";
