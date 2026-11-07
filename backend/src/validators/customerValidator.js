const editableFields = ["name", "phone", "email", "address", "notes"];
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const controlCharacters = /[\u0000-\u001f\u007f-\u009f]/u;

function invalidInput(message) {
    const error = new Error(message);
    error.code = "INVALID_INPUT";
    return error;
}

function validateText(value, field, maxLength, required, email = false) {
    if (value === undefined) {
        if (required) {
            throw invalidInput(`${field} is required.`);
        }
        return required ? undefined : null;
    }

    if (value === null && !required) {
        return null;
    }
    if (typeof value !== "string") {
        throw invalidInput(`${field} must be a string.`);
    }
    if (controlCharacters.test(value)) {
        throw invalidInput(`${field} must not contain control characters.`);
    }

    const normalized = value.trim();
    const length = Array.from(normalized).length;
    if (required && !normalized) {
        throw invalidInput(`${field} is required.`);
    }
    if (length > maxLength) {
        throw invalidInput(`${field} must be ${maxLength} characters or fewer.`);
    }
    if (email && normalized && !emailPattern.test(normalized)) {
        throw invalidInput("email must be a valid email address.");
    }

    return normalized || (required ? normalized : null);
}

function validateCreateCustomer(input) {
    if (!input || typeof input !== "object" || Array.isArray(input)) {
        throw invalidInput("Customer data must be an object.");
    }

    return {
        customer_name: validateText(input.name, "name", 150, true),
        phone: validateText(input.phone, "phone", 30, false),
        email: validateText(input.email, "email", 150, false, true),
        address: validateText(input.address, "address", 500, false),
        notes: validateText(input.notes, "notes", 5000, false),
    };
}

function validateUpdateCustomer(input) {
    if (!input || typeof input !== "object" || Array.isArray(input)) {
        throw invalidInput("Customer data must be an object.");
    }

    const keys = Object.keys(input);
    if (keys.length === 0 || keys.some((key) => !editableFields.includes(key))) {
        throw invalidInput("Provide at least one valid customer field to update.");
    }

    const updated = {};
    for (const field of keys) {
        if (field === "name") {
            updated.customer_name = validateText(input.name, "name", 150, true);
        } else if (field === "phone") {
            updated.phone = validateText(input.phone, "phone", 30, false);
        } else if (field === "email") {
            updated.email = validateText(input.email, "email", 150, false, true);
        } else if (field === "address") {
            updated.address = validateText(input.address, "address", 500, false);
        } else if (field === "notes") {
            updated.notes = validateText(input.notes, "notes", 5000, false);
        }
    }
    return updated;
}

function validateCustomerId(id) {
    if (typeof id !== "string" || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)) {
        throw invalidInput("Customer id must be a valid UUID.");
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
    if (controlCharacters.test(search)) {
        throw invalidInput("search must not contain control characters.");
    }

    const includeInactiveValue = query.includeInactive === undefined
        ? "false"
        : String(query.includeInactive).toLowerCase();
    if (!["true", "false"].includes(includeInactiveValue)) {
        throw invalidInput("includeInactive must be true or false.");
    }

    const sortBy = query.sortBy === undefined ? "name" : query.sortBy;
    const sortableColumns = ["name", "email", "phone", "created_at", "updated_at"];
    if (typeof sortBy !== "string" || !sortableColumns.includes(sortBy)) {
        throw invalidInput("sortBy is not a supported customer field.");
    }

    const order = query.order === undefined ? "asc" : String(query.order).toLowerCase();
    if (!["asc", "desc"].includes(order)) {
        throw invalidInput("order must be asc or desc.");
    }

    return {
        page,
        limit,
        search: search.trim(),
        includeInactive: includeInactiveValue === "true",
        sortBy,
        order: order.toUpperCase(),
    };
}

module.exports = {
    validateCreateCustomer,
    validateUpdateCustomer,
    validateCustomerId,
    validateListOptions,
};
