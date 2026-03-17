BEGIN;

INSERT INTO autoservice_schema."order" (id, customer_id, creation_date, description, meta_info)
VALUES
    (1, 1, '2026-03-10 10:00:00', 'TO and oil change', '{"source":"seed","priority":"high"}'::jsonb),
    (2, 2, '2026-03-11 12:30:00', 'Electrical diagnostics', '{"source":"seed","priority":"medium"}'::jsonb)
ON CONFLICT (id) DO UPDATE
    SET customer_id = EXCLUDED.customer_id,
        creation_date = EXCLUDED.creation_date,
        description = EXCLUDED.description,
        meta_info = EXCLUDED.meta_info;

INSERT INTO autoservice_schema.order_car (order_id, car_id)
VALUES
    (1, 'WVWZZZ1JZXW000001'),
    (2, 'WBAAA11090C000002')
ON CONFLICT (order_id, car_id) DO NOTHING;

INSERT INTO autoservice_schema.task (id, order_id, value, worker_id, description, car_id, description_search)
VALUES
    (1, 1, 120.00, 2, 'Oil and filter replacement', 'WVWZZZ1JZXW000001', to_tsvector('simple', 'Oil and filter replacement')),
    (2, 2, 200.00, 4, 'Alternator and wiring diagnostics', 'WBAAA11090C000002', to_tsvector('simple', 'Alternator and wiring diagnostics'))
ON CONFLICT (id) DO UPDATE
    SET order_id = EXCLUDED.order_id,
        value = EXCLUDED.value,
        worker_id = EXCLUDED.worker_id,
        description = EXCLUDED.description,
        car_id = EXCLUDED.car_id,
        description_search = EXCLUDED.description_search;

INSERT INTO autoservice_schema.purchase (id, provider_id, date, value, discount_period)
VALUES
    (1, 1, '2026-03-09 09:00:00', 80.00, daterange('2026-03-01', '2026-03-31', '[]')),
    (2, 2, '2026-03-10 09:30:00', 150.00, daterange('2026-03-15', '2026-04-15', '[]'))
ON CONFLICT (id) DO UPDATE
    SET provider_id = EXCLUDED.provider_id,
        date = EXCLUDED.date,
        value = EXCLUDED.value,
        discount_period = EXCLUDED.discount_period;

INSERT INTO autoservice_schema.autopart (id, name, purchase_id, task_id)
VALUES
    (1, 'Oil Filter', 1, 1),
    (2, 'Alternator Belt', 2, 2)
ON CONFLICT (id) DO UPDATE
    SET name = EXCLUDED.name,
        purchase_id = EXCLUDED.purchase_id,
        task_id = EXCLUDED.task_id;

COMMIT;
