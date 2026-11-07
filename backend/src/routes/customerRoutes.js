const express = require("express");

const {
    createCustomer,
    listCustomers,
    getCustomerById,
    updateCustomer,
    deleteCustomer,
} = require("../controllers/customerController");
const { authenticateUser } = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/", authenticateUser, createCustomer);
router.get("/", authenticateUser, listCustomers);
router.get("/:id", authenticateUser, getCustomerById);
router.put("/:id", authenticateUser, updateCustomer);
router.delete("/:id", authenticateUser, deleteCustomer);

module.exports = router;
