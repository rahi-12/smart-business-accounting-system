const test = require("node:test");
const assert = require("node:assert/strict");

const incomeService = require("../src/services/incomeService");

const validIncome = {
    title: "Consulting",
    amount: "120.50",
    category: "Services",
    payment_method: "Bank transfer",
    income_date: "2025-05-12",
    description: "Consulting invoice",
};

test("creates income and normalizes NUMERIC amount like the dashboard", async () => {
    let received;
    const repository = {
        createIncome: async (uid, income) => {
            received = { uid, income };
            return { id: "income-id", ...income, amount: "120.50" };
        },
    };

    const result = await incomeService.createIncome("firebase-uid", validIncome, repository);

    assert.equal(received.uid, "firebase-uid");
    assert.equal(received.income.amount, "120.50");
    assert.equal(result.amount, 120.5);
});

test("validates create fields before calling the repository", async () => {
    let called = false;
    const repository = {
        createIncome: async () => {
            called = true;
        },
    };

    await assert.rejects(
        incomeService.createIncome("firebase-uid", { ...validIncome, amount: 0 }, repository),
        (error) => error.code === "INVALID_INPUT"
    );
    await assert.rejects(
        incomeService.createIncome("firebase-uid", { ...validIncome, income_date: "2025-02-30" }, repository),
        (error) => error.code === "INVALID_INPUT"
    );
    await assert.rejects(
        incomeService.createIncome("firebase-uid", { ...validIncome, income_date: "0000-01-01" }, repository),
        (error) => error.code === "INVALID_INPUT"
    );
    assert.equal(called, false);
});

test("accepts year 0001 and rejects year 0000 for income dates", async () => {
    let received;
    const repository = {
        createIncome: async (_uid, income) => {
            received = income;
            return { id: "income-id", ...income, amount: "120.50" };
        },
    };

    await incomeService.createIncome(
        "firebase-uid",
        { ...validIncome, income_date: "0001-01-01" },
        repository
    );
    assert.equal(received.income_date, "0001-01-01");
});

test("lists normalized records and pagination details", async () => {
    let receivedOptions;
    const repository = {
        listIncome: async (_uid, options) => {
            receivedOptions = options;
            return {
                items: [{ id: "income-id", amount: "9.99" }],
                total: 21,
            };
        },
    };

    const result = await incomeService.listIncome("firebase-uid", { page: "2", limit: "10" }, repository);

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
        listIncome: async () => {
            called = true;
        },
        getIncomeById: async () => {
            called = true;
        },
    };

    await assert.rejects(
        incomeService.listIncome("firebase-uid", { sortBy: "id; DROP TABLE income" }, repository),
        (error) => error.code === "INVALID_INPUT"
    );
    await assert.rejects(
        incomeService.getIncomeById("firebase-uid", "not-a-uuid", repository),
        (error) => error.code === "INVALID_INPUT"
    );
    assert.equal(called, false);
});

test("returns not-found for records outside the user's visible income", async () => {
    const repository = {
        getIncomeById: async () => null,
    };

    await assert.rejects(
        incomeService.getIncomeById("firebase-uid", "123e4567-e89b-42d3-a456-426614174000", repository),
        (error) => error.code === "INCOME_NOT_FOUND"
    );
});

test("updates supplied fields and deletes owned income records", async () => {
    let updatedFields;
    const repository = {
        updateIncome: async (_uid, _id, updates) => {
            updatedFields = updates;
            return { id: "income-id", amount: "45.00", title: updates.title };
        },
        deleteIncome: async () => ({ id: "income-id" }),
    };
    const id = "123e4567-e89b-42d3-a456-426614174000";

    const updated = await incomeService.updateIncome("firebase-uid", id, { title: "Updated" }, repository);
    const deleted = await incomeService.deleteIncome("firebase-uid", id, repository);

    assert.deepEqual(updatedFields, { title: "Updated" });
    assert.equal(updated.amount, 45);
    assert.deepEqual(deleted, { id: "income-id" });
});

test("clears an income description when PUT receives null or an empty string", async () => {
    const receivedUpdates = [];
    const repository = {
        updateIncome: async (_uid, _id, updates) => {
            receivedUpdates.push(updates);
            return { id: "income-id", ...updates, amount: "45.00" };
        },
    };
    const id = "123e4567-e89b-42d3-a456-426614174000";

    for (const description of [null, ""]) {
        const updated = await incomeService.updateIncome(
            "firebase-uid",
            id,
            { description },
            repository
        );
        assert.equal(updated.description, null);
    }

    assert.deepEqual(receivedUpdates, [{ description: null }, { description: null }]);
});

test("limits income descriptions by Unicode character count", async () => {
    let called = false;
    const repository = {
        createIncome: async (_uid, income) => {
            called = true;
            return { id: "income-id", ...income, amount: "120.50" };
        },
    };
    const maxLengthDescription = "😀".repeat(5000);

    await incomeService.createIncome(
        "firebase-uid",
        { ...validIncome, description: maxLengthDescription },
        repository
    );
    assert.equal(called, true);

    await assert.rejects(
        incomeService.createIncome(
            "firebase-uid",
            { ...validIncome, description: `${maxLengthDescription}😀` },
            repository
        ),
        (error) => error.code === "INVALID_INPUT"
    );
});
