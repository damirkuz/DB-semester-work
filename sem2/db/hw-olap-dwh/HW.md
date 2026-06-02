# ДЗ OLAP / OLTP / DWH

## 1. Что нужно было сделать

По заданию нужно взять уже существующую OLTP-схему проекта и построить для нее аналитическую модель в отдельной схеме `olap`.

Аналитические вопросы:

- какая динамика ремонтных работ и выручки по дням;
- какие филиалы и мастера самые загруженные;
- сколько ремонтных действий и денег дают клиентские сегменты;
- какие модели автомобилей чаще всего попадают в ремонт.

## 2. Главный факт и зерно

Главный факт: `olap.fact_repair_task`.
```text
1 строка = 1 ремонтная задача из autoservice_schema.task
```

## 3. OLAP-модель

Миграции:

- [V7__create_olap_schema.sql](../migrations/V7__create_olap_schema.sql) - создает схему `olap`, измерения, факт, индексы и функцию обновления витрины;
- [V8__load_olap_mart.sql](../migrations/V8__load_olap_mart.sql) - выполняет первичную загрузку витрины.

Измерения:

- `olap.dim_date` - календарь по датам заказов;
- `olap.dim_customer` - клиент и сегмент по `tags`;
- `olap.dim_worker_branch` - мастер вместе с филиалом;
- `olap.dim_car` - автомобиль, модель, статус, тип бокса.

Факт:

```sql
olap.fact_repair_task (
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
```

Для повторной загрузки есть функция:

```sql
SELECT olap.refresh_repair_task_mart();
```

Она обновляет измерения и факт через `INSERT ... ON CONFLICT DO UPDATE`, поэтому ее можно запускать повторно после появления новых OLTP-данных.

## 4. Запуск

Поднять PostgreSQL и применить миграции:

```bash
cd sem2
docker compose up -d postgres
docker compose up flyway
```

Повторно обновить OLAP-витрину вручную:

```bash
cd sem2
docker compose exec -T postgres psql -U admin -d autoservice_db < db/hw-olap-dwh/refresh_olap.sql
```

Запустить аналитические запросы:

```bash
cd sem2
docker compose exec -T postgres psql -U admin -d autoservice_db < db/hw-olap-dwh/analytical_queries.sql
```

Запустить smoke-тест:

```bash
cd sem2
docker compose exec -T postgres psql -U admin -d autoservice_db -v ON_ERROR_STOP=1 < db/hw-olap-dwh/smoke_test.sql
```

Smoke-тест внутри транзакции создает тестовый филиал, мастера, клиента, автомобиль, заказ, ремонтную задачу и запчасть. Затем вызывает `olap.refresh_repair_task_mart()`, проверяет появление строки в `fact_repair_task` и делает `ROLLBACK`, чтобы не оставлять тестовые данные.


## 6. Аналитические запросы

Файл с запросами: [analytical_queries.sql](analytical_queries.sql).

### 7.1 Динамика активности и выручки по дням

```sql
SELECT
    d.date_id,
    d.week_of_year,
    count(*) AS repair_tasks,
    round(sum(f.task_value), 2) AS revenue,
    round(avg(f.task_value), 2) AS avg_task_value
FROM olap.fact_repair_task f
JOIN olap.dim_date d ON d.date_id = f.date_id
GROUP BY d.date_id, d.week_of_year
ORDER BY d.date_id
LIMIT 15;
```

Пример результата:

```text
  date_id   | week_of_year | repair_tasks |  revenue   | avg_task_value
------------+--------------+--------------+------------+----------------
 2025-11-07 |           45 |          335 |  841708.97 |        2512.56
 2025-11-08 |           45 |         2574 | 6394393.30 |        2484.22
 2025-11-09 |           45 |         2583 | 6511391.97 |        2520.86
 2025-11-10 |           46 |         2500 | 6275847.42 |        2510.34
 2025-11-11 |           46 |         2510 | 6247118.98 |        2488.89
```

### 7.2 Самые загруженные филиалы и мастера

```text
 branch_office_id |   branch_address   | worker_id |  worker_name  | worker_role | repair_tasks | revenue
------------------+--------------------+-----------+---------------+-------------+--------------+----------
             1818 | Branch Addr 1818   |    180916 | Worker 180916 | Master      |            8 | 18573.22
            60835 | Branch Addr 60835  |    234089 | Worker 234089 | Manager     |            8 | 17752.71
            69425 | Branch Addr 69425  |    214413 | Worker 214413 | Mechanic    |            8 | 16719.67
```

### 7.3 Клиентские сегменты

```text
 customer_segment | customers | repair_tasks |   revenue    | avg_task_value
------------------+-----------+--------------+--------------+----------------
 regular          |     39288 |       104966 | 261996131.82 |        2496.01
 new              |     27885 |        74609 | 186679324.99 |        2502.10
 vip              |     26323 |        70425 | 175700431.93 |        2494.86
```

### 7.4 Популярные модели автомобилей

```text
   model   | status | repair_tasks |   revenue    | tasks_with_autoparts
-----------+--------+--------------+--------------+----------------------
 CommonCar | Ready  |       180027 | 449603146.81 |               180027
 CommonCar | Repair |        44670 | 111201113.39 |                44670
 RareCar   | Ready  |        20333 |  51143931.71 |                20333
 RareCar   | Repair |         4970 |  12427696.83 |                 4970
```

## 8. Вывод

OLTP-схема автосервиса хранит нормализованные операционные данные: заказы, задачи ремонта, клиентов, работников, филиалы и автомобили.

OLAP-схема `olap` выносит аналитическую нагрузку в отдельную модель: один факт ремонта и четыре измерения. За счет этого аналитические запросы не собирают каждый раз длинную цепочку join из исходной схемы, а работают с готовой витриной под вопросы бизнеса.
