const { pool } = require("../config/database");
const { findUserByFirebaseUid } = require("./userRepository");
const { calculateInvoice } = require("../services/invoiceCalculator");
const { assertTransition, canTransition } = require("../services/invoiceStatus");
const { validateCreateIncome } = require("../validators/incomeValidator");

const invoiceColumns = `
    id,
    customer_id,
    invoice_number,
    issue_date::text AS issue_date,
    due_date::text AS due_date,
    customer_name,
    customer_email,
    customer_phone,
    customer_address,
    subtotal,
    discount_type,
    discount_value,
    discount,
    tax_rate,
    tax,
    total_amount,
    status,
    paid_at,
    income_id,
    notes,
    created_at,
    updated_at
`;

const sortableColumns = {
    invoice_number: "invoice_number",
    issue_date: "issue_date",
    due_date: "due_date",
    customer_name: "customer_name",
    total_amount: "total_amount",
    status: "status",
    created_at: "created_at",
    updated_at: "updated_at",
};

async function getUserId(firebaseUid) {
    const user = await findUserByFirebaseUid(firebaseUid);
    if (!user) {
        const error = new Error("User profile not found.");
        error.code = "PROFILE_NOT_FOUND";
        throw error;
    }
    return user.id;
}

async function withTransaction(operation) {
    const client = await pool.connect();
    try {
        await client.query("BEGIN");
        const result = await operation(client);
        await client.query("COMMIT");
        return result;
    } catch (error) {
        try {
            await client.query("ROLLBACK");
        } catch (rollbackError) {
            console.error("Invoice transaction rollback failed:", rollbackError.message);
        }
        throw error;
    } finally {
        client.release();
    }
}

function customerNotFound() {
    const error = new Error("Active customer record not found.");
    error.code = "CUSTOMER_NOT_FOUND";
    return error;
}

async function getActiveCustomer(client, userId, customerId) {
    const result = await client.query(
        `
            SELECT customer_name, email, phone, address
            FROM customers
            WHERE user_id = $1 AND id = $2 AND is_active = TRUE
            LIMIT 1
            FOR SHARE
        `,
        [userId, customerId]
    );
    if (!result.rows[0]) {
        throw customerNotFound();
    }
    return result.rows[0];
}

async function loadInvoice(client, userId, invoiceId) {
    const invoiceResult = await client.query(
        `
            SELECT ${invoiceColumns}
            FROM invoices
            WHERE user_id = $1 AND id = $2
            LIMIT 1
        `,
        [userId, invoiceId]
    );
    if (!invoiceResult.rows[0]) {
        return null;
    }
    const itemsResult = await client.query(
        `
            SELECT item.id, item.description, item.quantity, item.unit_price,
                   item.line_total, item.created_at
            FROM invoice_items AS item
            INNER JOIN invoices AS invoice ON invoice.id = item.invoice_id
            WHERE invoice.user_id = $1 AND invoice.id = $2
            ORDER BY item.created_at, item.id
        `,
        [userId, invoiceId]
    );
    return { ...invoiceResult.rows[0], items: itemsResult.rows };
}

async function insertItems(client, userId, invoiceId, items) {
    for (const item of items) {
        await client.query(
            `
                INSERT INTO invoice_items (invoice_id, description, quantity, unit_price, line_total)
                SELECT $2, $3, $4, $5, $6
                WHERE EXISTS (
                    SELECT 1 FROM invoices WHERE user_id = $1 AND id = $2
                )
            `,
            [userId, invoiceId, item.description, item.quantity, item.unit_price, item.line_total]
        );
    }
}

