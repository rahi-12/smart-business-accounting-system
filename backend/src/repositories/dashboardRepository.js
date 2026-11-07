const { pool } = require("../config/database");
const { findUserByFirebaseUid } = require("./userRepository");

function asNumber(value, fallback = 0) {
    const parsed = Number(value ?? fallback);
    return Number.isFinite(parsed) ? parsed : fallback;
}

async function getDashboardDataForFirebaseUid(firebaseUid) {
    const user = await findUserByFirebaseUid(firebaseUid);

    if (!user) {
        const error = new Error("User profile not found.");
        error.code = "PROFILE_NOT_FOUND";
        throw error;
    }

    const userId = user.id;

    const totalsResult = await pool.query(
        `
            SELECT
                COALESCE((
                    SELECT SUM(amount)
                    FROM income
                    WHERE user_id = $1
                ), 0) AS total_income,
                COALESCE((
                    SELECT SUM(amount)
                    FROM expenses
                    WHERE user_id = $1
                ), 0) AS total_expenses
        `,
        [userId]
    );

    const totals = totalsResult.rows[0] || {};
    const totalIncome = asNumber(totals.total_income, 0);
    const totalExpenses = asNumber(totals.total_expenses, 0);

    const recentTransactionsResult = await pool.query(
        `
            SELECT
                type,
                id,
                title,
                amount,
                category,
                payment_method,
                transaction_date,
                description
            FROM (
                SELECT
                    'income'::text AS type,
                    id,
                    title,
                    amount,
                    category,
                    payment_method,
                    income_date AS transaction_date,
                    description
                FROM income
                WHERE user_id = $1

                UNION ALL

                SELECT
                    'expense'::text AS type,
                    id,
                    title,
                    amount,
                    category,
                    payment_method,
                    expense_date AS transaction_date,
                    description
                FROM expenses
                WHERE user_id = $1
            ) AS transactions
            ORDER BY transaction_date DESC, id DESC
            LIMIT $2
        `,
        [userId, 10]
    );

    const recentTransactions = recentTransactionsResult.rows.map((row) => ({
        id: row.id,
        type: row.type,
        title: row.title,
        amount: asNumber(row.amount, 0),
        category: row.category,
        payment_method: row.payment_method,
        transaction_date: row.transaction_date ? row.transaction_date.toISOString?.() || String(row.transaction_date) : null,
        description: row.description || null,
    }));

    const currentYear = new Date().getFullYear();

    const monthlySummaryResult = await pool.query(
        `
            WITH months AS (
                SELECT generate_series(1, 12) AS month_number
            )
            SELECT
                months.month_number,
                TO_CHAR(TO_DATE(months.month_number::text, 'MM'), 'Mon') AS month_name,
                COALESCE(SUM(CASE WHEN tx.type = 'income' THEN tx.amount ELSE 0 END), 0) AS income_total,
                COALESCE(SUM(CASE WHEN tx.type = 'expense' THEN tx.amount ELSE 0 END), 0) AS expense_total
            FROM months
            LEFT JOIN (
                SELECT
                    EXTRACT(MONTH FROM income_date)::int AS month_number,
                    'income'::text AS type,
                    amount
                FROM income
                WHERE user_id = $1 AND EXTRACT(YEAR FROM income_date) = $2

                UNION ALL

                SELECT
                    EXTRACT(MONTH FROM expense_date)::int AS month_number,
                    'expense'::text AS type,
                    amount
                FROM expenses
                WHERE user_id = $1 AND EXTRACT(YEAR FROM expense_date) = $2
            ) AS tx ON tx.month_number = months.month_number
            GROUP BY months.month_number
            ORDER BY months.month_number ASC
        `,
        [userId, currentYear]
    );

    const monthlySummary = monthlySummaryResult.rows.map((row) => ({
        month: row.month_name,
        income: asNumber(row.income_total, 0),
        expenses: asNumber(row.expense_total, 0),
        net: asNumber(row.income_total, 0) - asNumber(row.expense_total, 0),
    }));

    return {
        summary: {
            total_income: totalIncome,
            total_expenses: totalExpenses,
            net_profit: totalIncome - totalExpenses,
        },
        recent_transactions: recentTransactions,
        monthly_summary: monthlySummary,
    };
}

module.exports = {
    getDashboardDataForFirebaseUid,
};
