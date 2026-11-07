const { pool } = require("../config/database");
const { findUserByFirebaseUid } = require("./userRepository");

const sortableColumns = {
    income_date: "income_date",
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

async function createIncome(firebaseUid, income) {
    const userId = await getUserId(firebaseUid);
    const result = await pool.query(
        `
            INSERT INTO income (user_id, title, amount, category, payment_method, income_date, description)
            VALUES ($1, $2, $3, $4, $5, COALESCE($6::date, CURRENT_DATE), $7)
            RETURNING id, title, amount, category, payment_method, income_date, description, created_at, updated_at
        `,
        [
            userId,
            income.title,
            income.amount,
            income.category,
            income.payment_method,
            income.income_date || null,
            income.description,
        ]
    );
    return result.rows[0] || null;
}

async function listIncome(firebaseUid, options) {
    const userId = await getUserId(firebaseUid);
    const sortColumn = sortableColumns[options.sortBy];
    if (!sortColumn) {
        const error = new Error("Unsupported income sort column.");
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
        addCondition("income_date >= ?::date", options.startDate);
    }
    if (options.endDate) {
        addCondition("income_date <= ?::date", options.endDate);
    }
    if (options.category) {
        addCondition("category = ?", options.category);
    }

    const whereClause = conditions.join(" AND ");
    const countResult = await pool.query(
        `SELECT COUNT(*)::int AS total FROM income WHERE ${whereClause}`,
        values
    );
    const pageValues = [...values, options.limit, (options.page - 1) * options.limit];
    const result = await pool.query(
        `
            SELECT id, title, amount, category, payment_method, income_date, description, created_at, updated_at
            FROM income
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

async function getIncomeById(firebaseUid, id) {
    const userId = await getUserId(firebaseUid);
    const result = await pool.query(
        `
            SELECT id, title, amount, category, payment_method, income_date, description, created_at, updated_at
            FROM income
            WHERE user_id = $1 AND id = $2
            LIMIT 1
        `,
        [userId, id]
    );
    return result.rows[0] || null;
}

async function updateIncome(firebaseUid, id, updates) {
    const userId = await getUserId(firebaseUid);
    const fields = Object.keys(updates);
    const values = [userId, id];
    const assignments = fields.map((field) => {
        values.push(updates[field]);
        return `${field} = $${values.length}`;
    });

    const result = await pool.query(
        `
            UPDATE income
            SET ${assignments.join(", ")}, updated_at = CURRENT_TIMESTAMP
            WHERE user_id = $1 AND id = $2
            RETURNING id, title, amount, category, payment_method, income_date, description, created_at, updated_at
        `,
        values
    );
    return result.rows[0] || null;
}

async function deleteIncome(firebaseUid, id) {
    const userId = await getUserId(firebaseUid);
    const result = await pool.query(
        "DELETE FROM income WHERE user_id = $1 AND id = $2 RETURNING id",
        [userId, id]
    );
    return result.rows[0] || null;
}

module.exports = {
    createIncome,
    listIncome,
    getIncomeById,
    updateIncome,
    deleteIncome,
};
