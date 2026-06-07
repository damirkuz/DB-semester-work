SELECT
    ip,
    count() AS request_count
FROM autoservice_hw.autoservice_web_logs
GROUP BY ip
ORDER BY request_count DESC, ip
LIMIT 10;

SELECT
    round(sumIf(1, status_code BETWEEN 200 AND 299) / count() * 100, 2) AS success_rate,
    round(sumIf(1, status_code BETWEEN 400 AND 499) / count() * 100, 2) AS client_error_rate,
    round(sumIf(1, status_code BETWEEN 500 AND 599) / count() * 100, 2) AS server_error_rate
FROM autoservice_hw.autoservice_web_logs;

SELECT
    url,
    count() AS hit_count,
    round(avg(response_size), 2) AS avg_response_size,
    min(response_size) AS min_size,
    max(response_size) AS max_size
FROM autoservice_hw.autoservice_web_logs
GROUP BY url
ORDER BY hit_count DESC, url
LIMIT 1;

SELECT
    toHour(log_time) AS hour,
    count() AS error_500_count
FROM autoservice_hw.autoservice_web_logs
WHERE status_code = 500
GROUP BY hour
ORDER BY error_500_count DESC, hour
LIMIT 1;
