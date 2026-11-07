const test = require("node:test");
const assert = require("node:assert/strict");

const expenseService = require("../src/services/expenseService");

const validExpense = {
    title: "Office supplies",
    amount: "120.50",
    category: "Operations",
    payment_method: "Bank transfer",
    expense_date: "2025-05-12",
    description: "Printer paper and ink",
};

test("creates expense and normalizes NUMERIC amount like the dashboard", async () => {
    let received;
    const repository = {
        createExpense: async (uid, expense) => {
            received = { uid, expense };
            return { id: "expense-id", ...expense, amount: "120.50" };
        },
    };

    const result = await expenseService.createExpense("firebase-uid", validExpense, repository);

    assert.equal(received.uid, "firebase-uid");
    assert.equal(received.expense.amount, "120.50");
    assert.equal(result.amount, 120.5);
});

test("validates create fields before calling the repository", async () => {
    let called = false;
    const repository = {
        createExpense: async () => {
            called = true;
        },
    };

    await assert.rejects(
        expenseService.createExpense("firebase-uid", { ...validExpense, amount: 0 }, repository),
        (error) => error.code === "INVALID_INPUT"
    );
    await assert.rejects(
        expenseService.createExpense("firebase-uid", { ...validExpense, expense_date: "2025-02-30" }, repository),
        (error) => error.code === "INVALID_INPUT"
    );
    await assert.rejects(
        expenseService.createExpense("firebase-uid", { ...validExpense, expense_date: "0000-01-01" }, repository),
        (error) => error.code === "INVALID_INPUT"
    );
    await assert.rejects(
        expenseService.createExpense("firebase-uid", { ...validExpense, title: "" }, repository),
        (error) => error.code === "INVALID_INPUT"
    );
    assert.equal(called, false);
});

test("lists normalized records and pagination details", async () => {
    let receivedOptions;
    const repository = {
        listExpenses: async (_uid, options) => {
            receivedOptions = options;
            return {
                items: [{ id: "expense-id", amount: "9.99" }],
                total: 21,
            };
        },
    };

    const result = await expenseService.listExpenses("firebase-uid", { page: "2", limit: "10" }, repository);

    assert.equal(receivedOptions.page, 2);
    assert.equal(result.items[0].amount, 9.99);
    assert.deepEqual(result.pagination, {
        page: 2,
        limit: 10,
        total: 21,
        totalPages: 3,
    });
});

test("rejects unsafe sorting and malformed UUIDs before repository access", async () => {
    let called = false;
    const repository = {
        listExpenses: async () => {
            called = true;
        },
        getExpenseById: async () => {
            called = true;
        },
    };

    await assert.rejects(
        expenseService.listExpenses("firebase-uid", { sortBy: "id; DROP TABLE expenses" }, repository),
        (error) => error.code === "INVALID_INPUT"
    );
    await assert.rejects(
        expenseService.getExpenseById("firebase-uid", "not-a-uuid", repository),
        (error) => error.code === "INVALID_INPUT"
    );
    assert.equal(called, false);
});

test("returns not-found for records outside the user's visible expenses", async () => {
    const repository = {
        getExpenseById: async () => null,
    };

    await assert.rejects(
        expenseService.getExpenseById("firebase-uid", "123e4567-e89b-42d3-a456-426614174000", repository),
        (error) => error.code === "EXPENSE_NOT_FOUND"
    );
});

test("updates supplied fields and deletes owned expense records", async () => {
    let updatedFields;
    const repository = {
        updateExpense: async (_uid, _id, updates) => {
            updatedFields = updates;
            return { id: "expense-id", amount: "45.00", title: updates.title };
        },
        deleteExpense: async () => ({ id: "expense-id" }),
    };
    const id = "123e4567-e89b-42d3-a456-426614174000";

    const updated = await expenseService.updateExpense("firebase-uid", id, { title: "Updated" }, repository);
    const deleted = await expenseService.deleteExpense("firebase-uid", id, repository);

    assert.deepEqual(updatedFields, { title: "Updated" });
    assert.equal(updated.amount, 45);
    assert.deepEqual(deleted, { id: "expense-id" });
});

test("clears an expense description when PUT receives null or an empty string", async () => {
    const receivedUpdates = [];
    const repository = {
        updateExpense: async (_uid, _id, updates) => {
            receivedUpdates.push(updates);
            return { id: "expense-id", ...updates, amount: "45.00" };
        },
    };
    const id = "123e4567-e89b-42d3-a456-426614174000";

    for (const description of [null, ""]) {
        const updated = await expenseService.updateExpense(
            "firebase-uid",
            id,
            { description },
            repository
        );
        assert.equal(updated.description, null);
    }

    assert.deepEqual(receivedUpdates, [{ description: null }, { description: null }]);
});

test("limits expense descriptions by Unicode character count", async () => {
    let called = false;
    const repository = {
        createExpense: async (_uid, expense) => {
            called = true;
            return { id: "expense-id", ...expense, amount: "120.50" };
        },
    };
    const maxLengthDescription = "😀".repeat(5000);

    await expenseService.createExpense(
        "firebase-uid",
        { ...validExpense, description: maxLengthDescription },
        repository
    );
    assert.equal(called, true);

    await assert.rejects(
        expenseService.createExpense(
            "firebase-uid",
            { ...validExpense, description: `${maxLengthDescription}😀` },
            repository
        ),
        (error) => error.code === "INVALID_INPUT"
    );
});
