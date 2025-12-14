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
