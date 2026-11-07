const expenseRepository = require("../repositories/expenseRepository");
const {
    validateCreateExpense,
    validateUpdateExpense,
    validateExpenseId,
    validateListOptions,
} = require("../validators/expenseValidator");

function normalizeAmount(value) {
    const amount = Number(value);
    return Number.isFinite(amount) ? Number(amount.toFixed(2)) : 0;
}

function normalizeExpense(expense) {
    if (!expense) {
        return null;
    }
    return {
        ...expense,
        amount: normalizeAmount(expense.amount),
    };
}

function expenseNotFound() {
    const error = new Error("Expense record not found.");
    error.code = "EXPENSE_NOT_FOUND";
    return error;
}

async function createExpense(firebaseUid, input, repository = expenseRepository) {
    const expense = validateCreateExpense(input);
    const created = await repository.createExpense(firebaseUid, expense);
    if (!created) {
        throw new Error("Expense record was not returned after creation.");
    }
    return normalizeExpense(created);
}

async function listExpenses(firebaseUid, query = {}, repository = expenseRepository) {
    const options = validateListOptions(query);
    const result = await repository.listExpenses(firebaseUid, options);
    return {
        items: result.items.map(normalizeExpense),
        pagination: {
            page: options.page,
            limit: options.limit,
            total: result.total,
            totalPages: Math.ceil(result.total / options.limit),
        },
    };
}

async function getExpenseById(firebaseUid, id, repository = expenseRepository) {
    const validId = validateExpenseId(id);
    const expense = await repository.getExpenseById(firebaseUid, validId);
    if (!expense) {
        throw expenseNotFound();
    }
    return normalizeExpense(expense);
}

async function updateExpense(firebaseUid, id, input, repository = expenseRepository) {
    const validId = validateExpenseId(id);
    const updates = validateUpdateExpense(input);
    const expense = await repository.updateExpense(firebaseUid, validId, updates);
    if (!expense) {
        throw expenseNotFound();
    }
    return normalizeExpense(expense);
}

async function deleteExpense(firebaseUid, id, repository = expenseRepository) {
    const validId = validateExpenseId(id);
    const deleted = await repository.deleteExpense(firebaseUid, validId);
    if (!deleted) {
        throw expenseNotFound();
    }
    return { id: deleted.id };
}

module.exports = {
    createExpense,
    listExpenses,
    getExpenseById,
    updateExpense,
    deleteExpense,
};
