const incomeService = require("../services/incomeService");

function sendError(res, error, action) {
    if (error.code === "INVALID_INPUT") {
        return res.status(400).json({
            success: false,
            code: error.code,
            message: error.message,
        });
    }

    if (error.code === "INCOME_NOT_FOUND" || error.code === "PROFILE_NOT_FOUND") {
        return res.status(404).json({
            success: false,
            code: error.code,
            message: error.message,
        });
    }

    console.error(`Income ${action} error:`, error.message);
    return res.status(500).json({
        success: false,
        code: `INCOME_${action.toUpperCase()}_FAILED`,
        message: `Unable to ${action} income.`,
    });
}

async function createIncome(req, res) {
    try {
        const income = await incomeService.createIncome(req.user.uid, req.body);
        return res.status(201).json({ success: true, data: income });
    } catch (error) {
        return sendError(res, error, "create");
    }
}

async function listIncome(req, res) {
    try {
        const income = await incomeService.listIncome(req.user.uid, req.query);
        return res.status(200).json({ success: true, data: income });
    } catch (error) {
        return sendError(res, error, "list");
    }
}

async function getIncomeById(req, res) {
    try {
        const income = await incomeService.getIncomeById(req.user.uid, req.params.id);
        return res.status(200).json({ success: true, data: income });
    } catch (error) {
        return sendError(res, error, "get");
    }
}

async function updateIncome(req, res) {
    try {
        const income = await incomeService.updateIncome(req.user.uid, req.params.id, req.body);
        return res.status(200).json({ success: true, data: income });
    } catch (error) {
        return sendError(res, error, "update");
    }
}

async function deleteIncome(req, res) {
    try {
        const result = await incomeService.deleteIncome(req.user.uid, req.params.id);
        return res.status(200).json({ success: true, data: result });
    } catch (error) {
        return sendError(res, error, "delete");
    }
}

module.exports = {
    createIncome,
    listIncome,
    getIncomeById,
    updateIncome,
    deleteIncome,
};
