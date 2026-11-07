const invoiceRepository = require("../repositories/invoiceRepository");
const {
    validateCreateInvoice,
    validateUpdateInvoice,
    validateInvoiceId,
    validatePayment,
    validateListOptions,
} = require("../validators/invoiceValidator");

function invoiceNotFound() {
    const error = new Error("Invoice record not found.");
    error.code = "INVOICE_NOT_FOUND";
    return error;
}

function normalizeAmount(value) {
    const amount = Number(value);
    if (value === null || value === undefined || !Number.isFinite(amount)) {
        throw new Error("Invoice contained an invalid monetary value.");
    }
    return Number(amount.toFixed(2));
}

function normalizeInvoice(invoice) {
    if (!invoice) {
        return null;
    }
    const result = {
        ...invoice,
        subtotal: normalizeAmount(invoice.subtotal),
        discount_value: normalizeAmount(invoice.discount_value),
        discount: normalizeAmount(invoice.discount),
        tax_rate: normalizeAmount(invoice.tax_rate),
        tax: normalizeAmount(invoice.tax),
        total_amount: normalizeAmount(invoice.total_amount),
    };
    if (invoice.items) {
        result.items = invoice.items.map((item) => ({
            ...item,
            quantity: normalizeAmount(item.quantity),
            unit_price: normalizeAmount(item.unit_price),
            line_total: normalizeAmount(item.line_total),
        }));
    }
    return result;
}

async function createInvoice(firebaseUid, input, repository = invoiceRepository) {
    const invoice = validateCreateInvoice(input);
    const created = await repository.createInvoice(firebaseUid, invoice);
    if (!created) {
        throw new Error("Invoice record was not returned after creation.");
    }
    return normalizeInvoice(created);
}

async function listInvoices(firebaseUid, query = {}, repository = invoiceRepository) {
    const options = validateListOptions(query);
    const result = await repository.listInvoices(firebaseUid, options);
    return {
        items: result.items.map(normalizeInvoice),
        pagination: {
            page: options.page,
            limit: options.limit,
            total: result.total,
            totalPages: Math.ceil(result.total / options.limit),
        },
    };
}

async function getInvoiceById(firebaseUid, id, repository = invoiceRepository) {
    const validId = validateInvoiceId(id);
    const invoice = await repository.getInvoiceById(firebaseUid, validId);
    if (!invoice) {
        throw invoiceNotFound();
    }
    return normalizeInvoice(invoice);
}

async function updateInvoice(firebaseUid, id, input, repository = invoiceRepository) {
    const validId = validateInvoiceId(id);
    const updates = validateUpdateInvoice(input);
    const invoice = await repository.updateInvoice(firebaseUid, validId, updates);
    if (!invoice) {
        throw invoiceNotFound();
    }
    return normalizeInvoice(invoice);
}

async function deleteInvoice(firebaseUid, id, repository = invoiceRepository) {
    const validId = validateInvoiceId(id);
    const deleted = await repository.deleteInvoice(firebaseUid, validId);
    if (!deleted) {
        throw invoiceNotFound();
    }
    return { id: deleted.id };
}

async function sendInvoice(firebaseUid, id, repository = invoiceRepository) {
    const validId = validateInvoiceId(id);
    const invoice = await repository.transitionInvoice(firebaseUid, validId, "sent");
    if (!invoice) {
        throw invoiceNotFound();
    }
    return normalizeInvoice(invoice);
}

async function cancelInvoice(firebaseUid, id, repository = invoiceRepository) {
    const validId = validateInvoiceId(id);
    const invoice = await repository.transitionInvoice(firebaseUid, validId, "cancelled");
    if (!invoice) {
        throw invoiceNotFound();
    }
    return normalizeInvoice(invoice);
}

async function payInvoice(firebaseUid, id, input, repository = invoiceRepository) {
    const validId = validateInvoiceId(id);
    const payment = validatePayment(input);
    const invoice = await repository.payInvoice(firebaseUid, validId, payment);
    if (!invoice) {
        throw invoiceNotFound();
    }
    return normalizeInvoice(invoice);
}

module.exports = {
    createInvoice,
    listInvoices,
    getInvoiceById,
    updateInvoice,
    deleteInvoice,
    sendInvoice,
    cancelInvoice,
    payInvoice,
};
