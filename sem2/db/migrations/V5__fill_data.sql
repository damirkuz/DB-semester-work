BEGIN;

SELECT setseed(0.5);

INSERT INTO autoservice_schema.branch_office (address, phone_number)
SELECT
    'Branch Addr ' || i,
    '+7' || (9000000000 + floor(random() * 100000000)::bigint)
FROM generate_series(1, 250000) AS i;


-- Распределение: Zipf по id_branch_office
-- 80% работников работают в филиалах c id с 1 по 100
-- Низкая селективность (всего 3 роли)
INSERT INTO autoservice_schema.worker (full_name, role, phone_number, id_branch_office)
SELECT
    'Worker ' || i,
    CASE (i % 3)
        WHEN 0 THEN 'Mechanic'
        WHEN 1 THEN 'Master'
        ELSE 'Manager'
        END,
    '+7' || (9000000000 + i),
    (floor(power(random(), 4) * 250000) + 1)::int
FROM generate_series(1, 250000) AS i;

-- NULL значения: 20% адресов отсутствуют
INSERT INTO autoservice_schema.provider (address, phone_number)
SELECT
    CASE WHEN random() < 0.2 THEN NULL ELSE 'Provider St. ' || i END,
    '+7' || (8000000000 + i)
FROM generate_series(1, 250000) AS i;

-- tags массивы
-- phone_number высокая кардинальность
INSERT INTO autoservice_schema.customer (full_name, phone_number, tags)
SELECT
    'Customer ' || i,
    '+7' || lpad(i::text, 10, '0'),
    CASE WHEN random() < 0.3 THEN ARRAY['new']
         WHEN random() < 0.6 THEN ARRAY['regular', 'discount']
         ELSE ARRAY['vip', 'corp'] END
FROM generate_series(1, 250000) AS i;


INSERT INTO autoservice_schema.box (id_branch_office, box_type)
SELECT
    (floor(random() * 250000) + 1)::int,
    CASE WHEN random() < 0.5 THEN 'Lift' ELSE 'Pit' END
FROM generate_series(1, 250000) AS i;


INSERT INTO autoservice_schema.car (vin, model, plate_number, status, box_id, specs)
SELECT
    'VIN_' || lpad(i::text, 13, '0'),
    CASE WHEN random() < 0.1 THEN 'RareCar' ELSE 'CommonCar' END,
    'A' || lpad((i % 999)::text, 3, '0') || 'AA',
    CASE WHEN random() < 0.8 THEN 'Ready' ELSE 'Repair' END,
    (floor(random() * 250000) + 1)::int,
    jsonb_build_object('engine', 'V8', 'color', CASE WHEN random() > 0.5 THEN 'Black' ELSE 'White' END)
FROM generate_series(1, 250000) AS i;

-- Range тип discount_period
-- У provider_id некоторые поставщики используются чаще
INSERT INTO autoservice_schema.purchase (provider_id, date, value, discount_period)
SELECT
    (floor(power(random(), 3) * 250000) + 1)::int,
    NOW() - (random() * 365 || ' days')::interval,
    (random() * 10000)::decimal(19,2),
    daterange(CURRENT_DATE, CURRENT_DATE + (random()*30)::int)
FROM generate_series(1, 250000) AS i;


INSERT INTO autoservice_schema."order" (customer_id, creation_date, description, meta_info)
SELECT
    -- Нормальное распределение ID клиентов
    GREATEST(1, LEAST(250000, 125000 + (random() + random() + random() - 1.5) * 50000))::int,
    NOW() - (random() * 100 || ' days')::interval,
    'Order desc ' || i,
    jsonb_build_object('source', 'mobile_app', 'version', 1.0)
FROM generate_series(1, 250000) AS i;


INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id, description_search)
SELECT
    i,
    (random() * 5000)::decimal(19,2),
    (floor(random() * 250000) + 1)::int,
    CASE WHEN random() < 0.2 THEN NULL ELSE 'Fix engine part ' || i END,
    'VIN_' || lpad((floor(random() * 250000) + 1)::text, 13, '0'),
    to_tsvector('english', 'repair fix service ' || i) -- Полнотекстовый
FROM generate_series(1, 250000) AS i;


-- value диапазон зарплат
INSERT INTO autoservice_schema.payout (value, date, payout_type, worker_id)
SELECT
    (20000 + random() * 80000)::int,
    NOW() - (random() * 60 || ' days')::interval,
    CASE WHEN random() < 0.9 THEN 'Salary' ELSE 'Bonus' END,
    (floor(random() * 250000) + 1)::int
FROM generate_series(1, 250000) AS i;

INSERT INTO autoservice_schema.order_car (order_id, car_id)
SELECT
    i,
    'VIN_' || lpad(i::text, 13, '0')
FROM generate_series(1, 250000) AS i;

INSERT INTO autoservice_schema.autopart (name, purchase_id, task_id)
SELECT
    'Part ' || i,
    i,
    i
FROM generate_series(1, 250000) AS i;

COMMIT;

ANALYZE autoservice_schema.branch_office;
ANALYZE autoservice_schema.worker;
ANALYZE autoservice_schema.provider;
ANALYZE autoservice_schema.customer;
ANALYZE autoservice_schema.purchase;
ANALYZE autoservice_schema."order";
ANALYZE autoservice_schema.box;
ANALYZE autoservice_schema.car;
ANALYZE autoservice_schema.task;
ANALYZE autoservice_schema.payout;
