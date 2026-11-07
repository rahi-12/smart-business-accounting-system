const dashboardService = require("../services/dashboardService");

async function getDashboardSummary(req, res) {
    try {
        const dashboardSummary = await dashboardService.getDashboardSummary(req.user.uid);

        return res.status(200).json({
            success: true,
            data: dashboardSummary,
        });
    } catch (error) {
        if (error.code === "PROFILE_NOT_FOUND") {
            return res.status(404).json({
                success: false,
                code: "PROFILE_NOT_FOUND",
                message: "User profile not found.",
            });
        }

        if (error.code === "INVALID_INPUT") {
            return res.status(400).json({
                success: false,
                code: "INVALID_INPUT",
                message: error.message || "Invalid dashboard request.",
            });
        }

        console.error("Dashboard summary error:", error.message);
        return res.status(500).json({
            success: false,
            code: "DASHBOARD_SUMMARY_FAILED",
            message: "Unable to load dashboard summary.",
        });
    }
}

module.exports = {
    getDashboardSummary,
};
