const express = require("express");

const { getDashboardSummary } = require("../controllers/dashboardController");
const { authenticateUser } = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/summary", authenticateUser, getDashboardSummary);

module.exports = router;
