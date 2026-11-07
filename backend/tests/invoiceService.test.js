const test = require("node:test");
const assert = require("node:assert/strict");

const invoiceService = require("../src/services/invoiceService");

const id = "123e4567-e89b-42d3-a456-426614174000";
const invoiceInput = {
    customer_id: id,
    issue_date: "2026-05-01",
    due_date: "2026-05-31",
    items: [{ description: "Consulting", quantity: "3", unit_price: "33.33" }],
    subtotal: "1.00",
    tax: "99.00",
    total: "100.00",
};

test("creates invoices with backend-calculated totals and ignores client totals", async () => {
    let received;
    const repository = {
        createInvoice: async (_uid, invoice) => {
            received = invoice;
            return {
                id,
                ...invoice,
                invoice_number: "INV-2026-0001",
                status: "draft",
                items: invoice.items,
            };
        },
    };
    const created = await invoiceService.createInvoice("firebase-uid", invoiceInput, repository);

    assert.equal(received.subtotal, "99.99");
    assert.equal(received.tax, "0.00");
    assert.equal(received.total_amount, "99.99");
    assert.equal(Object.hasOwn(received, "total"), false);
    assert.equal(created.items[0].line_total, 99.99);
    assert.equal(created.status, "draft");
});

test("validates invoice body, dates, UUIDs, list options, and payment inputs before repository access", async () => {
    let called = false;
    const repository = {
        createInvoice: async () => { called = true; },
        updateInvoice: async () => { called = true; },
        listInvoices: async () => { called = true; },
        payInvoice: async () => { called = true; },
    };
    for (const input of [
        { ...invoiceInput, customer_id: "bad" },
        { ...invoiceInput, issue_date: "0000-01-01" },
        { ...invoiceInput, due_date: "2026-04-30" },
        { ...invoiceInput, items: [{ description: "Bad\u0000item", quantity: "1", unit_price: "1" }] },
        { ...invoiceInput, items: [{ description: "x", quantity: "0", unit_price: "1" }] },
        { ...invoiceInput, items: [{ description: "x", quantity: "1", unit_price: "-1" }] },
        { ...invoiceInput, items: [] },
    ]) {
        await assert.rejects(
            invoiceService.createInvoice("firebase-uid", input, repository),
            (error) => error.code === "INVALID_INPUT"
        );
    }
    await assert.rejects(
        invoiceService.updateInvoice("firebase-uid", "bad", { notes: "ok" }, repository),
        (error) => error.code === "INVALID_INPUT"
    );
    await assert.rejects(
        invoiceService.listInvoices("firebase-uid", { status: "unpaid" }, repository),
        (error) => error.code === "INVALID_INPUT"
    );
    await assert.rejects(
        invoiceService.payInvoice("firebase-uid", id, { payment_method: "Card" }, repository),
        (error) => error.code === "INVALID_INPUT"
    );
    assert.equal(called, false);
});

test("lists invoices using the existing pagination response shape", async () => {
    let options;
    const result = await invoiceService.listInvoices(
        "firebase-uid",
        { page: "2", limit: "10", status: "sent", sortBy: "total_amount", order: "ASC" },
        {
            listInvoices: async (_uid, value) => {
                options = value;
                return {
                    items: [{
                        id,
                        subtotal: "12.00",
                        discount_value: "0.00",
                        discount: "0.00",
                        tax_rate: "0.00",
                        tax: "0.00",
                        total_amount: "12.00",
                    }],
                    total: 21,
                };
            },
        }
    );
    assert.equal(options.page, 2);
    assert.equal(options.status, "sent");
    assert.equal(result.items[0].total_amount, 12);
    assert.deepEqual(result.pagination, { page: 2, limit: 10, total: 21, totalPages: 3 });
});

test("ignores client totals on draft update while recalculating editable values", async () => {
    let updates;
    await invoiceService.updateInvoice(
        "firebase-uid",
        id,
        { notes: "Updated", subtotal: "1.00", tax: "99.00", total: "100.00", total_amount: "101.00" },
        {
            updateInvoice: async (_uid, _id, fields) => {
                updates = fields;
                return {
                    id,
                    subtotal: "3.00",
                    discount_value: "0.00",
                    discount: "0.00",
                    tax_rate: "0.00",
                    tax: "0.00",
                    total_amount: "3.00",
                    items: [],
                };
            },
        }
    );
    assert.deepEqual(updates, { notes: "Updated" });
});
