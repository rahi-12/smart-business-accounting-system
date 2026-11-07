
-- Migration: 006_create_invoice_items.sql
-- Purpose: Store individual products or services in an invoice.

CREATE TABLE invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    invoice_id UUID NOT NULL,

    product_name VARCHAR(150) NOT NULL,
    quantity NUMERIC(12, 2) NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL,
    line_total NUMERIC(12, 2) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT invoice_items_invoice_fk
        FOREIGN KEY (invoice_id)
        REFERENCES invoices(id)
        ON DELETE CASCADE,

    CONSTRAINT invoice_items_product_not_empty
        CHECK (LENGTH(TRIM(product_name)) > 0),

    CONSTRAINT invoice_items_quantity_positive
        CHECK (quantity > 0),

    CONSTRAINT invoice_items_unit_price_non_negative
        CHECK (unit_price >= 0),

    CONSTRAINT invoice_items_line_total_non_negative
        CHECK (line_total >= 0)
);

-- Retrieve all items belonging to an invoice.
CREATE INDEX invoice_items_invoice_id_idx
ON invoice_items(invoice_id);
