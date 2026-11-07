const customerService = require("../services/customerService");

function sendError(res, error, action) {
    if (error.code === "INVALID_INPUT") {
        return res.status(400).json({
            success: false,
            code: error.code,
            message: error.message,
        });
    }

    if (error.code === "CUSTOMER_NOT_FOUND" || error.code === "PROFILE_NOT_FOUND") {
        return res.status(404).json({
            success: false,
            code: error.code,
            message: error.message,
        });
    }

    if (error.code === "CUSTOMER_EMAIL_TAKEN") {
        return res.status(409).json({
            success: false,
            code: error.code,
            message: error.message,
        });
    }

    console.error(`Customer ${action} error:`, error.message);
    return res.status(500).json({
        success: false,
        code: `CUSTOMER_${action.toUpperCase()}_FAILED`,
        message: `Unable to ${action} customer${action === "list" ? "s" : ""}.`,
    });
}

async function createCustomer(req, res) {
    try {
        const customer = await customerService.createCustomer(req.user.uid, req.body);
        return res.status(201).json({ success: true, data: customer });
    } catch (error) {
        return sendError(res, error, "create");
    }
}

async function listCustomers(req, res) {
    try {
        const customers = await customerService.listCustomers(req.user.uid, req.query);
        return res.status(200).json({ success: true, data: customers });
    } catch (error) {
        return sendError(res, error, "list");
    }
}

async function getCustomerById(req, res) {
    try {
        const customer = await customerService.getCustomerById(req.user.uid, req.params.id);
        return res.status(200).json({ success: true, data: customer });
    } catch (error) {
        return sendError(res, error, "get");
    }
}

async function updateCustomer(req, res) {
    try {
        const customer = await customerService.updateCustomer(
            req.user.uid,
            req.params.id,
            req.body
        );
        return res.status(200).json({ success: true, data: customer });
    } catch (error) {
        return sendError(res, error, "update");
    }
}

async function deleteCustomer(req, res) {
    try {
        const result = await customerService.deleteCustomer(req.user.uid, req.params.id);
        return res.status(200).json({ success: true, data: result });
    } catch (error) {
        return sendError(res, error, "delete");
    }
}

module.exports = {
    createCustomer,
    listCustomers,
    getCustomerById,
    updateCustomer,
    deleteCustomer,
};
