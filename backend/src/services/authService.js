
const {
    findUserByFirebaseUid,
    findUserByEmail,
    findUserByUsername,
    createUser
} = require("../repositories/userRepository");

// Register a user profile in PostgreSQL
async function registerUser(userData) {
    const { firebaseUid, fullName, username, email } = userData;

    if (!firebaseUid || !fullName || !username || !email) {
        const err = new Error("Invalid registration input.");
        err.code = "INVALID_INPUT";
        throw err;
    }

    const trimmedFullName = fullName.trim();
    if (!trimmedFullName || trimmedFullName.length > 100) {
        const err = new Error("Full name must be between 1 and 100 characters.");
        err.code = "INVALID_INPUT";
        throw err;
    }

    const trimmedUsername = username.trim();
    if (!/^[a-zA-Z0-9_]{3,30}$/.test(trimmedUsername)) {
        const err = new Error(
            "Username must contain 3-30 letters, numbers, or underscores."
        );
        err.code = "INVALID_INPUT";
        throw err;
    }

    const existingEmail = await findUserByEmail(email);
    if (existingEmail && existingEmail.firebase_uid !== firebaseUid) {
        const err = new Error("This email is already registered.");
        err.code = "EMAIL_IN_USE";
        throw err;
    }

    const existingUsername = await findUserByUsername(trimmedUsername);
    if (existingUsername && existingUsername.firebase_uid !== firebaseUid) {
        const err = new Error("Username already taken.");
        err.code = "USERNAME_TAKEN";
        throw err;
    }

    try {
        return await createUser({
            firebaseUid,
            fullName: trimmedFullName,
            username: trimmedUsername,
            email
        });
    } catch (error) {
        if (error.code === "23505") {
            if (error.constraint?.includes("username")) {
                const err = new Error("Username already taken.");
                err.code = "USERNAME_TAKEN";
                throw err;
            }

            if (error.constraint?.includes("email")) {
                const err = new Error("This email is already registered.");
                err.code = "EMAIL_IN_USE";
                throw err;
            }
        }

        throw error;
    }
}

// Get the PostgreSQL profile of an authenticated Firebase user
async function getUserProfile(firebaseUid) {
    const user = await findUserByFirebaseUid(firebaseUid);

    if (!user) {
        const err = new Error("User profile not found.");
        err.code = "PROFILE_NOT_FOUND";
        throw err;
    }

    return user;
}

module.exports = {
    registerUser,
    getUserProfile
};
