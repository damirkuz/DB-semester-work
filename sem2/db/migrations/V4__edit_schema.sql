BEGIN;

ALTER TABLE autoservice_schema.car
    ADD COLUMN IF NOT EXISTS specs JSONB;

ALTER TABLE autoservice_schema."order"
    ADD COLUMN IF NOT EXISTS meta_info JSONB;

ALTER TABLE autoservice_schema.customer
    ADD COLUMN IF NOT EXISTS tags TEXT[];

ALTER TABLE autoservice_schema.task
    ADD COLUMN IF NOT EXISTS description_search TSVECTOR;

ALTER TABLE autoservice_schema.purchase
    ADD COLUMN IF NOT EXISTS discount_period DATERANGE;

COMMIT;
