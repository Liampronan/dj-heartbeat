import firebaseAdmin from "firebase-admin";

// use firebaseAdmin for admin-level tasks like creating a user.
export const firebaseAdminApp = firebaseAdmin.initializeApp();
// use db for interfacing with firebase backend generally.
export const db = firebaseAdminApp.firestore();
