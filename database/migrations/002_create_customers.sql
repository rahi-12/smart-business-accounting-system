
-- Migration: 002_create_customers.sql
-- Purpose: Store customers for each registered business user.

CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL,

    customer_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(254),
    address TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT customers_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT customers_name_not_empty
        CHECK (LENGTH(TRIM(customer_name)) > 0)
);

-- Helps retrieve customers belonging to a specific user.
CREATE INDEX customers_user_id_idx
ON customers(user_id);
