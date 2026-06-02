SELECT olap.refresh_repair_task_mart();

ANALYZE olap.dim_date;
ANALYZE olap.dim_customer;
ANALYZE olap.dim_worker_branch;
ANALYZE olap.dim_car;
ANALYZE olap.fact_repair_task;
