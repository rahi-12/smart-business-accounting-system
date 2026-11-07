const express = require("express");

const {
    createInvoice,
    listInvoices,
    getInvoiceById,
    updateInvoice,
    deleteInvoice,
    sendInvoice,
    cancelInvoice,
    payInvoice,
} = require("../controllers/invoiceController");
const { authenticateUser } = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/", authenticateUser, createInvoice);
router.get("/", authenticateUser, listInvoices);
router.get("/:id", authenticateUser, getInvoiceById);
router.put("/:id", authenticateUser, updateInvoice);
router.delete("/:id", authenticateUser, deleteInvoice);
router.post("/:id/send", authenticateUser, sendInvoice);
router.post("/:id/cancel", authenticateUser, cancelInvoice);
router.post("/:id/pay", authenticateUser, payInvoice);

module.exports = router;
