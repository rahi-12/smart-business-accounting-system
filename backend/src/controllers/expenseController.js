const expenseService = require("../services/expenseService");

function sendError(res, error, action) {
    if (error.code === "INVALID_INPUT") {
        return res.status(400).json({
            success: false,
            code: error.code,
            message: error.message,
        });
    }

    if (error.code === "EXPENSE_NOT_FOUND" || error.code === "PROFILE_NOT_FOUND") {
        return res.status(404).json({
            success: false,
            code: error.code,
            message: error.message,
        });
    }

    console.error(`Expense ${action} error:`, error.message);
    return res.status(500).json({
        success: false,
        code: `EXPENSE_${action.toUpperCase()}_FAILED`,
        message: `Unable to ${action} expense.`,
    });
}

async function createExpense(req, res) {
    try {
        const expense = await expenseService.createExpense(req.user.uid, req.body);
        return res.status(201).json({ success: true, data: expense });
    } catch (error) {
        return sendError(res, error, "create");
    }
}

async function listExpenses(req, res) {
    try {
        const expenses = await expenseService.listExpenses(req.user.uid, req.query);
        return res.status(200).json({ success: true, data: expenses });
    } catch (error) {
        return sendError(res, error, "list");
    }
}

async function getExpenseById(req, res) {
    try {
        const expense = await expenseService.getExpenseById(req.user.uid, req.params.id);
        return res.status(200).json({ success: true, data: expense });
    } catch (error) {
        return sendError(res, error, "get");
    }
}

async function updateExpense(req, res) {
    try {
        const expense = await expenseService.updateExpense(req.user.uid, req.params.id, req.body);
        return res.status(200).json({ success: true, data: expense });
    } catch (error) {
        return sendError(res, error, "update");
    }
}

async function deleteExpense(req, res) {
    try {
        const result = await expenseService.deleteExpense(req.user.uid, req.params.id);
        return res.status(200).json({ success: true, data: result });
    } catch (error) {
        return sendError(res, error, "delete");
    }
}

module.exports = {
    createExpense,
    listExpenses,
    getExpenseById,
    updateExpense,
    deleteExpense,
};
