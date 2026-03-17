BEGIN;

INSERT INTO autoservice_schema.branch_office (id, address, phone_number)
VALUES
    (1, 'Nurnberg, Hauptmarkt 1', '+499111000001'),
    (2, 'Nurnberg, Furth Str. 25', '+499111000002')
ON CONFLICT (id) DO UPDATE
    SET address = EXCLUDED.address,
        phone_number = EXCLUDED.phone_number;

INSERT INTO autoservice_schema.box (id, id_branch_office, box_type)
VALUES
    (1, 1, 'repair'),
    (2, 1, 'diagnostic'),
    (3, 2, 'repair')
ON CONFLICT (id) DO UPDATE
    SET id_branch_office = EXCLUDED.id_branch_office,
        box_type = EXCLUDED.box_type;

INSERT INTO autoservice_schema.worker (id, full_name, role, phone_number, id_branch_office)
VALUES
    (1, 'Ivan Petrov', 'manager', '+79990000001', 1),
    (2, 'Anna Sokolova', 'mechanic', '+79990000002', 1),
    (3, 'Oleg Smirnov', 'manager', '+79990000003', 2),
    (4, 'Maria Kuznetsova', 'electrician', '+79990000004', 2)
ON CONFLICT (id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        role = EXCLUDED.role,
        phone_number = EXCLUDED.phone_number,
        id_branch_office = EXCLUDED.id_branch_office;

INSERT INTO autoservice_schema.branch_office_manager (branch_office_id, manager_id)
VALUES
    (1, 1),
    (2, 3)
ON CONFLICT (branch_office_id) DO UPDATE
    SET manager_id = EXCLUDED.manager_id;

INSERT INTO autoservice_schema.provider (id, address, phone_number)
VALUES
    (1, 'Berlin, Lagerstrasse 10', '+493000000001'),
    (2, 'Munchen, Industriepark 7', '+498900000002')
ON CONFLICT (id) DO UPDATE
    SET address = EXCLUDED.address,
        phone_number = EXCLUDED.phone_number;

COMMIT;
