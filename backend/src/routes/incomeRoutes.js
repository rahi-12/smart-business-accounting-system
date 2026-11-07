const express = require("express");

const {
    createIncome,
    listIncome,
    getIncomeById,
    updateIncome,
    deleteIncome,
} = require("../controllers/incomeController");
const { authenticateUser } = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/", authenticateUser, createIncome);
router.get("/", authenticateUser, listIncome);
router.get("/:id", authenticateUser, getIncomeById);
router.put("/:id", authenticateUser, updateIncome);
router.delete("/:id", authenticateUser, deleteIncome);

module.exports = router;
