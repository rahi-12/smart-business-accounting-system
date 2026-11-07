const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const migrationPath = path.resolve(
    __dirname,
    "../../database/migrations/008_limit_transaction_description.sql"
);
const migration = fs.readFileSync(migrationPath, "utf8");

test("limits income and expense descriptions to the API's 5000-character maximum", () => {
    assert.match(
        migration,
        /ALTER TABLE income\s+ADD CONSTRAINT income_description_max_length\s+CHECK \(description IS NULL OR char_length\(description\) <= 5000\);/i
    );
    assert.match(
        migration,
        /ALTER TABLE expenses\s+ADD CONSTRAINT expenses_description_max_length\s+CHECK \(description IS NULL OR char_length\(description\) <= 5000\);/i
    );
});
