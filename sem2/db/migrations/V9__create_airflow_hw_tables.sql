BEGIN;

CREATE SCHEMA IF NOT EXISTS airflow_hw;

CREATE TABLE IF NOT EXISTS autoservice_schema.service_campaign
(
    id               BIGSERIAL PRIMARY KEY,
    campaign_code    TEXT UNIQUE NOT NULL,
    service_name     TEXT        NOT NULL,
    discount_percent NUMERIC(5, 2) NOT NULL,
    valid_from       DATE        NOT NULL,
    valid_to         DATE        NOT NULL,
    source_name      TEXT        NOT NULL,
    loaded_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT service_campaign_discount_check
        CHECK (discount_percent >= 0 AND discount_percent <= 100),
    CONSTRAINT service_campaign_period_check
        CHECK (valid_from <= valid_to)
);

CREATE TABLE IF NOT EXISTS airflow_hw.load_audit
(
    id            BIGSERIAL PRIMARY KEY,
    dag_id        TEXT        NOT NULL,
    task_id       TEXT        NOT NULL,
    source_name   TEXT        NOT NULL,
    loaded_rows   INT         NOT NULL DEFAULT 0,
    rejected_rows INT         NOT NULL DEFAULT 0,
    status        TEXT        NOT NULL,
    details       JSONB       NOT NULL DEFAULT '{}'::jsonb,
    started_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT load_audit_status_check
        CHECK (status IN ('success', 'failed'))
);

CREATE INDEX IF NOT EXISTS idx_customer_airflow_import_tags
    ON autoservice_schema.customer USING gin (tags)
    WHERE tags @> ARRAY['airflow_import'];

CREATE INDEX IF NOT EXISTS idx_service_campaign_period
    ON autoservice_schema.service_campaign (valid_from, valid_to);

CREATE INDEX IF NOT EXISTS idx_load_audit_dag_completed
    ON airflow_hw.load_audit (dag_id, completed_at DESC);

COMMIT;
