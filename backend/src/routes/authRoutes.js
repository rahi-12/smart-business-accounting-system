
const express = require("express");

const {
    register,
    getProfile
} = require("../controllers/authController");

const { authenticateUser } = require("../middleware/authMiddleware");

const router = express.Router();

// Register authenticated Firebase user
router.post("/register", authenticateUser, register);

// Get authenticated user's profile
router.get("/profile", authenticateUser, getProfile);

module.exports = router;
