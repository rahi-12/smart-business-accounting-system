ALTER TABLE income
    ADD CONSTRAINT income_description_max_length
    CHECK (description IS NULL OR char_length(description) <= 5000);

ALTER TABLE expenses
    ADD CONSTRAINT expenses_description_max_length
    CHECK (description IS NULL OR char_length(description) <= 5000);
