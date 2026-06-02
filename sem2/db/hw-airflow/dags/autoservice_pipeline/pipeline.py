from __future__ import annotations

import csv
import json
import os
import re
from contextlib import closing
from dataclasses import dataclass
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
from typing import Any

import psycopg2
from psycopg2.extras import RealDictCursor


PHONE_PATTERN = re.compile(r"^\+7\d{10}$")
DEFAULT_DATA_DIR = Path(__file__).resolve().parents[2] / "data"


@dataclass(frozen=True)
class PostgresConfig:
    host: str = os.getenv("PG_HOST", "localhost")
    port: int = int(os.getenv("PG_PORT", "5433"))
    database: str = os.getenv("PG_DB", os.getenv("DB_NAME", "autoservice_db"))
    user: str = os.getenv("PG_USER", os.getenv("DB_USER", "admin"))
    password: str = os.getenv("PG_PASSWORD", os.getenv("DB_PASSWORD", "admin_pass"))


@dataclass(frozen=True)
class ClickHouseConfig:
    host: str = os.getenv("CLICKHOUSE_HOST", "localhost")
    port: int = int(os.getenv("CLICKHOUSE_PORT", "8123"))
    username: str = os.getenv("CLICKHOUSE_USER", "default")
    password: str = os.getenv("CLICKHOUSE_PASSWORD", "")
    export_limit: int = int(os.getenv("EXPORT_LIMIT", "50000"))


def _data_dir(data_dir: str | Path | None = None) -> Path:
    return Path(data_dir) if data_dir else DEFAULT_DATA_DIR


def pg_connect():
    cfg = PostgresConfig()
    return psycopg2.connect(
        host=cfg.host,
        port=cfg.port,
        dbname=cfg.database,
        user=cfg.user,
        password=cfg.password,
    )


def ch_client():
    import clickhouse_connect

    cfg = ClickHouseConfig()
    return clickhouse_connect.get_client(
        host=cfg.host,
        port=cfg.port,
        username=cfg.username,
        password=cfg.password,
    )


def _first_value(client, sql: str):
    return client.query(sql).result_rows[0][0]


def ensure_source_files(data_dir: str | Path | None = None) -> dict[str, str]:
    base_dir = _data_dir(data_dir)
    sources = {
        "customer_leads_csv": base_dir / "customer_leads.csv",
        "service_campaigns_json": base_dir / "service_campaigns.json",
    }
    missing = [str(path) for path in sources.values() if not path.exists()]
    if missing:
        raise FileNotFoundError(f"Missing Airflow homework source files: {missing}")
    return {name: str(path) for name, path in sources.items()}


def _merge_tags(existing_tags: list[str] | None, new_tags: list[str]) -> list[str]:
    merged = []
    for tag in (existing_tags or []) + new_tags:
        normalized = tag.strip()
        if normalized and normalized not in merged:
            merged.append(normalized)
    return merged


