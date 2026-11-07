
WITH expected_tables(table_name) AS (
    VALUES
        ('users'),
        ('customers'),
        ('income'),
        ('expenses'),
        ('invoices'),
        ('invoice_items'),
        ('uploaded_files')
),

table_status AS (
    SELECT
        '01 - TABLE STATUS' AS section,
        e.table_name,
        e.table_name AS object_name,
        CASE
            WHEN t.table_name IS NOT NULL
            THEN 'EXISTS'
            ELSE 'MISSING'
        END AS details
    FROM expected_tables e
    LEFT JOIN information_schema.tables t
        ON t.table_schema = 'public'
        AND t.table_name = e.table_name
),

column_details AS (
    SELECT
        '02 - COLUMNS' AS section,
        c.table_name,
        c.column_name AS object_name,
        'Position: ' || c.ordinal_position ||
        ' | Type: ' || c.data_type ||
        CASE
            WHEN c.character_maximum_length IS NOT NULL
            THEN '(' || c.character_maximum_length || ')'
            WHEN c.numeric_precision IS NOT NULL
            THEN '(' || c.numeric_precision || ',' ||
                 c.numeric_scale || ')'
            ELSE ''
        END ||
        ' | Nullable: ' || c.is_nullable ||
        ' | Default: ' || COALESCE(c.column_default, 'NONE')
        AS details
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND c.table_name IN (
          SELECT table_name FROM expected_tables
      )
),

constraint_details AS (
    SELECT
        '03 - CONSTRAINTS' AS section,
        t.relname AS table_name,
        con.conname AS object_name,
        CAST(con.contype AS TEXT) || ' | ' ||
        pg_get_constraintdef(con.oid) AS details
    FROM pg_constraint con
    JOIN pg_class t
        ON t.oid = con.conrelid
    JOIN pg_namespace n
        ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
      AND t.relname IN (
          SELECT table_name FROM expected_tables
      )
),

index_details AS (
    SELECT
        '04 - INDEXES' AS section,
        tablename AS table_name,
        indexname AS object_name,
        indexdef AS details
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename IN (
          SELECT table_name FROM expected_tables
      )
)

SELECT * FROM table_status
UNION ALL
SELECT * FROM column_details
UNION ALL
SELECT * FROM constraint_details
UNION ALL
SELECT * FROM index_details
ORDER BY table_name, section, object_name;
