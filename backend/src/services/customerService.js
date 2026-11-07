const customerRepository = require("../repositories/customerRepository");
const {
    validateCreateCustomer,
    validateUpdateCustomer,
    validateCustomerId,
    validateListOptions,
} = require("../validators/customerValidator");

function customerNotFound() {
    const error = new Error("Customer record not found.");
    error.code = "CUSTOMER_NOT_FOUND";
    return error;
}

async function createCustomer(firebaseUid, input, repository = customerRepository) {
    const customer = validateCreateCustomer(input);
    const created = await repository.createCustomer(firebaseUid, customer);
    if (!created) {
        throw new Error("Customer record was not returned after creation.");
    }
    return created;
}

async function listCustomers(firebaseUid, query = {}, repository = customerRepository) {
    const options = validateListOptions(query);
    const result = await repository.listCustomers(firebaseUid, options);
    return {
        items: result.items,
        pagination: {
            page: options.page,
            limit: options.limit,
            total: result.total,
            totalPages: Math.ceil(result.total / options.limit),
        },
    };
}

async function getCustomerById(firebaseUid, id, repository = customerRepository) {
    const validId = validateCustomerId(id);
    const customer = await repository.getCustomerById(firebaseUid, validId);
    if (!customer) {
        throw customerNotFound();
    }
    return customer;
}

async function updateCustomer(firebaseUid, id, input, repository = customerRepository) {
    const validId = validateCustomerId(id);
    const updates = validateUpdateCustomer(input);
    const customer = await repository.updateCustomer(firebaseUid, validId, updates);
    if (!customer) {
        throw customerNotFound();
    }
    return customer;
}

async function deleteCustomer(firebaseUid, id, repository = customerRepository) {
    const validId = validateCustomerId(id);
    const deleted = await repository.deleteCustomer(firebaseUid, validId);
    if (!deleted) {
        throw customerNotFound();
    }
    return { id: deleted.id };
}

module.exports = {
    createCustomer,
    listCustomers,
    getCustomerById,
    updateCustomer,
    deleteCustomer,
};
