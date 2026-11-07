const express = require("express");

const {
    createExpense,
    listExpenses,
    getExpenseById,
    updateExpense,
    deleteExpense,
} = require("../controllers/expenseController");
const { authenticateUser } = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/", authenticateUser, createExpense);
router.get("/", authenticateUser, listExpenses);
router.get("/:id", authenticateUser, getExpenseById);
router.put("/:id", authenticateUser, updateExpense);
router.delete("/:id", authenticateUser, deleteExpense);

module.exports = router;
