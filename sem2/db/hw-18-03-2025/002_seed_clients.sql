BEGIN;

INSERT INTO autoservice_schema.customer (id, full_name, phone_number, tags)
VALUES
    (1, 'Max Mustermann', '+491511000001', ARRAY['vip', 'business']),
    (2, 'Erika Musterfrau', '+491511000002', ARRAY['new']),
    (3, 'John Doe', '+491511000003', ARRAY['fleet'])
ON CONFLICT (id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        phone_number = EXCLUDED.phone_number,
        tags = EXCLUDED.tags;

INSERT INTO autoservice_schema.car (vin, model, plate_number, status, box_id, specs)
VALUES
    ('WVWZZZ1JZXW000001', 'Volkswagen Golf', 'N-AB1234', 'in_service', 1, '{"color":"black","year":2018}'::jsonb),
    ('WBAAA11090C000002', 'BMW 320', 'N-CD5678', 'diagnostics', 2, '{"color":"white","year":2020}'::jsonb),
    ('VF1AAAAA654000003', 'Renault Clio', 'N-EF9012', 'waiting_parts', 3, '{"color":"blue","year":2017}'::jsonb)
ON CONFLICT (vin) DO UPDATE
    SET model = EXCLUDED.model,
        plate_number = EXCLUDED.plate_number,
        status = EXCLUDED.status,
        box_id = EXCLUDED.box_id,
        specs = EXCLUDED.specs;

COMMIT;
