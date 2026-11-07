const {
    initializeApp,
    getApps,
    applicationDefault
} = require("firebase-admin/app");

const { getAuth } = require("firebase-admin/auth");

let firebaseApp;

function initializeFirebase() {
    if (firebaseApp) {
        return firebaseApp;
    }

    // Check whether Firebase is already initialized
    const existingApps = getApps();

    if (existingApps.length > 0) {
        firebaseApp = existingApps[0];
    } else {
        // Initialize Firebase using service account credentials
        firebaseApp = initializeApp({
            credential: applicationDefault()
        });

        console.log("Firebase Admin SDK initialized successfully.");
    }

    return firebaseApp;
}

module.exports = {
    initializeFirebase,
    getAuth
};