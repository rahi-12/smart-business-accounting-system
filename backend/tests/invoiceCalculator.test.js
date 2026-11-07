const test = require("node:test");
const assert = require("node:assert/strict");

const { calculateInvoice } = require("../src/services/invoiceCalculator");

function item(quantity, unit_price) {
    return { description: "Service", quantity, unit_price };
}

test("calculates decimal quantities in minor units without floating-point drift", () => {
    assert.equal(calculateInvoice([item("0.1", "3.00")]).items[0].line_total, "0.30");
    assert.equal(calculateInvoice([item("3", "33.33")]).items[0].line_total, "99.99");
});

test("rounds percentage discounts half up to cents", () => {
    const result = calculateInvoice([item("1", "0.01")], {
        discount_type: "percent",
        discount_value: "50",
    });
    assert.equal(result.discount, "0.01");
    assert.equal(result.total_amount, "0.00");
});

test("rounds 7.5 percent and 15 percent tax half up", () => {
    const sevenPointFive = calculateInvoice([item("1", "1.00")], { tax_rate: "7.5" });
    const fifteen = calculateInvoice([item("1", "1.00")], { tax_rate: "15" });
    assert.equal(sevenPointFive.tax, "0.08");
    assert.equal(fifteen.tax, "0.15");
});

test("allows a discount equal to subtotal", () => {
    const result = calculateInvoice([item("2", "5.00")], {
        discount_type: "fixed",
        discount_value: "10.00",
    });
    assert.equal(result.discount, "10.00");
    assert.equal(result.total_amount, "0.00");
});

test("rejects a fixed discount larger than subtotal", () => {
    assert.throws(
        () => calculateInvoice([item("1", "9.99")], {
            discount_type: "fixed",
            discount_value: "10.00",
        }),
        (error) => error.code === "INVALID_INPUT" && /cannot exceed the subtotal/.test(error.message)
    );
});

test("rejects line and subtotal overflow beyond NUMERIC(12,2)", () => {
    assert.throws(
        () => calculateInvoice([item("9999999999.99", "9999999999.99")]),
        (error) => error.code === "INVALID_INPUT" && /NUMERIC\(12,2\)/.test(error.message)
    );
    assert.throws(
        () => calculateInvoice([item("1", "9999999999.99"), item("1", "0.01")]),
        (error) => error.code === "INVALID_INPUT" && /subtotal exceeds NUMERIC\(12,2\)/.test(error.message)
    );
    assert.throws(
        () => calculateInvoice([item("9".repeat(100000), "1")]),
        (error) => error.code === "INVALID_INPUT" && /supported numeric range/.test(error.message)
    );
});