async function createInvoice(firebaseUid, invoice) {
    const userId = await getUserId(firebaseUid);
    return withTransaction(async (client) => {
        const customer = await getActiveCustomer(client, userId, invoice.customer_id);
        const counterResult = await client.query(
            `
                INSERT INTO invoice_number_counters (user_id, invoice_year, last_number)
                VALUES ($1, EXTRACT(YEAR FROM $2::date)::integer, 1)
                ON CONFLICT (user_id, invoice_year)
                DO UPDATE SET last_number = invoice_number_counters.last_number + 1
                RETURNING invoice_year, last_number
            `,
            [userId, invoice.issue_date]
        );
        const { invoice_year: invoiceYear, last_number: lastNumber } = counterResult.rows[0];
        const invoiceNumber = `INV-${String(invoiceYear).padStart(4, "0")}-${String(lastNumber).padStart(4, "0")}`;
        const result = await client.query(
            `
                INSERT INTO invoices (
                    user_id, customer_id, invoice_number, issue_date, due_date,
                    customer_name, customer_email, customer_phone, customer_address,
                    subtotal, discount_type, discount_value, discount, tax_rate, tax,
                    total_amount, status, notes
                )
                VALUES ($1, $2, $3, $4::date, $5::date, $6, $7, $8, $9,
                        $10, $11, $12, $13, $14, $15, $16, 'draft', $17)
                RETURNING id
            `,
            [
                userId,
                invoice.customer_id,
                invoiceNumber,
                invoice.issue_date,
                invoice.due_date,
                customer.customer_name,
                customer.email,
                customer.phone,
                customer.address,
                invoice.subtotal,
                invoice.discount_type,
                invoice.discount_value,
                invoice.discount,
                invoice.tax_rate,
                invoice.tax,
                invoice.total_amount,
                invoice.notes,
            ]
        );
        const invoiceId = result.rows[0].id;
        await insertItems(client, userId, invoiceId, invoice.items);
        return loadInvoice(client, userId, invoiceId);
    });
}

async function listInvoices(firebaseUid, options) {
    const userId = await getUserId(firebaseUid);
    const sortColumn = sortableColumns[options.sortBy];
    if (!sortColumn) {
        const error = new Error("Unsupported invoice sort column.");
        error.code = "INVALID_INPUT";
        throw error;
    }
    const conditions = ["user_id = $1"];
    const values = [userId];
    function addCondition(condition, value) {
        values.push(value);
        conditions.push(condition.replace("?", `$${values.length}`));
    }
    if (options.search) {
        values.push(`%${options.search}%`);
        conditions.push(`(invoice_number ILIKE $${values.length} OR customer_name ILIKE $${values.length})`);
    }
    if (options.status) {
        addCondition("status = ?", options.status);
    }
    if (options.startDate) {
        addCondition("issue_date >= ?::date", options.startDate);
    }
    if (options.endDate) {
        addCondition("issue_date <= ?::date", options.endDate);
    }

    const whereClause = conditions.join(" AND ");
    const countResult = await pool.query(
        `SELECT COUNT(*)::int AS total FROM invoices WHERE ${whereClause}`,
        values
    );
    const pageValues = [...values, options.limit, (options.page - 1) * options.limit];
    const result = await pool.query(
        `
            SELECT ${invoiceColumns}
            FROM invoices
            WHERE ${whereClause}
            ORDER BY ${sortColumn} ${options.order}, id ${options.order}
            LIMIT $${pageValues.length - 1} OFFSET $${pageValues.length}
        `,
        pageValues
    );
    return { items: result.rows, total: countResult.rows[0].total };
}

async function getInvoiceById(firebaseUid, id) {
    const userId = await getUserId(firebaseUid);
    const invoiceResult = await pool.query(
        `SELECT ${invoiceColumns} FROM invoices WHERE user_id = $1 AND id = $2 LIMIT 1`,
        [userId, id]
    );
    if (!invoiceResult.rows[0]) {
        return null;
    }
    const itemsResult = await pool.query(
        `
            SELECT item.id, item.description, item.quantity, item.unit_price,
                   item.line_total, item.created_at
            FROM invoice_items AS item
            INNER JOIN invoices AS invoice ON invoice.id = item.invoice_id
            WHERE invoice.user_id = $1 AND invoice.id = $2
            ORDER BY item.created_at, item.id
        `,
        [userId, id]
    );
    return { ...invoiceResult.rows[0], items: itemsResult.rows };
}

