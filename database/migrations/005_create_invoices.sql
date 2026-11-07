
-- Migration: 005_create_invoices.sql
-- Purpose: Store business invoice records.

CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL,
    customer_id UUID NOT NULL,

    invoice_number VARCHAR(50) NOT NULL,
    invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE,

    subtotal NUMERIC(12, 2) NOT NULL DEFAULT 0,
    discount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    tax NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,

    status VARCHAR(20) NOT NULL DEFAULT 'unpaid',
    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT invoices_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT invoices_customer_fk
        FOREIGN KEY (customer_id)
        REFERENCES customers(id)
        ON DELETE RESTRICT,

    CONSTRAINT invoices_number_unique
        UNIQUE (user_id, invoice_number),

    CONSTRAINT invoices_amounts_non_negative
        CHECK (
            subtotal >= 0
            AND discount >= 0
            AND tax >= 0
            AND total_amount >= 0
        ),

    CONSTRAINT invoices_status_valid
        CHECK (status IN ('unpaid', 'paid', 'partially_paid', 'overdue', 'cancelled'))
);

-- Retrieve invoices belonging to a specific user.
CREATE INDEX invoices_user_id_idx
ON invoices(user_id);

-- Filter invoices by date.
CREATE INDEX invoices_user_date_idx
ON invoices(user_id, invoice_date);

-- Retrieve invoices belonging to a customer.
CREATE INDEX invoices_customer_id_idx
ON invoices(customer_id);
