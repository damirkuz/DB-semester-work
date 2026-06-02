BEGIN;

DO $$
DECLARE
    v_branch_id INT;
    v_worker_id INT;
    v_customer_id INT;
    v_box_id INT;
    v_order_id INT;
    v_task_id INT;
    v_fact_count INT;
BEGIN
    INSERT INTO autoservice_schema.branch_office (address, phone_number)
    VALUES ('OLAP smoke branch', '+79990000001')
    RETURNING id INTO v_branch_id;

    INSERT INTO autoservice_schema.worker (full_name, role, phone_number, id_branch_office)
    VALUES ('OLAP smoke worker', 'Master', '+79990000002', v_branch_id)
    RETURNING id INTO v_worker_id;

    INSERT INTO autoservice_schema.customer (full_name, phone_number, tags)
    VALUES ('OLAP smoke customer', '+79990000003', ARRAY['vip', 'smoke'])
    RETURNING id INTO v_customer_id;

    INSERT INTO autoservice_schema.box (id_branch_office, box_type)
    VALUES (v_branch_id, 'Lift')
    RETURNING id INTO v_box_id;

    INSERT INTO autoservice_schema.car (vin, model, plate_number, status, box_id, specs)
    VALUES (
        'SMOKEVIN00000001',
        'SmokeCar',
        'S001MO',
        'Repair',
        v_box_id,
        '{"engine": "test", "color": "silver"}'::jsonb
    );

    INSERT INTO autoservice_schema."order" (customer_id, creation_date, description, meta_info)
    VALUES (
        v_customer_id,
        TIMESTAMP '2026-06-02 10:15:00',
        'OLAP smoke order',
        '{"source": "smoke_test"}'::jsonb
    )
    RETURNING id INTO v_order_id;

    INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id, description_search)
    VALUES (
        v_order_id,
        12345.67,
        v_worker_id,
        'OLAP smoke repair task',
        'SMOKEVIN00000001',
        to_tsvector('english', 'olap smoke repair task')
    )
    RETURNING id INTO v_task_id;

    INSERT INTO autoservice_schema.autopart (name, task_id)
    VALUES ('OLAP smoke autopart', v_task_id);

    PERFORM olap.refresh_repair_task_mart();

    SELECT count(*)
    INTO v_fact_count
    FROM olap.fact_repair_task f
    JOIN olap.dim_customer c ON c.customer_id = f.customer_id
    JOIN olap.dim_car car ON car.car_vin = f.car_vin
    WHERE f.task_id = v_task_id
      AND f.task_value = 12345.67
      AND f.has_autopart
      AND c.customer_segment = 'vip'
      AND car.model = 'SmokeCar';

    IF v_fact_count <> 1 THEN
        RAISE EXCEPTION 'Expected one OLAP fact for smoke task %, got %', v_task_id, v_fact_count;
    END IF;

    RAISE NOTICE 'Smoke OLAP fact created for task_id=%', v_task_id;
END $$;

ROLLBACK;
