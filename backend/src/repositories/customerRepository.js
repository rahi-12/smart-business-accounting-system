const { pool } = require("../config/database");
const { findUserByFirebaseUid } = require("./userRepository");

const sortableColumns = {
    name: "customer_name",
    email: "email",
    phone: "phone",
    created_at: "created_at",
    updated_at: "updated_at",
};

const selectedColumns = `
    id,
    customer_name AS name,
    phone,
    email,
    address,
    notes,
    is_active,
    created_at,
    updated_at
`;

async function getUserId(firebaseUid) {
    const user = await findUserByFirebaseUid(firebaseUid);
    if (!user) {
        const error = new Error("User profile not found.");
        error.code = "PROFILE_NOT_FOUND";
        throw error;
    }
    return user.id;
}

function emailTaken(error) {
    if (error.code === "23505" && error.constraint === "customers_active_email_unique") {
        const duplicate = new Error("An active customer with this email already exists.");
        duplicate.code = "CUSTOMER_EMAIL_TAKEN";
        throw duplicate;
    }
    throw error;
}

async function createCustomer(firebaseUid, customer) {
    const userId = await getUserId(firebaseUid);
    try {
        const result = await pool.query(
            `
                INSERT INTO customers (user_id, customer_name, phone, email, address, notes)
                VALUES ($1, $2, $3, $4, $5, $6)
                RETURNING ${selectedColumns}
            `,
            [
                userId,
                customer.customer_name,
                customer.phone,
                customer.email,
                customer.address,
                customer.notes,
            ]
        );
        return result.rows[0] || null;
    } catch (error) {
        return emailTaken(error);
    }
}

async function listCustomers(firebaseUid, options) {
    const userId = await getUserId(firebaseUid);
    const sortColumn = sortableColumns[options.sortBy];
    if (!sortColumn) {
        const error = new Error("Unsupported customer sort column.");
        error.code = "INVALID_INPUT";
        throw error;
    }

    const conditions = ["user_id = $1"];
    const values = [userId];

    if (!options.includeInactive) {
        conditions.push("is_active = TRUE");
    }
    if (options.search) {
        values.push(`%${options.search}%`);
        conditions.push(
            `(customer_name ILIKE $${values.length} OR email ILIKE $${values.length} OR phone ILIKE $${values.length})`
        );
    }

    const whereClause = conditions.join(" AND ");
    const countResult = await pool.query(
        `SELECT COUNT(*)::int AS total FROM customers WHERE ${whereClause}`,
        values
    );
    const pageValues = [...values, options.limit, (options.page - 1) * options.limit];
    const result = await pool.query(
        `
            SELECT ${selectedColumns}
            FROM customers
            WHERE ${whereClause}
            ORDER BY ${sortColumn} ${options.order}, id ${options.order}
            LIMIT $${pageValues.length - 1} OFFSET $${pageValues.length}
        `,
        pageValues
    );

    return {
        items: result.rows,
        total: countResult.rows[0].total,
    };
}

async function getCustomerById(firebaseUid, id) {
    const userId = await getUserId(firebaseUid);
    const result = await pool.query(
        `
            SELECT ${selectedColumns}
            FROM customers
            WHERE user_id = $1 AND id = $2
            LIMIT 1
        `,
        [userId, id]
    );
    return result.rows[0] || null;
}

async function updateCustomer(firebaseUid, id, updates) {
    const userId = await getUserId(firebaseUid);
    const fields = Object.keys(updates);
    const values = [userId, id];
    const assignments = fields.map((field) => {
        values.push(updates[field]);
        return `${field} = $${values.length}`;
    });

    try {
        const result = await pool.query(
            `
                UPDATE customers
                SET ${assignments.join(", ")}, updated_at = CURRENT_TIMESTAMP
                WHERE user_id = $1 AND id = $2 AND is_active = TRUE
                RETURNING ${selectedColumns}
            `,
            values
        );
        return result.rows[0] || null;
    } catch (error) {
        return emailTaken(error);
    }
}

async function deleteCustomer(firebaseUid, id) {
    const userId = await getUserId(firebaseUid);
    const result = await pool.query(
        `
            UPDATE customers
            SET is_active = FALSE, updated_at = CURRENT_TIMESTAMP
            WHERE user_id = $1 AND id = $2 AND is_active = TRUE
            RETURNING id
        `,
        [userId, id]
    );
    return result.rows[0] || null;
}

module.exports = {
    createCustomer,
    listCustomers,
    getCustomerById,
    updateCustomer,
    deleteCustomer,
};
