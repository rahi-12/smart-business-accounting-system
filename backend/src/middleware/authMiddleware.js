const { initializeFirebase, getAuth } = require("../config/firebase");

async function authenticateUser(req, res, next) {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res.status(401).json({
                success: false,
                code: "INVALID_TOKEN",
                message: "Authentication token is required."
            });
        }

        const idToken = authHeader.substring(7);
        const firebaseApp = initializeFirebase();
        const decodedToken = await getAuth(firebaseApp).verifyIdToken(idToken);

        req.user = {
            uid: decodedToken.uid,
            email: decodedToken.email || null
        };

        next();
    } catch (error) {
        return res.status(401).json({
            success: false,
            code: "INVALID_TOKEN",
            message: "Invalid or expired authentication token."
        });
    }
}

module.exports = {
    authenticateUser
};