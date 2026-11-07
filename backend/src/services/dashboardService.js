const dashboardRepository = require("../repositories/dashboardRepository");

function normalizeAmount(value) {
    const numeric = Number(value ?? 0);
    return Number.isFinite(numeric) ? Number(numeric.toFixed(2)) : 0;
}

async function getDashboardSummary(firebaseUid, repository = dashboardRepository) {
    if (!firebaseUid || !firebaseUid.trim()) {
        const error = new Error("Firebase UID is required.");
        error.code = "INVALID_INPUT";
        throw error;
    }

    const dashboardData = await repository.getDashboardDataForFirebaseUid(firebaseUid);

    const totalIncome = normalizeAmount(dashboardData.summary.total_income);
    const totalExpenses = normalizeAmount(dashboardData.summary.total_expenses);
    const netProfit = normalizeAmount(totalIncome - totalExpenses);

    const recentTransactions = (dashboardData.recent_transactions || []).map((transaction) => ({
        ...transaction,
        amount: normalizeAmount(transaction.amount),
    }));

    const monthlySummary = (dashboardData.monthly_summary || []).map((entry) => ({
        month: entry.month,
        income: normalizeAmount(entry.income),
        expenses: normalizeAmount(entry.expenses),
        net: normalizeAmount(entry.net),
    }));

    return {
        summary: {
            total_income: totalIncome,
            total_expenses: totalExpenses,
            net_profit: netProfit,
        },
        recent_transactions: recentTransactions,
        monthly_summary: monthlySummary,
    };
}

module.exports = {
    getDashboardSummary,
};