function dateText(value) {
    return value instanceof Date ? value.toISOString().slice(0, 10) : String(value).slice(0, 10);
}

async function updateInvoice(firebaseUid, id, updates) {
    const userId = await getUserId(firebaseUid);
    return withTransaction(async (client) => {
        const locked = await client.query(
            `SELECT * FROM invoices WHERE user_id = $1 AND id = $2 FOR UPDATE`,
            [userId, id]
        );
        const current = locked.rows[0];
        if (!current) {
            return null;
        }
        if (current.status !== "draft") {
            const error = new Error("Only draft invoices can be edited.");
            error.code = "INVOICE_NOT_EDITABLE";
            throw error;
        }

        const currentItems = await client.query(
            `
                SELECT item.description, item.quantity, item.unit_price
                FROM invoice_items AS item
                INNER JOIN invoices AS invoice ON invoice.id = item.invoice_id
                WHERE invoice.user_id = $1 AND invoice.id = $2
                ORDER BY item.created_at, item.id
            `,
            [userId, id]
        );
        const customerId = updates.customer_id === undefined ? current.customer_id : updates.customer_id;
        const customer = updates.customer_id === undefined
            ? {
                customer_name: current.customer_name,
                email: current.customer_email,
                phone: current.customer_phone,
                address: current.customer_address,
            }
            : await getActiveCustomer(client, userId, customerId);
        const issueDate = updates.issue_date === undefined
            ? dateText(current.issue_date)
            : updates.issue_date;
        const dueDate = updates.due_date === undefined
            ? (current.due_date ? dateText(current.due_date) : null)
            : updates.due_date;
        if (dueDate && dueDate < issueDate) {
            const error = new Error("due_date must be on or after issue_date.");
            error.code = "INVALID_INPUT";
            throw error;
        }
        const items = updates.items === undefined ? currentItems.rows : updates.items;
        const calculation = calculateInvoice(items, {
            discount_type: updates.discount_type === undefined ? current.discount_type : updates.discount_type,
            discount_value: updates.discount_value === undefined ? current.discount_value : updates.discount_value,
            tax_rate: updates.tax_rate === undefined ? current.tax_rate : updates.tax_rate,
        });
        const notes = updates.notes === undefined ? current.notes : updates.notes;
        await client.query(
            `
                UPDATE invoices
                SET customer_id = $3,
                    issue_date = $4::date,
                    due_date = $5::date,
                    customer_name = $6,
                    customer_email = $7,
                    customer_phone = $8,
                    customer_address = $9,
                    subtotal = $10,
                    discount_type = $11,
                    discount_value = $12,
                    discount = $13,
                    tax_rate = $14,
                    tax = $15,
                    total_amount = $16,
                    notes = $17,
                    updated_at = CURRENT_TIMESTAMP
                WHERE user_id = $1 AND id = $2
            `,
            [
                userId,
                id,
                customerId,
                issueDate,
                dueDate,
                customer.customer_name,
                customer.email,
                customer.phone,
                customer.address,
                calculation.subtotal,
                calculation.discount_type,
                calculation.discount_value,
                calculation.discount,
                calculation.tax_rate,
                calculation.tax,
                calculation.total_amount,
                notes,
            ]
        );
        if (updates.items !== undefined) {
            await client.query(
                `
                    DELETE FROM invoice_items AS item
                    USING invoices AS invoice
                    WHERE item.invoice_id = invoice.id
                      AND invoice.user_id = $1 AND invoice.id = $2
                `,
                [userId, id]
            );
            await insertItems(client, userId, id, calculation.items);
        }
        return loadInvoice(client, userId, id);
    });
}

