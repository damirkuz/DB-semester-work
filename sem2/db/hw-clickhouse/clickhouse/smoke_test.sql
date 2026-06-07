SELECT
    throwIf(count() != 500000, 'autoservice_web_logs must contain 500000 rows') AS web_logs_rows_ok
FROM autoservice_hw.autoservice_web_logs;

SELECT
    throwIf(count() != 1000000, 'autoservice_sales_ch must contain 1000000 rows') AS sales_rows_ok
FROM autoservice_hw.autoservice_sales_ch;

SELECT
    throwIf(count() < 10, 'top IP query must return at least 10 rows') AS top_ip_query_ok
FROM
(
    SELECT ip
    FROM autoservice_hw.autoservice_web_logs
    GROUP BY ip
    ORDER BY count() DESC
    LIMIT 10
);

SELECT
    throwIf(success_rate <= 0, 'success rate must be positive') AS status_rate_query_ok
FROM
(
    SELECT
        round(sumIf(1, status_code BETWEEN 200 AND 299) / count() * 100, 2) AS success_rate
    FROM autoservice_hw.autoservice_web_logs
);

SELECT
    throwIf(count() = 0, 'sales aggregation for recent data must return rows') AS sales_aggregation_ok
FROM
(
    SELECT toDate(sale_date) AS sale_day
    FROM autoservice_hw.autoservice_sales_ch
    WHERE sale_date >= now() - toIntervalDay(30)
    GROUP BY sale_day
);
