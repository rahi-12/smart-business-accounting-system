const { pool } = require("../config/database");
const { findUserByFirebaseUid } = require("./userRepository");

const sortableColumns = {
    expense_date: "expense_date",
    amount: "amount",
    title: "title",
    category: "category",
    created_at: "created_at",
    updated_at: "updated_at",
};

async function getUserId(firebaseUid) {
    const user = await findUserByFirebaseUid(firebaseUid);
    if (!user) {
        const error = new Error("User profile not found.");
        error.code = "PROFILE_NOT_FOUND";
        throw error;
    }
    return user.id;
}

async function createExpense(firebaseUid, expense) {
    const userId = await getUserId(firebaseUid);
    const result = await pool.query(
        `
            INSERT INTO expenses (user_id, title, amount, category, payment_method, expense_date, description)
            VALUES ($1, $2, $3, $4, $5, COALESCE($6::date, CURRENT_DATE), $7)
            RETURNING id, title, amount, category, payment_method, expense_date, description, created_at, updated_at
        `,
        [
            userId,
            expense.title,
            expense.amount,
            expense.category,
            expense.payment_method,
            expense.expense_date || null,
            expense.description,
        ]
    );
    return result.rows[0] || null;
}

async function listExpenses(firebaseUid, options) {
    const userId = await getUserId(firebaseUid);
    const sortColumn = sortableColumns[options.sortBy];
    if (!sortColumn) {
        const error = new Error("Unsupported expense sort column.");
        error.code = "INVALID_INPUT";
        throw error;
    }

    const conditions = ["user_id = $1"];
    const values = [userId];

    function addCondition(condition, value) {
        values.push(value);
        conditions.push(condition.replace("?", `$${values.length}`));
    }

    if (options.search) {
        values.push(`%${options.search}%`);
        conditions.push(`(title ILIKE $${values.length} OR description ILIKE $${values.length})`);
    }
    if (options.startDate) {
        addCondition("expense_date >= ?::date", options.startDate);
    }
    if (options.endDate) {
        addCondition("expense_date <= ?::date", options.endDate);
    }
    if (options.category) {
        addCondition("category = ?", options.category);
    }

    const whereClause = conditions.join(" AND ");
    const countResult = await pool.query(
        `SELECT COUNT(*)::int AS total FROM expenses WHERE ${whereClause}`,
        values
    );
    const pageValues = [...values, options.limit, (options.page - 1) * options.limit];
    const result = await pool.query(
        `
            SELECT id, title, amount, category, payment_method, expense_date, description, created_at, updated_at
            FROM expenses
            WHERE ${whereClause}
            ORDER BY ${sortColumn} ${options.order}, id ${options.order}
            LIMIT $${pageValues.length - 1} OFFSET $${pageValues.length}
        `,
        pageValues
    );

    return {
        items: result.rows,
        total: countResult.rows[0].total,
    };
}

async function getExpenseById(firebaseUid, id) {
    const userId = await getUserId(firebaseUid);
    const result = await pool.query(
        `
            SELECT id, title, amount, category, payment_method, expense_date, description, created_at, updated_at
            FROM expenses
            WHERE user_id = $1 AND id = $2
            LIMIT 1
        `,
        [userId, id]
    );
    return result.rows[0] || null;
}

async function updateExpense(firebaseUid, id, updates) {
    const userId = await getUserId(firebaseUid);
    const fields = Object.keys(updates);
    const values = [userId, id];
    const assignments = fields.map((field) => {
        values.push(updates[field]);
        return `${field} = $${values.length}`;
    });

    const result = await pool.query(
        `
            UPDATE expenses
            SET ${assignments.join(", ")}, updated_at = CURRENT_TIMESTAMP
            WHERE user_id = $1 AND id = $2
            RETURNING id, title, amount, category, payment_method, expense_date, description, created_at, updated_at
        `,
        values
    );
    return result.rows[0] || null;
}

async function deleteExpense(firebaseUid, id) {
    const userId = await getUserId(firebaseUid);
    const result = await pool.query(
        "DELETE FROM expenses WHERE user_id = $1 AND id = $2 RETURNING id",
        [userId, id]
    );
    return result.rows[0] || null;
}

module.exports = {
    createExpense,
    listExpenses,
    getExpenseById,
    updateExpense,
    deleteExpense,
};
