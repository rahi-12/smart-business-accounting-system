
const authService = require("../services/authService");

// Register user profile
async function register(req, res) {
    try {
        const user = await authService.registerUser({
            firebaseUid: req.user.uid,
            fullName: req.body.fullName,
            username: req.body.username,
            email: req.user.email
        });

        return res.status(201).json({
            success: true,
            message: "User registered successfully.",
            user
        });
    } catch (error) {
        console.error("Registration error:", error.message);

        if (error.code === "USERNAME_TAKEN") {
            return res.status(409).json({
                success: false,
                code: "USERNAME_TAKEN",
                message: "Username already taken."
            });
        }

        if (error.code === "INVALID_INPUT") {
            return res.status(400).json({
                success: false,
                code: "INVALID_INPUT",
                message: error.message || "Invalid registration input."
            });
        }

        return res.status(400).json({
            success: false,
            code: "REGISTRATION_FAILED",
            message: error.message || "Registration failed."
        });
    }
}

// Get logged-in user's profile
async function getProfile(req, res) {
    try {
        const user = await authService.getUserProfile(req.user.uid);

        return res.status(200).json({
            success: true,
            user
        });
    } catch (error) {
        if (error.code === "PROFILE_NOT_FOUND") {
            return res.status(404).json({
                success: false,
                code: "PROFILE_NOT_FOUND",
                message: "Profile not found."
            });
        }

        console.error("Profile lookup error:", error.message);
        return res.status(500).json({
            success: false,
            code: "PROFILE_LOOKUP_FAILED",
            message: "Unable to load user profile."
        });
    }
}

module.exports = {
    register,
    getProfile
};
