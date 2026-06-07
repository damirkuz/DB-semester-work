BEGIN;

CREATE SCHEMA IF NOT EXISTS nosql_hw;

CREATE TABLE IF NOT EXISTS nosql_hw.sales_pg
(
    sale_date   TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    product_id  BIGINT                      NOT NULL,
    category    TEXT                        NOT NULL,
    quantity    INTEGER                     NOT NULL,
    price       NUMERIC(10, 2)              NOT NULL,
    customer_id BIGINT                      NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sales_pg_sale_date
    ON nosql_hw.sales_pg (sale_date);

CREATE INDEX IF NOT EXISTS idx_sales_pg_product
    ON nosql_hw.sales_pg (product_id);

INSERT INTO nosql_hw.sales_pg (
    sale_date,
    product_id,
    category,
    quantity,
    price,
    customer_id
)
SELECT
    (now() - interval '1000000 minutes')::timestamp + (n || ' minutes')::interval,
    n % 1000,
    CASE (n % 4)
        WHEN 0 THEN 'Repair parts'
        WHEN 1 THEN 'Diagnostics'
        WHEN 2 THEN 'Maintenance'
        ELSE 'Body work'
    END,
    (n % 10 + 1)::int,
    round(((n * 37) % 10000 / 100.0)::numeric, 2),
    n % 50000
FROM generate_series(0, 999999) AS n
WHERE NOT EXISTS (SELECT 1 FROM nosql_hw.sales_pg);

ANALYZE nosql_hw.sales_pg;

COMMIT;
