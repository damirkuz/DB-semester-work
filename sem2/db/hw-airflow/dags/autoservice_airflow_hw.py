from __future__ import annotations

import pendulum
from airflow import DAG
from airflow.operators.python import PythonOperator

from autoservice_pipeline.pipeline import (
    build_clickhouse_mart,
    clickhouse_quality_checks,
    ensure_source_files,
    export_postgres_to_clickhouse,
    load_customer_leads,
    load_service_campaigns,
    postgres_quality_checks,
    prepare_clickhouse,
)


DEFAULT_ARGS = {
    "owner": "damir",
    "retries": 1,
}


with DAG(
    dag_id="autoservice_etl_to_postgres",
    description="CSV and JSON sources are loaded into the autoservice PostgreSQL schema.",
    start_date=pendulum.datetime(2026, 6, 1, tz="Europe/Moscow"),
    schedule="0 2 * * *",
    catchup=False,
    default_args=DEFAULT_ARGS,
    tags=["db-homework", "autoservice", "etl"],
) as etl_dag:
    check_sources = PythonOperator(
        task_id="check_sources",
        python_callable=ensure_source_files,
    )

    load_csv_customers = PythonOperator(
        task_id="load_customer_leads",
        python_callable=load_customer_leads,
    )

    load_json_campaigns = PythonOperator(
        task_id="load_service_campaigns",
        python_callable=load_service_campaigns,
    )

    check_postgres_quality = PythonOperator(
        task_id="postgres_quality_checks",
        python_callable=postgres_quality_checks,
    )

    check_sources >> [load_csv_customers, load_json_campaigns] >> check_postgres_quality


with DAG(
    dag_id="autoservice_analytics_to_clickhouse",
    description="Autoservice PostgreSQL data is exported to ClickHouse and aggregated into an analytics mart.",
    start_date=pendulum.datetime(2026, 6, 1, tz="Europe/Moscow"),
    schedule="30 2 * * *",
    catchup=False,
    default_args=DEFAULT_ARGS,
    tags=["db-homework", "autoservice", "clickhouse"],
) as analytics_dag:
    prepare_ch = PythonOperator(
        task_id="prepare_clickhouse",
        python_callable=prepare_clickhouse,
    )

    export_pg = PythonOperator(
        task_id="export_postgres_to_clickhouse",
        python_callable=export_postgres_to_clickhouse,
    )

    build_mart = PythonOperator(
        task_id="build_branch_daily_repair_mart",
        python_callable=build_clickhouse_mart,
    )

    check_clickhouse_quality = PythonOperator(
        task_id="clickhouse_quality_checks",
        python_callable=clickhouse_quality_checks,
    )

    prepare_ch >> export_pg >> build_mart >> check_clickhouse_quality
