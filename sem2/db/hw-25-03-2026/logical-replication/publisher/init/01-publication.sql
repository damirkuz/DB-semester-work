CREATE TABLE IF NOT EXISTS test_pk (
                                       id int primary key,
                                       name text
);

CREATE TABLE IF NOT EXISTS test_nopk (
                                         id int,
                                         name text
);

CREATE PUBLICATION pub_demo FOR TABLE test_pk, test_nopk;
