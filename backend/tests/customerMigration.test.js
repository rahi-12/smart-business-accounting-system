const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const migrationPath = path.resolve(
    __dirname,
    "../../database/migrations/009_customer_management.sql"
);
const migration = fs.readFileSync(migrationPath, "utf8");

test("adds customer soft-delete fields, API length constraints, and active email uniqueness", () => {
    assert.match(migration, /ALTER COLUMN phone TYPE VARCHAR\(30\)/i);
    assert.match(migration, /ADD COLUMN notes TEXT/i);
    assert.match(migration, /ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE/i);
    assert.match(migration, /customers_email_max_length/i);
    assert.match(migration, /customers_address_max_length/i);
    assert.match(migration, /customers_notes_max_length/i);
    assert.match(
        migration,
        /CREATE UNIQUE INDEX customers_active_email_unique\s+ON customers \(user_id, LOWER\(email\)\)\s+WHERE is_active = TRUE AND email IS NOT NULL/i
    );
});
