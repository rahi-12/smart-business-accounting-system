ALTER TABLE customers
    ALTER COLUMN phone TYPE VARCHAR(30);

ALTER TABLE customers
    ADD COLUMN notes TEXT,
    ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE customers
    ADD CONSTRAINT customers_email_max_length
        CHECK (email IS NULL OR char_length(email) <= 150),
    ADD CONSTRAINT customers_address_max_length
        CHECK (address IS NULL OR char_length(address) <= 500),
    ADD CONSTRAINT customers_notes_max_length
        CHECK (notes IS NULL OR char_length(notes) <= 5000);

CREATE UNIQUE INDEX customers_active_email_unique
    ON customers (user_id, LOWER(email))
    WHERE is_active = TRUE AND email IS NOT NULL;
