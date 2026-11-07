
const { pool } = require("../config/database");

// Find a user by Firebase UID
async function findUserByFirebaseUid(firebaseUid) {
    const query = `
        SELECT id, firebase_uid, full_name, username, email
        FROM users
        WHERE firebase_uid = $1
        LIMIT 1
    `;

    const result = await pool.query(query, [firebaseUid]);

    return result.rows[0] || null;
}

// Find a user by email
async function findUserByEmail(email) {
    const query = `
        SELECT id, firebase_uid, full_name, username, email
        FROM users
        WHERE LOWER(email) = LOWER($1)
        LIMIT 1
    `;

    const result = await pool.query(query, [email]);

    return result.rows[0] || null;
}

// Find a user by username
async function findUserByUsername(username) {
    const query = `
        SELECT id, username
        FROM users
        WHERE LOWER(username) = LOWER($1)
        LIMIT 1
    `;

    const result = await pool.query(query, [username]);

    return result.rows[0] || null;
}

// Create a new user profile or update an existing profile for the same Firebase user
async function createUser(userData) {
    const { firebaseUid, fullName, username, email } = userData;

    const query = `
        INSERT INTO users (firebase_uid, full_name, username, email)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (firebase_uid)
        DO UPDATE SET
            full_name = EXCLUDED.full_name,
            username = EXCLUDED.username
        RETURNING id, firebase_uid, full_name, username, email
    `;

    const result = await pool.query(query, [
        firebaseUid,
        fullName,
        username,
        email
    ]);

    return result.rows[0];
}

module.exports = {
    findUserByFirebaseUid,
    findUserByEmail,
    findUserByUsername,
    createUser
};
