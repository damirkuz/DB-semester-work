# ДЗ ClickHouse

## 1. Что нужно было сделать

По заданию нужно:

- поднять ClickHouse в `docker compose`;
- создать таблицу логов и загрузить 500000 строк;
- выполнить 4 аналитических запроса по логам;
- создать таблицу продаж в ClickHouse на 1000000 строк;
- создать похожую таблицу в PostgreSQL через Flyway-миграцию;
- сравнить аналитический запрос и размер данных;
- проверить HTTP-интерфейс ClickHouse.

## 2. Структура

- [docker-compose.yml](docker-compose.yml) - только ClickHouse;
- [clickhouse/01_create_and_seed.sql](clickhouse/01_create_and_seed.sql) - таблицы и данные ClickHouse;
- [clickhouse/02_web_log_queries.sql](clickhouse/02_web_log_queries.sql) - аналитика по логам;
- [clickhouse/03_sales_compare_queries.sql](clickhouse/03_sales_compare_queries.sql) - запрос для сравнения продаж;
- [clickhouse/smoke_test.sql](clickhouse/smoke_test.sql) - проверки ClickHouse;
- [postgres/postgres_sales_checks.sql](postgres/postgres_sales_checks.sql) - PostgreSQL-часть сравнения;
- [scripts/run_clickhouse_smoke.sh](scripts/run_clickhouse_smoke.sh) - быстрый запуск ClickHouse-проверки;
- [V10__create_nosql_clickhouse_sales_pg.sql](../migrations/V10__create_nosql_clickhouse_sales_pg.sql) - Flyway-миграция PostgreSQL.

## 3. ClickHouse

Поднять ClickHouse:

```bash
cd sem2/db/hw-clickhouse
docker compose up -d clickhouse
```

HTTP-интерфейс доступен на [http://localhost:8124](http://localhost:8124)

Создать таблицы и загрузить данные:

```bash
docker compose exec -T clickhouse clickhouse-client --password clickhouse --multiquery \
  < clickhouse/01_create_and_seed.sql
```

Запустить 4 запроса по логам:

```bash
docker compose exec -T clickhouse clickhouse-client --password clickhouse --multiquery \
  < clickhouse/02_web_log_queries.sql
```

Запустить запрос по продажам и посмотреть размер таблицы:

```bash
docker compose exec -T clickhouse clickhouse-client --password clickhouse --multiquery \
  < clickhouse/03_sales_compare_queries.sql
```

Smoke-тест:

```bash
cd sem2/db/hw-clickhouse
./scripts/run_clickhouse_smoke.sh
```

## 4. PostgreSQL-сравнение через Flyway

Для PostgreSQL добавлена миграция [V10__create_nosql_clickhouse_sales_pg.sql](../migrations/V10__create_nosql_clickhouse_sales_pg.sql). Она создает `nosql_hw.sales_pg`, индексы и загружает 1000000 строк.

Применить миграции:

```bash
cd sem2
docker compose up -d postgres
docker compose up flyway
```

Выполнить PostgreSQL-проверку:

```bash
cd sem2
docker compose exec -T postgres psql -U admin -d autoservice_db \
  < db/hw-clickhouse/postgres/postgres_sales_checks.sql
```

## 5. Пример результатов

ClickHouse smoke-тест:

```text
0
0
0
0
0
```

Результат запросов по логам:

```text
10.20.0.0   10000
10.20.0.1   10000
10.20.0.10  10000
10.20.0.11  10000

57.14  14.29  14.29

/admin/boxes  100000  500331.64  5  999984

0  3086
```

Для таблицы продаж ClickHouse проверка размера показала:

```text
rows_count  data_size_on_disk
1000000     12.41 MiB
```

PostgreSQL-проверка:

```text
sale_day    number_of_transactions  total_quantity  total_revenue  avg_price
2026-06-07  622                     3429            188965.74      54.52
2026-06-06  1440                    7920            400071.20      50.22

rows_count  total_relation_size
1000000     104 MB
```