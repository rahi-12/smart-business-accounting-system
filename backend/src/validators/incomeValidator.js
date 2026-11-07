const MAX_AMOUNT = 9999999999.99;
const MAX_DESCRIPTION_LENGTH = 5000;

const editableFields = ["title", "amount", "category", "payment_method", "income_date", "description"];

function invalidInput(message) {
    const error = new Error(message);
    error.code = "INVALID_INPUT";
    return error;
}

function validateText(value, field, maxLength, required) {
    if (value === undefined) {
        if (required) {
            throw invalidInput(`${field} is required.`);
        }
        return value;
    }

    if (value === null && field === "description") {
        return null;
    }

    if (typeof value !== "string") {
        throw invalidInput(`${field} must be a string.`);
    }

    const normalized = value.trim();
    if (required && !normalized) {
        throw invalidInput(`${field} is required.`);
    }
    const length = field === "description" ? Array.from(normalized).length : normalized.length;
    if (length > maxLength) {
        throw invalidInput(`${field} must be ${maxLength} characters or fewer.`);
    }

    return normalized || (field === "description" ? null : normalized);
}

function validateAmount(value, required) {
    if (value === undefined) {
        if (required) {
            throw invalidInput("amount is required.");
        }
        return undefined;
    }

    const amountText = typeof value === "number" ? String(value) : value;
    if (
        (typeof value !== "number" && typeof value !== "string") ||
        !/^\d+(?:\.\d{1,2})?$/.test(amountText)
    ) {
        throw invalidInput("amount must be a positive number with at most two decimal places.");
    }

    const amount = Number(amountText);
    if (!Number.isFinite(amount) || amount <= 0 || amount > MAX_AMOUNT) {
        throw invalidInput("amount must be greater than 0 and fit NUMERIC(12,2).");
    }

    return amount.toFixed(2);
}

function validateDate(value, field, required) {
    if (value === undefined) {
        if (required) {
            throw invalidInput(`${field} is required.`);
        }
        return undefined;
    }

    if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
        throw invalidInput(`${field} must be a valid date in YYYY-MM-DD format.`);
    }

    const [year, month, day] = value.split("-").map(Number);
    const date = new Date(0);
    date.setUTCHours(0, 0, 0, 0);
    date.setUTCFullYear(year, month - 1, day);
    if (
        year < 1 ||
        date.getUTCFullYear() !== year ||
        date.getUTCMonth() !== month - 1 ||
        date.getUTCDate() !== day
    ) {
        throw invalidInput(`${field} must be a valid date in YYYY-MM-DD format.`);
    }

    return value;
}

function validateCreateIncome(input) {
    if (!input || typeof input !== "object" || Array.isArray(input)) {
        throw invalidInput("Income data must be an object.");
    }

    return {
        title: validateText(input.title, "title", 150, true),
        amount: validateAmount(input.amount, true),
        category: validateText(input.category, "category", 100, true),
        payment_method: validateText(input.payment_method, "payment_method", 50, true),
        income_date: validateDate(input.income_date, "income_date", false),
        description: validateText(input.description, "description", MAX_DESCRIPTION_LENGTH, false),
    };
}

function validateUpdateIncome(input) {
    if (!input || typeof input !== "object" || Array.isArray(input)) {
        throw invalidInput("Income data must be an object.");
    }

    const keys = Object.keys(input);
    if (keys.length === 0 || keys.some((key) => !editableFields.includes(key))) {
        throw invalidInput("Provide at least one valid income field to update.");
    }

    const updated = {};
    for (const field of keys) {
        if (field === "title") {
            updated.title = validateText(input.title, "title", 150, true);
        } else if (field === "amount") {
            updated.amount = validateAmount(input.amount, true);
        } else if (field === "category") {
            updated.category = validateText(input.category, "category", 100, true);
        } else if (field === "payment_method") {
            updated.payment_method = validateText(input.payment_method, "payment_method", 50, true);
        } else if (field === "income_date") {
            updated.income_date = validateDate(input.income_date, "income_date", true);
        } else if (field === "description") {
            updated.description = validateText(input.description, "description", MAX_DESCRIPTION_LENGTH, false);
        }
    }
    return updated;
}

function validateIncomeId(id) {
    if (typeof id !== "string" || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)) {
        throw invalidInput("Income id must be a valid UUID.");
    }
    return id;
}

function validateListOptions(query) {
    const page = query.page === undefined ? 1 : Number(query.page);
    const limit = query.limit === undefined ? 10 : Number(query.limit);
    if (!Number.isInteger(page) || page < 1) {
        throw invalidInput("page must be a positive integer.");
    }
    if (!Number.isInteger(limit) || limit < 1 || limit > 100) {
        throw invalidInput("limit must be an integer between 1 and 100.");
    }

    const search = query.search === undefined ? "" : query.search;
    if (typeof search !== "string" || search.length > 200) {
        throw invalidInput("search must be a string of 200 characters or fewer.");
    }

    const startDate = validateDate(query.startDate, "startDate", false);
    const endDate = validateDate(query.endDate, "endDate", false);
    if (startDate && endDate && startDate > endDate) {
        throw invalidInput("startDate must be on or before endDate.");
    }

    const category = query.category === undefined
        ? undefined
        : validateText(query.category, "category", 100, true);
    const sortBy = query.sortBy === undefined ? "income_date" : query.sortBy;
    const sortableColumns = ["income_date", "amount", "title", "category", "created_at", "updated_at"];
    if (typeof sortBy !== "string" || !sortableColumns.includes(sortBy)) {
        throw invalidInput("sortBy is not a supported income field.");
    }

    const order = query.order === undefined ? "desc" : String(query.order).toLowerCase();
    if (!["asc", "desc"].includes(order)) {
        throw invalidInput("order must be asc or desc.");
    }

    return {
        page,
        limit,
        search: search.trim(),
        startDate,
        endDate,
        category,
        sortBy,
        order: order.toUpperCase(),
    };
}

module.exports = {
    validateCreateIncome,
    validateUpdateIncome,
    validateIncomeId,
    validateListOptions,
};
