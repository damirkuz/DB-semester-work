CREATE DATABASE IF NOT EXISTS autoservice_hw;

DROP TABLE IF EXISTS autoservice_hw.autoservice_web_logs;

CREATE TABLE autoservice_hw.autoservice_web_logs
(
    log_time DateTime,
    ip String,
    url String,
    status_code UInt16,
    response_size UInt64
)
ENGINE = MergeTree()
ORDER BY (log_time, status_code);

INSERT INTO autoservice_hw.autoservice_web_logs
SELECT
    toDateTime('2026-06-01 00:00:00') + toIntervalSecond(number),
    concat('10.20.0.', toString(number % 50)),
    arrayElement(
        ['/orders', '/api/tasks', '/api/customers', '/admin/boxes', '/parts'],
        (number % 5) + 1
    ),
    arrayElement([200, 200, 201, 204, 301, 404, 500], (number % 7) + 1),
    rand() % 1000000
FROM numbers(500000);

DROP TABLE IF EXISTS autoservice_hw.autoservice_sales_ch;

CREATE TABLE autoservice_hw.autoservice_sales_ch
(
    sale_date DateTime,
    product_id UInt64,
    category String,
    quantity UInt32,
    price Float64,
    customer_id UInt64
)
ENGINE = MergeTree()
ORDER BY sale_date;

INSERT INTO autoservice_hw.autoservice_sales_ch
SELECT
    now() - toIntervalMinute(1000000 - number),
    number % 1000,
    arrayElement(['Repair parts', 'Diagnostics', 'Maintenance', 'Body work'], (number % 4) + 1),
    (number % 10) + 1,
    round(((number * 37) % 10000) / 100, 2),
    number % 50000
FROM numbers(1000000);
