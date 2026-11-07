const test = require("node:test");
const assert = require("node:assert/strict");

const { pool } = require("../src/config/database");
const invoiceService = require("../src/services/invoiceService");

const invoiceId = "123e4567-e89b-42d3-a456-426614174000";

test("pay inserts one income and double pay conflicts without inserting another", async () => {
    const originalQuery = pool.query;
    const originalConnect = pool.connect;
    let status = "sent";
    let incomeId = null;
    const incomes = [];
    const transactionStatements = [];

    pool.query = async (query) => {
        if (query.includes("FROM users")) {
            return { rows: [{ id: "owner-id" }] };
        }
        throw new Error("Unexpected pool query in invoice pay test.");
    };
    pool.connect = async () => ({
        query: async (query, values = []) => {
            transactionStatements.push(query);
            if (query === "BEGIN" || query === "COMMIT" || query === "ROLLBACK") {
                return { rows: [] };
            }
            if (query.includes("SELECT id, invoice_number, total_amount, status")) {
                return {
                    rows: [{ id: invoiceId, invoice_number: "INV-2026-0001", total_amount: "125.50", status }],
                };
            }
            if (query.includes("INSERT INTO income")) {
                const newIncomeId = `income-${incomes.length + 1}`;
                incomes.push({ id: newIncomeId, values });
                return { rows: [{ id: newIncomeId }] };
            }
            if (query.includes("UPDATE invoices") && query.includes("SET status = 'paid'")) {
                status = "paid";
                incomeId = values[2];
                return { rows: [] };
            }
            if (query.includes("FROM invoices") && query.includes("LIMIT 1")) {
                return {
                    rows: [{
                        id: invoiceId,
                        invoice_number: "INV-2026-0001",
                        status,
                        issue_date: "2026-05-01",
                        due_date: null,
                        customer_id: "customer-id",
                        customer_name: "Customer",
                        customer_email: null,
                        customer_phone: null,
                        customer_address: null,
                        subtotal: "125.50",
                        discount_type: "fixed",
                        discount_value: "0.00",
                        discount: "0.00",
                        tax_rate: "0.00",
                        tax: "0.00",
                        total_amount: "125.50",
                        income_id: incomeId,
                        paid_at: "2026-06-01T00:00:00.000Z",
                        notes: null,
                    }],
                };
            }
            if (query.includes("FROM invoice_items")) {
                return { rows: [] };
            }
            throw new Error(`Unexpected client query in invoice pay test: ${query}`);
        },
        release: () => {},
    });

    try {
        const paid = await invoiceService.payInvoice(
            "firebase-uid",
            invoiceId,
            { payment_method: "Bank transfer", payment_date: "2026-06-01" }
        );
        assert.equal(paid.status, "paid");
        assert.equal(paid.income_id, "income-1");
        assert.equal(incomes.length, 1);
        assert.match(transactionStatements[1], /FOR UPDATE/);
        assert.equal(incomes[0].values[1], "Invoice INV-2026-0001");
        assert.equal(incomes[0].values[2], "125.50");
        assert.equal(incomes[0].values[3], "Invoice Payment");
        assert.equal(incomes[0].values[4], "Bank transfer");
        assert.equal(incomes[0].values[5], "2026-06-01");

        await assert.rejects(
            invoiceService.payInvoice(
                "firebase-uid",
                invoiceId,
                { payment_method: "Bank transfer", payment_date: "2026-06-01" }
            ),
            (error) => error.code === "INVOICE_INVALID_TRANSITION"
        );
        assert.equal(incomes.length, 1);
        assert.equal(transactionStatements.includes("ROLLBACK"), true);
    } finally {
        pool.query = originalQuery;
        pool.connect = originalConnect;
    }
});

test("rolls back the income when updating the invoice to paid fails", async () => {
    const originalQuery = pool.query;
    const originalConnect = pool.connect;
    let status = "sent";
    let pendingIncome = null;
    let persistedIncomeCount = 0;
    let rolledBack = false;

    pool.query = async (query) => {
        if (query.includes("FROM users")) {
            return { rows: [{ id: "owner-id" }] };
        }
        throw new Error("Unexpected pool query in invoice rollback test.");
    };
    pool.connect = async () => ({
        query: async (query) => {
            if (query === "BEGIN") {
                return { rows: [] };
            }
            if (query === "COMMIT") {
                if (pendingIncome) {
                    persistedIncomeCount += 1;
                }
                return { rows: [] };
            }
            if (query === "ROLLBACK") {
                pendingIncome = null;
                rolledBack = true;
                return { rows: [] };
            }
            if (query.includes("SELECT id, invoice_number, total_amount, status")) {
                return {
                    rows: [{
                        id: invoiceId,
                        invoice_number: "INV-2026-0001",
                        total_amount: "125.50",
                        status,
                    }],
                };
            }
            if (query.includes("INSERT INTO income")) {
                pendingIncome = { id: "income-pending" };
                return { rows: [{ id: pendingIncome.id }] };
            }
            if (query.includes("UPDATE invoices") && query.includes("SET status = 'paid'")) {
                throw new Error("Invoice update failed.");
            }
            throw new Error(`Unexpected client query in invoice rollback test: ${query}`);
        },
        release: () => {},
    });

    try {
        await assert.rejects(
            invoiceService.payInvoice(
                "firebase-uid",
                invoiceId,
                { payment_method: "Bank transfer", payment_date: "2026-06-01" }
            ),
            /Invoice update failed/
        );
        assert.equal(status, "sent");
        assert.equal(persistedIncomeCount, 0);
        assert.equal(rolledBack, true);
    } finally {
        pool.query = originalQuery;
        pool.connect = originalConnect;
    }
});
