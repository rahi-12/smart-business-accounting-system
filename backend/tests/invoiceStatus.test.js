const test = require("node:test");
const assert = require("node:assert/strict");

const { canTransition, assertTransition } = require("../src/services/invoiceStatus");

test("allows only the specified invoice status transitions", () => {
    const allowed = [
        ["draft", "sent"],
        ["draft", "cancelled"],
        ["sent", "paid"],
        ["sent", "cancelled"],
    ];
    for (const [from, to] of allowed) {
        assert.equal(canTransition(from, to), true);
        assert.doesNotThrow(() => assertTransition(from, to));
    }

    for (const from of ["draft", "sent", "paid", "cancelled"]) {
        for (const to of ["draft", "sent", "paid", "cancelled"]) {
            if (!allowed.some(([allowedFrom, allowedTo]) => allowedFrom === from && allowedTo === to)) {
                assert.equal(canTransition(from, to), false);
                assert.throws(
                    () => assertTransition(from, to),
                    (error) => error.code === "INVOICE_INVALID_TRANSITION"
                );
            }
        }
    }
});
