const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const migrationPath = path.resolve(
    __dirname,
    "../../database/migrations/010_invoice_management.sql"
);
const migration = fs.readFileSync(migrationPath, "utf8");

test("adds invoice snapshots, payment link, status constraints, indexes, and concurrent number counters", () => {
    assert.match(migration, /RENAME COLUMN invoice_date TO issue_date/i);
    assert.match(migration, /RENAME COLUMN product_name TO description/i);
    assert.match(migration, /ADD COLUMN customer_name VARCHAR\(150\)/i);
    assert.match(migration, /ADD COLUMN discount_type VARCHAR\(10\)/i);
    assert.match(migration, /ADD COLUMN tax_rate NUMERIC\(5, 2\)/i);
    assert.match(migration, /ADD COLUMN income_id UUID/i);
    assert.match(migration, /UNIQUE \(income_id\)/i);
    assert.match(migration, /status IN \('draft', 'sent', 'paid', 'cancelled'\)/i);
    assert.match(migration, /CREATE TABLE invoice_number_counters/i);
    assert.match(migration, /PRIMARY KEY \(user_id, invoice_year\)/i);
    assert.match(migration, /invoices_user_status_issue_date_idx/i);
});
