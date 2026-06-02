BEGIN;

CREATE SCHEMA IF NOT EXISTS olap;

CREATE TABLE IF NOT EXISTS olap.dim_date
(
    date_id      DATE PRIMARY KEY,
    year         INT     NOT NULL,
    quarter      INT     NOT NULL,
    month        INT     NOT NULL,
    month_name   TEXT    NOT NULL,
    week_of_year INT     NOT NULL,
    day_of_month INT     NOT NULL,
    day_of_week  INT     NOT NULL,
    is_weekend   BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS olap.dim_customer
(
    customer_id      INT PRIMARY KEY,
    full_name        TEXT NOT NULL,
    phone_number     TEXT NOT NULL,
    customer_segment TEXT NOT NULL,
    tags             TEXT
);

CREATE TABLE IF NOT EXISTS olap.dim_worker_branch
(
    worker_id        INT PRIMARY KEY,
    worker_name      TEXT NOT NULL,
    worker_role      TEXT NOT NULL,
    branch_office_id INT  NOT NULL,
    branch_address   TEXT NOT NULL,
    branch_phone     TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS olap.dim_car
(
    car_vin          VARCHAR(17) PRIMARY KEY,
    model            TEXT NOT NULL,
    status           TEXT NOT NULL,
    box_type         TEXT NOT NULL,
    branch_office_id INT  NOT NULL
);

CREATE TABLE IF NOT EXISTS olap.fact_repair_task
(
    fact_id          BIGSERIAL PRIMARY KEY,
    task_id          INT UNIQUE NOT NULL,
    order_id         INT        NOT NULL,
    date_id          DATE       NOT NULL REFERENCES olap.dim_date (date_id),
    customer_id      INT        NOT NULL REFERENCES olap.dim_customer (customer_id),
    worker_id        INT        NOT NULL REFERENCES olap.dim_worker_branch (worker_id),
    car_vin          VARCHAR(17) NOT NULL REFERENCES olap.dim_car (car_vin),
    task_value       NUMERIC(19, 2) NOT NULL,
    has_autopart     BOOLEAN    NOT NULL,
    autopart_name    TEXT,
    task_description TEXT,
    order_description TEXT,
    order_created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    closure_date     TIMESTAMP WITHOUT TIME ZONE,
    load_dttm        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT fact_repair_task_value_check CHECK (task_value >= 0)
);

CREATE INDEX IF NOT EXISTS idx_fact_repair_task_date
    ON olap.fact_repair_task (date_id);

CREATE INDEX IF NOT EXISTS idx_fact_repair_task_customer
    ON olap.fact_repair_task (customer_id);

CREATE INDEX IF NOT EXISTS idx_fact_repair_task_worker
    ON olap.fact_repair_task (worker_id);

CREATE INDEX IF NOT EXISTS idx_fact_repair_task_car
    ON olap.fact_repair_task (car_vin);

CREATE OR REPLACE FUNCTION olap.refresh_repair_task_mart()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO olap.dim_date (
        date_id,
        year,
        quarter,
        month,
        month_name,
        week_of_year,
        day_of_month,
        day_of_week,
        is_weekend
    )
    SELECT
        d::date AS date_id,
        EXTRACT(year FROM d)::int AS year,
        EXTRACT(quarter FROM d)::int AS quarter,
        EXTRACT(month FROM d)::int AS month,
        TO_CHAR(d, 'TMMonth') AS month_name,
        EXTRACT(week FROM d)::int AS week_of_year,
        EXTRACT(day FROM d)::int AS day_of_month,
        EXTRACT(isodow FROM d)::int AS day_of_week,
        EXTRACT(isodow FROM d)::int IN (6, 7) AS is_weekend
    FROM (
        SELECT
            min(o.creation_date)::date AS min_date,
            max(coalesce(ocd.closure_date, o.creation_date))::date AS max_date
        FROM autoservice_schema."order" o
        LEFT JOIN autoservice_schema.order_closure_date ocd ON ocd.order_id = o.id
    ) bounds
    CROSS JOIN LATERAL generate_series(bounds.min_date, bounds.max_date, interval '1 day') AS d
    WHERE bounds.min_date IS NOT NULL
    ON CONFLICT (date_id) DO UPDATE
    SET year = EXCLUDED.year,
        quarter = EXCLUDED.quarter,
        month = EXCLUDED.month,
        month_name = EXCLUDED.month_name,
        week_of_year = EXCLUDED.week_of_year,
        day_of_month = EXCLUDED.day_of_month,
        day_of_week = EXCLUDED.day_of_week,
        is_weekend = EXCLUDED.is_weekend;

    INSERT INTO olap.dim_customer (
        customer_id,
        full_name,
        phone_number,
        customer_segment,
        tags
    )
    SELECT
        c.id,
        c.full_name,
        c.phone_number,
        CASE
            WHEN c.tags @> ARRAY['vip'] THEN 'vip'
            WHEN c.tags @> ARRAY['corp'] THEN 'corp'
            WHEN c.tags @> ARRAY['regular'] THEN 'regular'
            WHEN c.tags @> ARRAY['new'] THEN 'new'
            ELSE 'no_tags'
        END AS customer_segment,
        coalesce(array_to_string(c.tags, ', '), '') AS tags
    FROM autoservice_schema.customer c
    ON CONFLICT (customer_id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        phone_number = EXCLUDED.phone_number,
        customer_segment = EXCLUDED.customer_segment,
        tags = EXCLUDED.tags;

    INSERT INTO olap.dim_worker_branch (
        worker_id,
        worker_name,
        worker_role,
        branch_office_id,
        branch_address,
        branch_phone
    )
    SELECT
        w.id,
        w.full_name,
        w.role,
        bo.id,
        bo.address,
        bo.phone_number
    FROM autoservice_schema.worker w
    JOIN autoservice_schema.branch_office bo ON bo.id = w.id_branch_office
    ON CONFLICT (worker_id) DO UPDATE
    SET worker_name = EXCLUDED.worker_name,
        worker_role = EXCLUDED.worker_role,
        branch_office_id = EXCLUDED.branch_office_id,
        branch_address = EXCLUDED.branch_address,
        branch_phone = EXCLUDED.branch_phone;

    INSERT INTO olap.dim_car (
        car_vin,
        model,
        status,
        box_type,
        branch_office_id
    )
    SELECT
        car.vin,
        car.model,
        car.status,
        b.box_type,
        b.id_branch_office
    FROM autoservice_schema.car car
    JOIN autoservice_schema.box b ON b.id = car.box_id
    ON CONFLICT (car_vin) DO UPDATE
    SET model = EXCLUDED.model,
        status = EXCLUDED.status,
        box_type = EXCLUDED.box_type,
        branch_office_id = EXCLUDED.branch_office_id;

    INSERT INTO olap.fact_repair_task (
        task_id,
        order_id,
        date_id,
        customer_id,
        worker_id,
        car_vin,
        task_value,
        has_autopart,
        autopart_name,
        task_description,
        order_description,
        order_created_at,
        closure_date,
        load_dttm
    )
    SELECT
        t.id,
        o.id,
        o.creation_date::date,
        o.customer_id,
        t.worker_id,
        t.car_id,
        coalesce(t.value, 0),
        ap.id IS NOT NULL,
        ap.name,
        t.description,
        o.description,
        o.creation_date,
        ocd.closure_date,
        now()
    FROM autoservice_schema.task t
    JOIN autoservice_schema."order" o ON o.id = t.order_id
    LEFT JOIN autoservice_schema.autopart ap ON ap.task_id = t.id
    LEFT JOIN autoservice_schema.order_closure_date ocd ON ocd.order_id = o.id
    ON CONFLICT (task_id) DO UPDATE
    SET order_id = EXCLUDED.order_id,
        date_id = EXCLUDED.date_id,
        customer_id = EXCLUDED.customer_id,
        worker_id = EXCLUDED.worker_id,
        car_vin = EXCLUDED.car_vin,
        task_value = EXCLUDED.task_value,
        has_autopart = EXCLUDED.has_autopart,
        autopart_name = EXCLUDED.autopart_name,
        task_description = EXCLUDED.task_description,
        order_description = EXCLUDED.order_description,
        order_created_at = EXCLUDED.order_created_at,
        closure_date = EXCLUDED.closure_date,
        load_dttm = now();
END;
$$;

COMMIT;
