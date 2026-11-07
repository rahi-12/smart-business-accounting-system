const {
    calculateInvoice,
    validateCalculationOptions,
} = require("../services/invoiceCalculator");
const { validateCreateIncome } = require("./incomeValidator");

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const controlCharacters = /[\u0000-\u001f\u007f-\u009f]/u;
const editableFields = [
    "customer_id",
    "issue_date",
    "due_date",
    "discount_type",
    "discount_value",
    "tax_rate",
    "notes",
    "items",
];

function invalidInput(message) {
    const error = new Error(message);
    error.code = "INVALID_INPUT";
    return error;
}

function validateDate(value, field, required) {
    if (value === undefined || value === null) {
        if (required) {
            throw invalidInput(`${field} is required.`);
        }
        return null;
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

function validateText(value, field, maxLength, required, nullable = false) {
    if (value === undefined) {
        if (required) {
            throw invalidInput(`${field} is required.`);
        }
        return nullable ? null : undefined;
    }
    if (value === null && nullable) {
        return null;
    }
    if (typeof value !== "string") {
        throw invalidInput(`${field} must be a string.`);
    }
    if (controlCharacters.test(value)) {
        throw invalidInput(`${field} must not contain control characters.`);
    }
    const normalized = value.trim();
    if (required && !normalized) {
        throw invalidInput(`${field} is required.`);
    }
    if (Array.from(normalized).length > maxLength) {
        throw invalidInput(`${field} must be ${maxLength} characters or fewer.`);
    }
    return normalized || (nullable ? null : normalized);
}

function validateCustomerId(value) {
    if (typeof value !== "string" || !uuidPattern.test(value)) {
        throw invalidInput("customer_id must be a valid UUID.");
    }
    return value;
}

function validateItems(value, required) {
    if (value === undefined && !required) {
        return undefined;
    }
    if (!Array.isArray(value) || value.length < 1 || value.length > 100) {
        throw invalidInput("items must contain between 1 and 100 items.");
    }
    const items = value.map((item, index) => {
        if (!item || typeof item !== "object" || Array.isArray(item)) {
            throw invalidInput(`items[${index}] must be an object.`);
        }
        return {
            description: validateText(item.description, `items[${index}].description`, 300, true),
            quantity: item.quantity,
            unit_price: item.unit_price,
        };
    });
    return calculateInvoice(items).items;
}

function validateInvoiceFields(input, partial) {
    if (!input || typeof input !== "object" || Array.isArray(input)) {
        throw invalidInput("Invoice data must be an object.");
    }
    if (partial) {
        const keys = Object.keys(input);
        if (keys.length === 0 || keys.some((key) => !editableFields.includes(key))) {
            throw invalidInput("Provide at least one valid invoice field to update.");
        }
    }

    const result = {};
    if (!partial || Object.hasOwn(input, "customer_id")) {
        result.customer_id = validateCustomerId(input.customer_id);
    }
    if (!partial || Object.hasOwn(input, "issue_date")) {
        result.issue_date = validateDate(input.issue_date, "issue_date", true);
    }
    if (Object.hasOwn(input, "due_date") || !partial) {
        result.due_date = validateDate(input.due_date, "due_date", false);
    }
    if (Object.hasOwn(input, "discount_type") || !partial) {
        result.discount_type = input.discount_type === undefined ? "fixed" : input.discount_type;
        if (!["fixed", "percent"].includes(result.discount_type)) {
            throw invalidInput("discount_type must be percent or fixed.");
        }
    }
    if (Object.hasOwn(input, "discount_value") || !partial) {
        result.discount_value = input.discount_value === undefined ? "0" : input.discount_value;
    }
    if (Object.hasOwn(input, "tax_rate") || !partial) {
        result.tax_rate = input.tax_rate === undefined ? "0" : input.tax_rate;
    }
    if (Object.hasOwn(input, "notes") || !partial) {
        result.notes = validateText(input.notes, "notes", 5000, false, true);
    }
    if (Object.hasOwn(input, "items") || !partial) {
        result.items = validateItems(input.items, true);
    }

    if (result.issue_date && result.due_date && result.due_date < result.issue_date) {
        throw invalidInput("due_date must be on or after issue_date.");
    }
    const calculationOptions = {};
    for (const field of ["discount_type", "discount_value", "tax_rate"]) {
        if (Object.hasOwn(result, field)) {
            calculationOptions[field] = result[field];
        }
    }
    if (Object.keys(calculationOptions).length > 0) {
        if (calculationOptions.discount_value !== undefined && calculationOptions.discount_type === undefined) {
            validateCalculationOptions({
                discount_type: "fixed",
                discount_value: calculationOptions.discount_value,
            });
        } else {
            validateCalculationOptions(calculationOptions);
        }
    }
    return result;
}

function validateCreateInvoice(input) {
    const fields = validateInvoiceFields(input, false);
    const calculation = calculateInvoice(fields.items, fields);
    return { ...fields, ...calculation };
}

function validateUpdateInvoice(input) {
    if (!input || typeof input !== "object" || Array.isArray(input)) {
        throw invalidInput("Invoice data must be an object.");
    }
    const ignoredTotals = new Set(["subtotal", "tax", "total", "total_amount"]);
    const editableInput = Object.fromEntries(
        Object.entries(input).filter(([field]) => !ignoredTotals.has(field))
    );
    return validateInvoiceFields(editableInput, true);
}

function validateInvoiceId(id) {
    if (typeof id !== "string" || !uuidPattern.test(id)) {
        throw invalidInput("Invoice id must be a valid UUID.");
    }
    return id;
}

function validatePayment(input) {
    if (!input || typeof input !== "object" || Array.isArray(input)) {
        throw invalidInput("Invoice payment data must be an object.");
    }
    if (typeof input.payment_method === "string" && controlCharacters.test(input.payment_method)) {
        throw invalidInput("payment_method must not contain control characters.");
    }
    if (input.payment_date === undefined) {
        throw invalidInput("payment_date is required.");
    }
    const validated = validateCreateIncome({
        title: "Invoice Payment",
        amount: "0.01",
        category: "Invoice Payment",
        payment_method: input.payment_method,
        income_date: input.payment_date,
    });
    return {
        payment_method: validated.payment_method,
        payment_date: validated.income_date,
    };
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
    if (controlCharacters.test(search)) {
        throw invalidInput("search must not contain control characters.");
    }
    const startDate = validateDate(query.startDate, "startDate", false);
    const endDate = validateDate(query.endDate, "endDate", false);
    if (startDate && endDate && startDate > endDate) {
        throw invalidInput("startDate must be on or before endDate.");
    }
    const status = query.status;
    if (status !== undefined && !["draft", "sent", "paid", "cancelled"].includes(status)) {
        throw invalidInput("status is not a supported invoice status.");
    }
    const sortableColumns = [
        "invoice_number",
        "issue_date",
        "due_date",
        "customer_name",
        "total_amount",
        "status",
        "created_at",
        "updated_at",
    ];
    const sortBy = query.sortBy === undefined ? "issue_date" : query.sortBy;
    if (typeof sortBy !== "string" || !sortableColumns.includes(sortBy)) {
        throw invalidInput("sortBy is not a supported invoice field.");
    }
    const order = query.order === undefined ? "desc" : String(query.order).toLowerCase();
    if (!["asc", "desc"].includes(order)) {
        throw invalidInput("order must be asc or desc.");
    }
    return {
        page,
        limit,
        search: search.trim(),
        status,
        startDate,
        endDate,
        sortBy,
        order: order.toUpperCase(),
    };
}

module.exports = {
    validateCreateInvoice,
    validateUpdateInvoice,
    validateInvoiceId,
    validatePayment,
    validateListOptions,
};
