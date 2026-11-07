const test = require("node:test");
const assert = require("node:assert/strict");

const { pool } = require("../src/config/database");
const incomeRepository = require("../src/repositories/incomeRepository");
const expenseRepository = require("../src/repositories/expenseRepository");

test("binds cleared descriptions as SQL NULL for income and expense updates", async () => {
    const originalQuery = pool.query;
    const updates = [];

    pool.query = async (query, values) => {
        if (query.includes("FROM users")) {
            return { rows: [{ id: "user-id" }] };
        }
        if (query.includes("UPDATE income") || query.includes("UPDATE expenses")) {
            updates.push({ query, values });
            return { rows: [{ id: "transaction-id", description: null }] };
        }
        throw new Error("Unexpected query in repository test.");
    };

    try {
        await incomeRepository.updateIncome(
            "firebase-uid",
            "123e4567-e89b-42d3-a456-426614174000",
            { description: null }
        );
        await expenseRepository.updateExpense(
            "firebase-uid",
            "123e4567-e89b-42d3-a456-426614174000",
            { description: null }
        );

        assert.equal(updates.length, 2);
        for (const update of updates) {
            assert.match(update.query, /SET description = \$3, updated_at = CURRENT_TIMESTAMP/);
            assert.deepEqual(update.values, [
                "user-id",
                "123e4567-e89b-42d3-a456-426614174000",
                null,
            ]);
        }
    } finally {
        pool.query = originalQuery;
    }
});
