const test = require("node:test");
const assert = require("node:assert/strict");

const customerService = require("../src/services/customerService");

const validCustomer = {
    name: "Northwind Services",
    phone: "+1 555 0100",
    email: "billing@example.com",
    address: "100 Market Street",
    notes: "Primary account",
};

const validId = "123e4567-e89b-42d3-a456-426614174000";

test("creates a customer with validated and normalized fields", async () => {
    let received;
    const repository = {
        createCustomer: async (uid, customer) => {
            received = { uid, customer };
            return { id: validId, ...customer, is_active: true };
        },
    };

    const result = await customerService.createCustomer(
        "firebase-uid",
        { ...validCustomer, notes: "  Primary account  " },
        repository
    );

    assert.equal(received.uid, "firebase-uid");
    assert.deepEqual(received.customer, {
        customer_name: "Northwind Services",
        phone: "+1 555 0100",
        email: "billing@example.com",
        address: "100 Market Street",
        notes: "Primary account",
    });
    assert.equal(result.is_active, true);
});

test("rejects invalid customer input before repository access", async () => {
    let called = false;
    const repository = {
        createCustomer: async () => {
            called = true;
        },
        updateCustomer: async () => {
            called = true;
        },
    };

    const invalidCustomers = [
        {},
        { ...validCustomer, name: " " },
        { ...validCustomer, name: "x".repeat(151) },
        { ...validCustomer, phone: "x".repeat(31) },
        { ...validCustomer, email: "not-an-email" },
        { ...validCustomer, email: "x".repeat(146) + "@x.io" },
        { ...validCustomer, address: "x".repeat(501) },
        { ...validCustomer, notes: "x".repeat(5001) },
        { ...validCustomer, name: "Bad\u0000Name" },
        { ...validCustomer, address: "Bad\u0085Address" },
    ];

    for (const input of invalidCustomers) {
        await assert.rejects(
            customerService.createCustomer("firebase-uid", input, repository),
            (error) => error.code === "INVALID_INPUT"
        );
    }

    await assert.rejects(
        customerService.updateCustomer("firebase-uid", "not-a-uuid", { name: "Valid" }, repository),
        (error) => error.code === "INVALID_INPUT"
    );
    assert.equal(called, false);
});

test("normalizes empty optional fields to null on create and update", async () => {
    let created;
    let updated;
    const repository = {
        createCustomer: async (_uid, customer) => {
            created = customer;
            return { id: validId, ...customer };
        },
        updateCustomer: async (_uid, _id, fields) => {
            updated = fields;
            return { id: validId, ...fields };
        },
    };

    await customerService.createCustomer(
        "firebase-uid",
        { name: "No Contact", phone: "", email: " ", address: "", notes: "" },
        repository
    );
    await customerService.updateCustomer(
        "firebase-uid",
        validId,
        { phone: null, email: "", address: null, notes: "  " },
        repository
    );

    assert.deepEqual(created, {
        customer_name: "No Contact",
        phone: null,
        email: null,
        address: null,
        notes: null,
    });
    assert.deepEqual(updated, {
        phone: null,
        email: null,
        address: null,
        notes: null,
    });
});

test("returns paginated customer lists using validated list options", async () => {
    let received;
    const repository = {
        listCustomers: async (_uid, options) => {
            received = options;
            return {
                items: [{ id: validId, name: "Northwind Services" }],
                total: 21,
            };
        },
    };

    const result = await customerService.listCustomers(
        "firebase-uid",
        {
            page: "2",
            limit: "10",
            search: " Northwind ",
            includeInactive: "true",
            sortBy: "updated_at",
            order: "DESC",
        },
        repository
    );

    assert.deepEqual(received, {
        page: 2,
        limit: 10,
        search: "Northwind",
        includeInactive: true,
        sortBy: "updated_at",
        order: "DESC",
    });
    assert.deepEqual(result.pagination, {
        page: 2,
        limit: 10,
        total: 21,
        totalPages: 3,
    });
});

test("rejects invalid list parameters before repository access", async () => {
    let called = false;
    const repository = {
        listCustomers: async () => {
            called = true;
        },
    };

    for (const query of [
        { limit: "101" },
        { includeInactive: "yes" },
        { sortBy: "id; DROP TABLE customers" },
        { order: "sideways" },
        { search: "bad\nsearch" },
    ]) {
        await assert.rejects(
            customerService.listCustomers("firebase-uid", query, repository),
            (error) => error.code === "INVALID_INPUT"
        );
    }
    assert.equal(called, false);
});

test("reads inactive customers by id and reports missing or foreign rows as not found", async () => {
    const repository = {
        getCustomerById: async () => ({ id: validId, name: "Archived", is_active: false }),
    };
    const inactive = await customerService.getCustomerById("firebase-uid", validId, repository);
    assert.equal(inactive.is_active, false);

    await assert.rejects(
        customerService.getCustomerById("firebase-uid", validId, {
            getCustomerById: async () => null,
        }),
        (error) => error.code === "CUSTOMER_NOT_FOUND"
    );
});

test("updates partial fields and soft-deletes active customers", async () => {
    let updatedFields;
    let deletedId;
    const repository = {
        updateCustomer: async (_uid, _id, updates) => {
            updatedFields = updates;
            return {
                id: validId,
                name: updates.customer_name,
                notes: updates.notes,
                is_active: true,
            };
        },
        deleteCustomer: async (_uid, id) => {
            deletedId = id;
            return { id };
        },
    };

    const updated = await customerService.updateCustomer(
        "firebase-uid",
        validId,
        { name: "Renamed", notes: null },
        repository
    );
    const deleted = await customerService.deleteCustomer("firebase-uid", validId, repository);

    assert.deepEqual(updatedFields, { customer_name: "Renamed", notes: null });
    assert.equal(updated.name, "Renamed");
    assert.equal(deletedId, validId);
    assert.deepEqual(deleted, { id: validId });
});
