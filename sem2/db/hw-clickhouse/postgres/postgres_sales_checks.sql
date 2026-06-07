\timing on

SELECT
    sale_date::date AS sale_day,
    count(*) AS number_of_transactions,
    sum(quantity) AS total_quantity,
    round(sum(quantity * price)::numeric, 2) AS total_revenue,
    round(avg(price)::numeric, 2) AS avg_price
FROM nosql_hw.sales_pg
WHERE sale_date >= now() - interval '30 days'
GROUP BY sale_date::date
ORDER BY sale_day DESC
LIMIT 10;

SELECT
    count(*) AS rows_count,
    pg_size_pretty(pg_total_relation_size('nosql_hw.sales_pg')) AS total_relation_size
FROM nosql_hw.sales_pg;
