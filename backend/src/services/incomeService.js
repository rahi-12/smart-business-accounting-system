const incomeRepository = require("../repositories/incomeRepository");
const {
    validateCreateIncome,
    validateUpdateIncome,
    validateIncomeId,
    validateListOptions,
} = require("../validators/incomeValidator");

function normalizeAmount(value) {
    const amount = Number(value);
    return Number.isFinite(amount) ? Number(amount.toFixed(2)) : 0;
}

function normalizeIncome(income) {
    if (!income) {
        return null;
    }
    return {
        ...income,
        amount: normalizeAmount(income.amount),
    };
}

function incomeNotFound() {
    const error = new Error("Income record not found.");
    error.code = "INCOME_NOT_FOUND";
    return error;
}

async function createIncome(firebaseUid, input, repository = incomeRepository) {
    const income = validateCreateIncome(input);
    const created = await repository.createIncome(firebaseUid, income);
    if (!created) {
        throw new Error("Income record was not returned after creation.");
    }
    return normalizeIncome(created);
}

async function listIncome(firebaseUid, query = {}, repository = incomeRepository) {
    const options = validateListOptions(query);
    const result = await repository.listIncome(firebaseUid, options);
    return {
        items: result.items.map(normalizeIncome),
        pagination: {
            page: options.page,
            limit: options.limit,
            total: result.total,
            totalPages: Math.ceil(result.total / options.limit),
        },
    };
}

async function getIncomeById(firebaseUid, id, repository = incomeRepository) {
    const validId = validateIncomeId(id);
    const income = await repository.getIncomeById(firebaseUid, validId);
    if (!income) {
        throw incomeNotFound();
    }
    return normalizeIncome(income);
}

async function updateIncome(firebaseUid, id, input, repository = incomeRepository) {
    const validId = validateIncomeId(id);
    const updates = validateUpdateIncome(input);
    const income = await repository.updateIncome(firebaseUid, validId, updates);
    if (!income) {
        throw incomeNotFound();
    }
    return normalizeIncome(income);
}

async function deleteIncome(firebaseUid, id, repository = incomeRepository) {
    const validId = validateIncomeId(id);
    const deleted = await repository.deleteIncome(firebaseUid, validId);
    if (!deleted) {
        throw incomeNotFound();
    }
    return { id: deleted.id };
}

module.exports = {
    createIncome,
    listIncome,
    getIncomeById,
    updateIncome,
    deleteIncome,
};
