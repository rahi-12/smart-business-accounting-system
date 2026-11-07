
-- Migration: 003_create_income.sql
-- Purpose: Store business income records.

CREATE TABLE income (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL,

    title VARCHAR(150) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    category VARCHAR(100) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,

    income_date DATE NOT NULL DEFAULT CURRENT_DATE,
    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT income_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT income_amount_positive
        CHECK (amount > 0),

    CONSTRAINT income_title_not_empty
        CHECK (LENGTH(TRIM(title)) > 0),

    CONSTRAINT income_category_not_empty
        CHECK (LENGTH(TRIM(category)) > 0)
);

-- Helps retrieve income records belonging to a user.
CREATE INDEX income_user_id_idx
ON income(user_id);

-- Helps filter income records by date.
CREATE INDEX income_user_date_idx
ON income(user_id, income_date);
