# ДЗ Airflow

## 1. Что нужно было сделать

По заданию нужно реализовать два сценария обработки данных в Apache Airflow:

- ETL-сценарий: загрузить данные из двух внешних источников в основную БД проекта;
- Analytics-сценарий: переложить данные из основной БД проекта в ClickHouse и построить аналитическую витрину.

## 2. Источники данных

Используются два разных источника:

- [customer_leads.csv](data/customer_leads.csv) - CSV с клиентскими лидами;
- [service_campaigns.json](data/service_campaigns.json) - JSON со скидочными сервисными кампаниями.

CSV пополняет существующую таблицу `autoservice_schema.customer`. Для идемпотентности клиент ищется по `phone_number`: если он уже есть, обновляются `full_name` и `tags`; если нет - вставляется новая строка. Всем импортированным клиентам добавляется тег `airflow_import`.

JSON пополняет таблицу `autoservice_schema.service_campaign`. Для идемпотентности используется `campaign_code` и `ON CONFLICT DO UPDATE`.

Журнал загрузок пишется в `airflow_hw.load_audit`.

## 3. DAG 1: ETL в PostgreSQL

Файл DAG: [autoservice_airflow_hw.py](dags/autoservice_airflow_hw.py).

DAG `autoservice_etl_to_postgres` запускается каждый день в `02:00` и состоит из задач:

- `check_sources` - проверяет наличие CSV и JSON;
- `load_customer_leads` - валидирует CSV и загружает клиентов в `autoservice_schema.customer`;
- `load_service_campaigns` - валидирует JSON и загружает акции в `autoservice_schema.service_campaign`;
- `postgres_quality_checks` - проверяет, что импортированные данные есть и не нарушают правила качества.

Проверки качества:

- телефон клиента должен соответствовать формату `+7XXXXXXXXXX`;
- период кампании должен иметь `valid_from <= valid_to`;
- скидка должна быть от `0` до `100`;
- некорректные строки не загружаются, а фиксируются в `airflow_hw.load_audit.details`.

## 4. DAG 2: PostgreSQL -> ClickHouse

DAG `autoservice_analytics_to_clickhouse` запускается каждый день в `02:30`, после ETL-окна.

Он переносит данные из основной PostgreSQL БД в ClickHouse:

- `autoservice_raw.repair_tasks` - ремонтные задачи автосервиса;
- `autoservice_raw.airflow_customers` - клиенты, импортированные через Airflow;
- `autoservice_raw.service_campaigns` - сервисные кампании.

Потом строится витрина:

```text
autoservice_analytics.branch_daily_repair_mart
```

Зерно витрины:

```text
1 строка = 1 филиал автосервиса за 1 день ремонта
```

Метрики:

- `repair_tasks` - количество ремонтных задач;
- `unique_customers` - количество уникальных клиентов;
- `revenue` - сумма стоимости ремонтных задач;
- `avg_task_value` - средняя стоимость задачи;
- `autopart_tasks` - сколько задач связано с запчастями;
- `imported_customers` - сколько клиентов было импортировано из CSV;
- `active_campaigns` - сколько сервисных кампаний было активно в дату ремонта.

Идемпотентность ClickHouse-сценария обеспечена полной пересборкой raw-таблиц и витрины: перед загрузкой выполняется `TRUNCATE`, затем данные заново читаются из PostgreSQL.

## 5. Запуск

Сначала поднять основной PostgreSQL и применить миграции:

```bash
cd sem2
docker compose up -d postgres
docker compose up flyway
```

Запустить инфраструктуру Airflow и ClickHouse:

```bash
cd sem2/db/hw-airflow
docker compose up airflow-init
docker compose up -d airflow-webserver airflow-scheduler clickhouse
```

Airflow UI доступен на `http://localhost:8080`, логин/пароль: `admin/admin`.


```bash
cd sem2/db/hw-airflow
docker compose --profile debug run --rm airflow-cli \
  python /opt/airflow/hw/run_pipeline_smoke.py --mode all
```

## 6. Проверочные SQL

PostgreSQL:

```bash
cd sem2
docker compose exec -T postgres psql -U admin -d autoservice_db \
  < db/hw-airflow/sql/postgres_quality_checks.sql
```

ClickHouse:

```bash
cd sem2/db/hw-airflow
docker compose exec -T clickhouse clickhouse-client --password clickhouse \
  < sql/clickhouse_mart_checks.sql
```

## 7. Пример результатов

После DAG 1 ожидается, что из CSV загрузится 5 валидных клиентов, а 1 строка с плохим телефоном попадет в reject. Из JSON загрузятся 3 валидные кампании, а кампания `AIRFLOW-BAD-DATE` попадет в reject из-за периода `valid_from > valid_to`.

Пример результата smoke-скрипта:

```json
{
  "etl": {
    "customer_leads": {
      "loaded_rows": 5,
      "rejected_rows": 1
    },
    "service_campaigns": {
      "loaded_rows": 3,
      "rejected_rows": 1
    }
  },
  "analytics": {
    "export": {
      "repair_tasks": 50000,
      "airflow_customers": 5,
      "service_campaigns": 3
    },
    "mart": {
      "mart_rows": 45890
    },
    "quality": {
      "raw_repair_tasks": 50000,
      "raw_airflow_customers": 5,
      "raw_campaigns": 3,
      "mart_rows": 45890,
      "mart_revenue": "124373126.06"
    }
  }
}
```

Проверка DAG-ов через Airflow CLI:

```text
autoservice_analytics_to_clickhouse | /opt/airflow/dags/autoservice_airflow_hw.py | damir | None
autoservice_etl_to_postgres         | /opt/airflow/dags/autoservice_airflow_hw.py | damir | None
```

`airflow dags test autoservice_etl_to_postgres 2026-06-02`:

```text
load_service_campaigns: {'loaded_rows': 3, 'rejected_rows': 1}
load_customer_leads: {'loaded_rows': 5, 'rejected_rows': 1}
postgres_quality_checks: {'imported_customers': 5, 'bad_imported_phones': 0, 'campaigns': 3, 'bad_campaign_periods': 0}
DagRun Finished: dag_id=autoservice_etl_to_postgres, state=success
```

`airflow dags test autoservice_analytics_to_clickhouse 2026-06-02`:

```text
export_postgres_to_clickhouse: {'repair_tasks': 50000, 'airflow_customers': 5, 'service_campaigns': 3}
build_branch_daily_repair_mart: {'mart_rows': 45890}
clickhouse_quality_checks: {'raw_repair_tasks': 50000, 'raw_airflow_customers': 5, 'raw_campaigns': 3, 'mart_rows': 45890, 'mart_revenue': '124373126.06'}
DagRun Finished: dag_id=autoservice_analytics_to_clickhouse, state=success
```

Результат ClickHouse SQL-проверки:

```text
mart_rows | repair_tasks | revenue
----------+--------------+-------------
45890     | 50000        | 124373126.06
```

Airflow UI после запуска `airflow-webserver` и `airflow-scheduler` доступен на `http://localhost:8080`. Health endpoint вернул:

```text
metadatabase: healthy
scheduler: healthy
```