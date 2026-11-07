const invoiceService = require("../services/invoiceService");

function sendError(res, error, action) {
    if (error.code === "INVALID_INPUT") {
        return res.status(400).json({
            success: false,
            code: error.code,
            message: error.message,
        });
    }
    if (["INVOICE_NOT_FOUND", "CUSTOMER_NOT_FOUND", "PROFILE_NOT_FOUND"].includes(error.code)) {
        return res.status(404).json({
            success: false,
            code: error.code,
            message: error.message,
        });
    }
    if ([
        "INVOICE_INVALID_TRANSITION",
        "INVOICE_NOT_EDITABLE",
        "INVOICE_NOT_DELETABLE",
        "INVOICE_ITEMS_REQUIRED",
        "INVOICE_ZERO_TOTAL",
    ].includes(error.code)) {
        return res.status(409).json({
            success: false,
            code: error.code,
            message: error.message,
        });
    }
    console.error(`Invoice ${action} error:`, error.message);
    return res.status(500).json({
        success: false,
        code: `INVOICE_${action.toUpperCase()}_FAILED`,
        message: `Unable to ${action} invoice.`,
    });
}

async function createInvoice(req, res) {
    try {
        const invoice = await invoiceService.createInvoice(req.user.uid, req.body);
        return res.status(201).json({ success: true, data: invoice });
    } catch (error) {
        return sendError(res, error, "create");
    }
}

async function listInvoices(req, res) {
    try {
        const invoices = await invoiceService.listInvoices(req.user.uid, req.query);
        return res.status(200).json({ success: true, data: invoices });
    } catch (error) {
        return sendError(res, error, "list");
    }
}

async function getInvoiceById(req, res) {
    try {
        const invoice = await invoiceService.getInvoiceById(req.user.uid, req.params.id);
        return res.status(200).json({ success: true, data: invoice });
    } catch (error) {
        return sendError(res, error, "get");
    }
}

async function updateInvoice(req, res) {
    try {
        const invoice = await invoiceService.updateInvoice(req.user.uid, req.params.id, req.body);
        return res.status(200).json({ success: true, data: invoice });
    } catch (error) {
        return sendError(res, error, "update");
    }
}

async function deleteInvoice(req, res) {
    try {
        const deleted = await invoiceService.deleteInvoice(req.user.uid, req.params.id);
        return res.status(200).json({ success: true, data: deleted });
    } catch (error) {
        return sendError(res, error, "delete");
    }
}

async function sendInvoice(req, res) {
    try {
        const invoice = await invoiceService.sendInvoice(req.user.uid, req.params.id);
        return res.status(200).json({ success: true, data: invoice });
    } catch (error) {
        return sendError(res, error, "send");
    }
}

async function cancelInvoice(req, res) {
    try {
        const invoice = await invoiceService.cancelInvoice(req.user.uid, req.params.id);
        return res.status(200).json({ success: true, data: invoice });
    } catch (error) {
        return sendError(res, error, "cancel");
    }
}

async function payInvoice(req, res) {
    try {
        const invoice = await invoiceService.payInvoice(req.user.uid, req.params.id, req.body);
        return res.status(200).json({ success: true, data: invoice });
    } catch (error) {
        return sendError(res, error, "pay");
    }
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
