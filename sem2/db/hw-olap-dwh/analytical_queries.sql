-- 1. Динамика активности и выручки по дням.
SELECT
    d.date_id,
    d.week_of_year,
    count(*) AS repair_tasks,
    round(sum(f.task_value), 2) AS revenue,
    round(avg(f.task_value), 2) AS avg_task_value
FROM olap.fact_repair_task f
JOIN olap.dim_date d ON d.date_id = f.date_id
GROUP BY d.date_id, d.week_of_year
ORDER BY d.date_id
LIMIT 15;

-- 2. Самые загруженные филиалы и мастера.
SELECT
    wb.branch_office_id,
    wb.branch_address,
    wb.worker_id,
    wb.worker_name,
    wb.worker_role,
    count(*) AS repair_tasks,
    round(sum(f.task_value), 2) AS revenue
FROM olap.fact_repair_task f
JOIN olap.dim_worker_branch wb ON wb.worker_id = f.worker_id
GROUP BY
    wb.branch_office_id,
    wb.branch_address,
    wb.worker_id,
    wb.worker_name,
    wb.worker_role
ORDER BY repair_tasks DESC, revenue DESC
LIMIT 10;

-- 3. Сколько действий и денег дают сегменты клиентов.
SELECT
    c.customer_segment,
    count(DISTINCT c.customer_id) AS customers,
    count(*) AS repair_tasks,
    round(sum(f.task_value), 2) AS revenue,
    round(avg(f.task_value), 2) AS avg_task_value
FROM olap.fact_repair_task f
JOIN olap.dim_customer c ON c.customer_id = f.customer_id
GROUP BY c.customer_segment
ORDER BY revenue DESC;

-- 4. Самые популярные модели автомобилей в ремонтах.
SELECT
    car.model,
    car.status,
    count(*) AS repair_tasks,
    round(sum(f.task_value), 2) AS revenue,
    count(*) FILTER (WHERE f.has_autopart) AS tasks_with_autoparts
FROM olap.fact_repair_task f
JOIN olap.dim_car car ON car.car_vin = f.car_vin
GROUP BY car.model, car.status
ORDER BY repair_tasks DESC, revenue DESC
LIMIT 10;
