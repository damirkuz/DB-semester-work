SELECT
    count(*) FILTER (WHERE tags @> ARRAY['airflow_import']) AS imported_customers,
    count(*) FILTER (
        WHERE phone_number !~ '^\+7[0-9]{10}$'
          AND tags @> ARRAY['airflow_import']
    ) AS bad_imported_phones
FROM autoservice_schema.customer;

SELECT
    campaign_code,
    service_name,
    discount_percent,
    valid_from,
    valid_to,
    source_name
FROM autoservice_schema.service_campaign
ORDER BY campaign_code;

SELECT
    dag_id,
    task_id,
    source_name,
    loaded_rows,
    rejected_rows,
    status,
    details
FROM airflow_hw.load_audit
ORDER BY completed_at DESC
LIMIT 5;
