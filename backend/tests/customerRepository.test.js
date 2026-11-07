const test = require("node:test");
const assert = require("node:assert/strict");

const { pool } = require("../src/config/database");
const customerRepository = require("../src/repositories/customerRepository");

test("scopes every customer query by owner and uses parameters for user values", async () => {
    const originalQuery = pool.query;
    const queries = [];
    pool.query = async (query, values = []) => {
        queries.push({ query, values });
        if (query.includes("FROM users")) {
            return { rows: [{ id: "owner-id" }] };
        }
        if (query.includes("COUNT(*)")) {
            return { rows: [{ total: 0 }] };
        }
        return { rows: [] };
    };

    try {
        await customerRepository.createCustomer("firebase-uid", {
            customer_name: "Sample",
            phone: null,
            email: null,
            address: null,
            notes: null,
        });
        await customerRepository.listCustomers("firebase-uid", {
            page: 1,
            limit: 10,
            search: "Sample",
            includeInactive: false,
            sortBy: "name",
            order: "ASC",
        });
        await customerRepository.getCustomerById("firebase-uid", "customer-id");
        await customerRepository.updateCustomer("firebase-uid", "customer-id", {
            notes: null,
        });
        await customerRepository.deleteCustomer("firebase-uid", "customer-id");

        const customerQueries = queries.filter((entry) => !entry.query.includes("FROM users"));
        assert.equal(customerQueries.length, 6);
        assert.match(customerQueries[0].query, /INSERT INTO customers/);
        assert.match(customerQueries[0].query, /VALUES \(\$1, \$2, \$3, \$4, \$5, \$6\)/);
        assert.match(customerQueries[1].query, /WHERE user_id = \$1 AND is_active = TRUE/);
        assert.match(customerQueries[2].query, /WHERE user_id = \$1 AND is_active = TRUE/);
        assert.match(customerQueries[3].query, /WHERE user_id = \$1 AND id = \$2/);
        assert.match(customerQueries[4].query, /WHERE user_id = \$1 AND id = \$2 AND is_active = TRUE/);
        assert.match(customerQueries[5].query, /WHERE user_id = \$1 AND id = \$2 AND is_active = TRUE/);
        assert.match(customerQueries[5].query, /SET is_active = FALSE/);
        assert.equal(customerQueries[3].values[1], "customer-id");
        assert.equal(customerQueries[4].values[2], null);
    } finally {
        pool.query = originalQuery;
    }
});

test("maps the active-email unique index violation to a specific conflict", async () => {
    const originalQuery = pool.query;
    pool.query = async (query) => {
        if (query.includes("FROM users")) {
            return { rows: [{ id: "owner-id" }] };
        }
        const error = new Error("unique violation");
        error.code = "23505";
        error.constraint = "customers_active_email_unique";
        throw error;
    };

    try {
        await assert.rejects(
            customerRepository.createCustomer("firebase-uid", {
                customer_name: "Sample",
                phone: null,
                email: "sample@example.com",
                address: null,
                notes: null,
            }),
            (error) => error.code === "CUSTOMER_EMAIL_TAKEN"
        );
    } finally {
        pool.query = originalQuery;
    }
});