def _write_audit(
    conn,
    dag_id: str,
    task_id: str,
    source_name: str,
    loaded_rows: int,
    rejected_rows: int,
    status: str,
    details: dict[str, Any],
) -> None:
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO airflow_hw.load_audit (
                dag_id,
                task_id,
                source_name,
                loaded_rows,
                rejected_rows,
                status,
                details
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s::jsonb)
            """,
            (
                dag_id,
                task_id,
                source_name,
                loaded_rows,
                rejected_rows,
                status,
                json.dumps(details, ensure_ascii=False),
            ),
        )


def load_customer_leads(data_dir: str | Path | None = None) -> dict[str, Any]:
    source_path = _data_dir(data_dir) / "customer_leads.csv"
    accepted: list[dict[str, Any]] = []
    rejected: list[dict[str, str]] = []

    with source_path.open("r", encoding="utf-8", newline="") as csv_file:
        for row in csv.DictReader(csv_file):
            tags = [tag.strip() for tag in row["tags"].split(";") if tag.strip()]
            if not row["lead_id"] or not row["full_name"] or not PHONE_PATTERN.match(row["phone_number"]):
                rejected.append({"lead_id": row.get("lead_id", ""), "reason": "bad required fields"})
                continue
            accepted.append(
                {
                    "lead_id": row["lead_id"],
                    "full_name": row["full_name"],
                    "phone_number": row["phone_number"],
                    "tags": _merge_tags(tags, ["airflow_import"]),
                }
            )

    with closing(pg_connect()) as conn:
        loaded = 0
        with conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                for row in accepted:
                    cur.execute(
                        """
                        SELECT id, tags
                        FROM autoservice_schema.customer
                        WHERE phone_number = %s
                        ORDER BY id
                        LIMIT 1
                        """,
                        (row["phone_number"],),
                    )
                    existing = cur.fetchone()
                    if existing:
                        merged_tags = _merge_tags(existing["tags"], row["tags"])
                        cur.execute(
                            """
                            UPDATE autoservice_schema.customer
                            SET full_name = %s,
                                tags = %s::text[]
                            WHERE id = %s
                            """,
                            (row["full_name"], merged_tags, existing["id"]),
                        )
                    else:
                        cur.execute(
                            """
                            INSERT INTO autoservice_schema.customer (full_name, phone_number, tags)
                            VALUES (%s, %s, %s::text[])
                            """,
                            (row["full_name"], row["phone_number"], row["tags"]),
                        )
                    loaded += 1

            _write_audit(
                conn,
                "autoservice_etl_to_postgres",
                "load_customer_leads",
                source_path.name,
                loaded,
                len(rejected),
                "success",
                {"rejected": rejected},
            )

    return {"loaded_rows": loaded, "rejected_rows": len(rejected), "source": str(source_path)}


def load_service_campaigns(data_dir: str | Path | None = None) -> dict[str, Any]:
    source_path = _data_dir(data_dir) / "service_campaigns.json"
    payload = json.loads(source_path.read_text(encoding="utf-8"))
    accepted: list[dict[str, Any]] = []
    rejected: list[dict[str, str]] = []

    for item in payload:
        try:
            valid_from = date.fromisoformat(item["valid_from"])
            valid_to = date.fromisoformat(item["valid_to"])
            discount = Decimal(str(item["discount_percent"]))
            if not item["campaign_code"] or not item["service_name"]:
                raise ValueError("empty code or service name")
            if discount < 0 or discount > 100:
                raise ValueError("discount is out of range")
            if valid_from > valid_to:
                raise ValueError("valid_from is greater than valid_to")
            accepted.append(
                {
                    "campaign_code": item["campaign_code"],
                    "service_name": item["service_name"],
                    "discount_percent": discount,
                    "valid_from": valid_from,
                    "valid_to": valid_to,
                }
            )
        except (KeyError, ValueError) as exc:
            rejected.append({"campaign_code": item.get("campaign_code", ""), "reason": str(exc)})

    with closing(pg_connect()) as conn:
        with conn:
            with conn.cursor() as cur:
                for row in accepted:
                    cur.execute(
                        """
                        INSERT INTO autoservice_schema.service_campaign (
                            campaign_code,
                            service_name,
                            discount_percent,
                            valid_from,
                            valid_to,
                            source_name,
                            loaded_at,
                            updated_at
                        )
                        VALUES (%s, %s, %s, %s, %s, %s, now(), now())
                        ON CONFLICT (campaign_code) DO UPDATE
                        SET service_name = EXCLUDED.service_name,
                            discount_percent = EXCLUDED.discount_percent,
                            valid_from = EXCLUDED.valid_from,
                            valid_to = EXCLUDED.valid_to,
                            source_name = EXCLUDED.source_name,
                            updated_at = now()
                        """,
                        (
                            row["campaign_code"],
                            row["service_name"],
                            row["discount_percent"],
                            row["valid_from"],
                            row["valid_to"],
                            source_path.name,
                        ),
                    )

            _write_audit(
                conn,
                "autoservice_etl_to_postgres",
                "load_service_campaigns",
                source_path.name,
                len(accepted),
                len(rejected),
                "success",
                {"rejected": rejected},
            )

    return {"loaded_rows": len(accepted), "rejected_rows": len(rejected), "source": str(source_path)}


def postgres_quality_checks() -> dict[str, int]:
    with closing(pg_connect()) as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                """
                SELECT
                    count(*) FILTER (WHERE tags @> ARRAY['airflow_import']) AS imported_customers,
                    count(*) FILTER (
                        WHERE phone_number !~ '^\\+7[0-9]{10}$'
                          AND tags @> ARRAY['airflow_import']
                    ) AS bad_imported_phones
                FROM autoservice_schema.customer
                """
            )
            customers = cur.fetchone()
            cur.execute(
                """
                SELECT
                    count(*) AS campaigns,
                    count(*) FILTER (WHERE valid_from > valid_to) AS bad_campaign_periods
                FROM autoservice_schema.service_campaign
                """
            )
            campaigns = cur.fetchone()

    result = {**dict(customers), **dict(campaigns)}
    if result["imported_customers"] == 0 or result["campaigns"] == 0:
        raise RuntimeError(f"Postgres quality checks failed: {result}")
    if result["bad_imported_phones"] or result["bad_campaign_periods"]:
        raise RuntimeError(f"Postgres quality checks found bad data: {result}")
    return result


def prepare_clickhouse() -> dict[str, str]:
    client = ch_client()
    statements = [
        "CREATE DATABASE IF NOT EXISTS autoservice_raw",
        "CREATE DATABASE IF NOT EXISTS autoservice_analytics",
        """
        CREATE TABLE IF NOT EXISTS autoservice_raw.repair_tasks
        (
            task_id UInt64,
            order_id UInt64,
            repair_date Date,
            customer_id UInt64,
            customer_segment String,
            worker_id UInt64,
            branch_office_id UInt64,
            branch_address String,
            car_model String,
            task_value Decimal(19, 2),
            has_autopart UInt8,
            loaded_at DateTime
        )
        ENGINE = MergeTree
        ORDER BY (repair_date, branch_office_id, task_id)
        """,
        """
        CREATE TABLE IF NOT EXISTS autoservice_raw.airflow_customers
        (
            customer_id UInt64,
            full_name String,
            phone_number String,
            tags String,
            loaded_at DateTime
        )
        ENGINE = MergeTree
        ORDER BY customer_id
        """,
        """
        CREATE TABLE IF NOT EXISTS autoservice_raw.service_campaigns
        (
            campaign_code String,
            service_name String,
            discount_percent Float64,
            valid_from Date,
            valid_to Date,
            loaded_at DateTime
        )
        ENGINE = MergeTree
        ORDER BY campaign_code
        """,
        """
        CREATE TABLE IF NOT EXISTS autoservice_analytics.branch_daily_repair_mart
        (
            repair_date Date,
            branch_office_id UInt64,
            branch_address String,
            repair_tasks UInt64,
            unique_customers UInt64,
            revenue Decimal(19, 2),
            avg_task_value Float64,
            autopart_tasks UInt64,
            imported_customers UInt64,
            active_campaigns UInt64,
            load_dttm DateTime
        )
        ENGINE = MergeTree
        PARTITION BY toYYYYMM(repair_date)
        ORDER BY (repair_date, branch_office_id)
        """,
    ]
    for statement in statements:
        client.command(statement)
    return {"status": "prepared"}


def _query_postgres(sql: str, params: tuple[Any, ...] = ()) -> list[dict[str, Any]]:
    with closing(pg_connect()) as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(sql, params)
            return [dict(row) for row in cur.fetchall()]


def export_postgres_to_clickhouse() -> dict[str, int]:
    prepare_clickhouse()
    cfg = ClickHouseConfig()
    limit_sql = "" if cfg.export_limit <= 0 else "LIMIT %s"
    limit_params: tuple[Any, ...] = () if cfg.export_limit <= 0 else (cfg.export_limit,)

    repairs = _query_postgres(
        f"""
        SELECT
            t.id AS task_id,
            t.order_id,
            o.creation_date::date AS repair_date,
            o.customer_id,
            CASE
                WHEN c.tags @> ARRAY['vip'] THEN 'vip'
                WHEN c.tags @> ARRAY['regular'] THEN 'regular'
                WHEN c.tags @> ARRAY['airflow_import'] THEN 'airflow_import'
                WHEN c.tags @> ARRAY['new'] THEN 'new'
                ELSE 'no_tags'
            END AS customer_segment,
            t.worker_id,
            bo.id AS branch_office_id,
            bo.address AS branch_address,
            car.model AS car_model,
            coalesce(t.value, 0) AS task_value,
            CASE WHEN ap.id IS NULL THEN 0 ELSE 1 END AS has_autopart,
            now()::timestamp AS loaded_at
        FROM autoservice_schema.task t
        JOIN autoservice_schema."order" o ON o.id = t.order_id
        JOIN autoservice_schema.customer c ON c.id = o.customer_id
        JOIN autoservice_schema.worker w ON w.id = t.worker_id
        JOIN autoservice_schema.branch_office bo ON bo.id = w.id_branch_office
        JOIN autoservice_schema.car car ON car.vin = t.car_id
        LEFT JOIN autoservice_schema.autopart ap ON ap.task_id = t.id
        ORDER BY t.id
        {limit_sql}
        """,
        limit_params,
    )
    customers = _query_postgres(
        """
        SELECT
            id AS customer_id,
            full_name,
            phone_number,
            coalesce(array_to_string(tags, ','), '') AS tags,
            now()::timestamp AS loaded_at
        FROM autoservice_schema.customer
        WHERE tags @> ARRAY['airflow_import']
        ORDER BY id
        """
    )
    campaigns = _query_postgres(
        """
        SELECT
            campaign_code,
            service_name,
            discount_percent::float AS discount_percent,
            valid_from,
            valid_to,
            now()::timestamp AS loaded_at
        FROM autoservice_schema.service_campaign
        ORDER BY campaign_code
        """
    )

    client = ch_client()
    for table in (
        "autoservice_raw.repair_tasks",
        "autoservice_raw.airflow_customers",
        "autoservice_raw.service_campaigns",
    ):
        client.command(f"TRUNCATE TABLE {table}")

    if repairs:
        client.insert(
            "autoservice_raw.repair_tasks",
            [list(row.values()) for row in repairs],
            column_names=list(repairs[0].keys()),
        )
    if customers:
        client.insert(
            "autoservice_raw.airflow_customers",
            [list(row.values()) for row in customers],
            column_names=list(customers[0].keys()),
        )
    if campaigns:
        client.insert(
            "autoservice_raw.service_campaigns",
            [list(row.values()) for row in campaigns],
            column_names=list(campaigns[0].keys()),
        )

    return {
        "repair_tasks": len(repairs),
        "airflow_customers": len(customers),
        "service_campaigns": len(campaigns),
    }


def build_clickhouse_mart() -> dict[str, int]:
    client = ch_client()
    client.command("TRUNCATE TABLE autoservice_analytics.branch_daily_repair_mart")
    client.command(
        """
        INSERT INTO autoservice_analytics.branch_daily_repair_mart
        WITH imported AS (
            SELECT count() AS imported_customers
            FROM autoservice_raw.airflow_customers
        ),
        campaigns_by_date AS (
            SELECT
                d.repair_date,
                count(c.campaign_code) AS active_campaigns
            FROM (
                SELECT DISTINCT repair_date
                FROM autoservice_raw.repair_tasks
            ) d
            CROSS JOIN autoservice_raw.service_campaigns c
            WHERE d.repair_date BETWEEN c.valid_from AND c.valid_to
            GROUP BY d.repair_date
        )
        SELECT
            r.repair_date,
            r.branch_office_id,
            any(r.branch_address) AS branch_address,
            count() AS repair_tasks,
            uniqExact(r.customer_id) AS unique_customers,
            sum(r.task_value) AS revenue,
            avg(toFloat64(r.task_value)) AS avg_task_value,
            sum(r.has_autopart) AS autopart_tasks,
            any(imported.imported_customers) AS imported_customers,
            coalesce(any(cbd.active_campaigns), 0) AS active_campaigns,
            now() AS load_dttm
        FROM autoservice_raw.repair_tasks r
        CROSS JOIN imported
        LEFT JOIN campaigns_by_date cbd ON cbd.repair_date = r.repair_date
        GROUP BY r.repair_date, r.branch_office_id
        """
    )
    count = _first_value(client, "SELECT count() FROM autoservice_analytics.branch_daily_repair_mart")
    return {"mart_rows": int(count)}


def clickhouse_quality_checks() -> dict[str, Any]:
    client = ch_client()
    result = {
        "raw_repair_tasks": int(_first_value(client, "SELECT count() FROM autoservice_raw.repair_tasks")),
        "raw_airflow_customers": int(_first_value(client, "SELECT count() FROM autoservice_raw.airflow_customers")),
        "raw_campaigns": int(_first_value(client, "SELECT count() FROM autoservice_raw.service_campaigns")),
        "mart_rows": int(_first_value(client, "SELECT count() FROM autoservice_analytics.branch_daily_repair_mart")),
        "mart_revenue": str(
            _first_value(client, "SELECT coalesce(sum(revenue), 0) FROM autoservice_analytics.branch_daily_repair_mart")
        ),
    }
    if result["raw_repair_tasks"] == 0 or result["raw_campaigns"] == 0 or result["mart_rows"] == 0:
        raise RuntimeError(f"ClickHouse quality checks failed: {result}")
    return result


def run_etl_to_postgres(data_dir: str | Path | None = None) -> dict[str, Any]:
    ensure_source_files(data_dir)
    return {
        "customer_leads": load_customer_leads(data_dir),
        "service_campaigns": load_service_campaigns(data_dir),
        "quality": postgres_quality_checks(),
    }


def run_analytics_to_clickhouse() -> dict[str, Any]:
    return {
        "export": export_postgres_to_clickhouse(),
        "mart": build_clickhouse_mart(),
        "quality": clickhouse_quality_checks(),
        "completed_at": datetime.utcnow().isoformat(timespec="seconds"),
    }
