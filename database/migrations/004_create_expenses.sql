
-- Migration: 004_create_expenses.sql
-- Purpose: Store business expense records.

CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL,

    title VARCHAR(150) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    category VARCHAR(100) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,

    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT expenses_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT expenses_amount_positive
        CHECK (amount > 0),

    CONSTRAINT expenses_title_not_empty
        CHECK (LENGTH(TRIM(title)) > 0),

    CONSTRAINT expenses_category_not_empty
        CHECK (LENGTH(TRIM(category)) > 0)
);

-- Retrieve expenses belonging to a specific user.
CREATE INDEX expenses_user_id_idx
ON expenses(user_id);

-- Filter expenses by date efficiently.
CREATE INDEX expenses_user_date_idx
ON expenses(user_id, expense_date);
