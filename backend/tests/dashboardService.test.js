const test = require("node:test");
const assert = require("node:assert/strict");

const { getDashboardSummary } = require("../src/services/dashboardService");

test("returns normalized dashboard totals, transactions, and monthly summary", async () => {
    const repo = {
        getDashboardDataForFirebaseUid: async () => ({
            summary: {
                total_income: "2450.50",
                total_expenses: "890.25",
            },
            recent_transactions: [
                {
                    id: "txn-1",
                    type: "income",
                    title: "Consulting Client",
                    amount: "1200.00",
                    category: "Services",
                    payment_method: "Bank Transfer",
                    transaction_date: "2025-05-12",
                    description: "Professional fee",
                },
                {
                    id: "txn-2",
                    type: "expense",
                    title: "Office Rent",
                    amount: "425.50",
                    category: "Operations",
                    payment_method: "Bank Transfer",
                    transaction_date: "2025-05-10",
                    description: "Monthly rent",
                },
            ],
            monthly_summary: [
                { month: "Jan", income: "1000", expenses: "800", net: "200" },
                { month: "Feb", income: "500", expenses: "250", net: "250" },
            ],
        }),
    };

    const dashboard = await getDashboardSummary("firebase-uid-1", repo);

    assert.equal(dashboard.summary.total_income, 2450.5);
    assert.equal(dashboard.summary.total_expenses, 890.25);
    assert.equal(dashboard.summary.net_profit, 1560.25);
    assert.equal(dashboard.recent_transactions.length, 2);
    assert.equal(dashboard.monthly_summary[0].month, "Jan");
    assert.equal(dashboard.monthly_summary[1].net, 250);
});

test("rejects requests with missing Firebase UID", async () => {
    await assert.rejects(
        async () => getDashboardSummary("   "),
        (error) => {
            assert.equal(error.code, "INVALID_INPUT");
            return true;
        }
    );
});

test("propagates user-profile-not-found errors", async () => {
    const repo = {
        getDashboardDataForFirebaseUid: async () => {
            const error = new Error("User profile not found.");
            error.code = "PROFILE_NOT_FOUND";
            throw error;
        },
    };

    await assert.rejects(
        async () => getDashboardSummary("firebase-uid-2", repo),
        (error) => {
            assert.equal(error.code, "PROFILE_NOT_FOUND");
            return true;
        }
    );
});