async function deleteInvoice(firebaseUid, id) {
    const userId = await getUserId(firebaseUid);
    return withTransaction(async (client) => {
        const locked = await client.query(
            `SELECT status FROM invoices WHERE user_id = $1 AND id = $2 FOR UPDATE`,
            [userId, id]
        );
        if (!locked.rows[0]) {
            return null;
        }
        if (locked.rows[0].status !== "draft") {
            const error = new Error("Only draft invoices can be deleted.");
            error.code = "INVOICE_NOT_DELETABLE";
            throw error;
        }
        const result = await client.query(
            `DELETE FROM invoices WHERE user_id = $1 AND id = $2 RETURNING id`,
            [userId, id]
        );
        return result.rows[0] || null;
    });
}

async function transitionInvoice(firebaseUid, id, targetStatus) {
    const userId = await getUserId(firebaseUid);
    return withTransaction(async (client) => {
        const locked = await client.query(
            `SELECT status FROM invoices WHERE user_id = $1 AND id = $2 FOR UPDATE`,
            [userId, id]
        );
        if (!locked.rows[0]) {
            return null;
        }
        assertTransition(locked.rows[0].status, targetStatus);
        if (targetStatus === "sent") {
            const count = await client.query(
                `
                    SELECT COUNT(*)::int AS item_count
                    FROM invoice_items AS item
                    INNER JOIN invoices AS invoice ON invoice.id = item.invoice_id
                    WHERE invoice.user_id = $1 AND invoice.id = $2
                `,
                [userId, id]
            );
            if (count.rows[0].item_count < 1) {
                const error = new Error("An invoice must have at least one item before it is sent.");
                error.code = "INVOICE_ITEMS_REQUIRED";
                throw error;
            }
        }
        await client.query(
            `
                UPDATE invoices
                SET status = $3, updated_at = CURRENT_TIMESTAMP
                WHERE user_id = $1 AND id = $2
            `,
            [userId, id, targetStatus]
        );
        return loadInvoice(client, userId, id);
    });
}

async function payInvoice(firebaseUid, id, payment) {
    const userId = await getUserId(firebaseUid);
    return withTransaction(async (client) => {
        const locked = await client.query(
            `
                SELECT id, invoice_number, total_amount, status
                FROM invoices
                WHERE user_id = $1 AND id = $2
                FOR UPDATE
            `,
            [userId, id]
        );
        const invoice = locked.rows[0];
        if (!invoice) {
            return null;
        }
        if (!canTransition(invoice.status, "paid")) {
            assertTransition(invoice.status, "paid");
        }
        if (Number(invoice.total_amount) <= 0) {
            const error = new Error("An invoice with a zero total cannot be recorded as income.");
            error.code = "INVOICE_ZERO_TOTAL";
            throw error;
        }
        const income = validateCreateIncome({
            title: `Invoice ${invoice.invoice_number}`,
            amount: invoice.total_amount,
            category: "Invoice Payment",
            payment_method: payment.payment_method,
            income_date: payment.payment_date,
            description: null,
        });
        const incomeResult = await client.query(
            `
                INSERT INTO income (user_id, title, amount, category, payment_method, income_date, description)
                VALUES ($1, $2, $3, $4, $5, $6::date, $7)
                RETURNING id
            `,
            [
                userId,
                income.title,
                income.amount,
                income.category,
                income.payment_method,
                income.income_date,
                income.description,
            ]
        );
        await client.query(
            `
                UPDATE invoices
                SET status = 'paid', income_id = $3, paid_at = CURRENT_TIMESTAMP,
                    updated_at = CURRENT_TIMESTAMP
                WHERE user_id = $1 AND id = $2
            `,
            [userId, id, incomeResult.rows[0].id]
        );
        return loadInvoice(client, userId, id);
    });
}

module.exports = {
    createInvoice,
    listInvoices,
    getInvoiceById,
    updateInvoice,
    deleteInvoice,
    transitionInvoice,
    payInvoice,
};
