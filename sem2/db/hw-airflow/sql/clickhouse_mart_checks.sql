SELECT
    count() AS mart_rows,
    sum(repair_tasks) AS repair_tasks,
    round(sum(revenue), 2) AS revenue
FROM autoservice_analytics.branch_daily_repair_mart;

SELECT
    repair_date,
    branch_office_id,
    branch_address,
    repair_tasks,
    unique_customers,
    revenue,
    imported_customers,
    active_campaigns
FROM autoservice_analytics.branch_daily_repair_mart
ORDER BY revenue DESC
LIMIT 10;
