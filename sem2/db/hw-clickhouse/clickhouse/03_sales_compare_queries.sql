SELECT
    toDate(sale_date) AS sale_day,
    count() AS number_of_transactions,
    sum(quantity) AS total_quantity,
    round(sum(quantity * price), 2) AS total_revenue,
    round(avg(price), 2) AS avg_price
FROM autoservice_hw.autoservice_sales_ch
WHERE sale_date >= now() - toIntervalDay(30)
GROUP BY sale_day
ORDER BY sale_day DESC
LIMIT 10;

SELECT
    sum(rows) AS rows_count,
    formatReadableSize(sum(bytes_on_disk)) AS data_size_on_disk
FROM system.parts
WHERE database = 'autoservice_hw'
  AND table = 'autoservice_sales_ch'
  AND active;
