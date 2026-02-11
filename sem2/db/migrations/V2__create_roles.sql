DO
$do$
    BEGIN
        IF NOT EXISTS (
            SELECT FROM pg_catalog.pg_roles
            WHERE  rolname = 'app') THEN

            CREATE ROLE app LOGIN PASSWORD 'app_pass';
        END IF;
    END
$do$;

DO
$do$
    BEGIN
        IF NOT EXISTS (
            SELECT FROM pg_catalog.pg_roles
            WHERE  rolname = 'readonly') THEN

            CREATE ROLE readonly LOGIN PASSWORD 'readonly_pass';
        END IF;
    END
$do$;
