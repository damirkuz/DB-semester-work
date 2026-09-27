# DB-semester-work — семестровые работы по базам данных (ИТИС КФУ)

Учебный проект по курсу «Базы данных»: семестр 1 — проектирование и SQL для БД «Автосервис», семестр 2 — продвинутый PostgreSQL и NoSQL (репликация, OLAP/DWH, ClickHouse, MongoDB, Airflow, Redis).

## Описание

**Sem 1** — командная работа (Куздикенов Дамир, Виноградов Дмитрий, Переверзев Евгений). Предметная область — сеть автомастерских. От ER-диаграммы и нормальных форм (до БКНФ) до триггеров, функций и транзакций: полный цикл проектирования реляционной БД на PostgreSQL.

**Sem 2** — индивидуальные ДЗ по администрированию и архитектуре данных: мониторинг PostgreSQL, роли и права, резервное копирование (WAL), логическая репликация, аналитическое хранилище (OLAP/DWH), Airflow-пайплайны, ClickHouse и MongoDB, очереди задач в БД. Плюс презентация по Redis/Valkey.

## Возможности

Sem 1 (`sem1/`):
- Схема `autoservice_schema`: филиалы, сотрудники, клиенты, заказы, автомобили, задачи, закупки (см. `create_tables.sql`).
- ER-диаграммы (`er-diagramm.png`, `er-diagramm-BKNF.png`) и разбор нормальных форм (`normal_forms.md`).
- Пакеты запросов по темам: JOIN (`select_join_queries.md`), агрегаты/GROUP BY, подзапросы и коррелированные подзапросы, CTE/UNION/оконные функции.
- Хранимые функции и процедуры (`fn_proc*.md`), триггеры (`trigger_cron*.md`), транзакции (`transaction.md`).
- Скрипты наполнения данными (`insert_data.sql`, `inserts_updates.sql`).

Sem 2 (`sem2/`):
- Docker Compose стек мониторинга: PostgreSQL + `postgres_exporter` + Prometheus + Grafana (`docker-compose.yml`, `prometheus.yml`).
- Flyway-миграции `db/migrations/` (V1–V10): схема, роли и права (`V2`, `V3`), OLAP-схема и витрина (`V7`, `V8`), очереди задач (`V6`), таблицы Airflow (`V9`), выгрузка в ClickHouse (`V10`).
- ДЗ по темам: WAL и бэкапы (`hw-18-03-2025`), логическая репликация primary/replica (`hw-25-03-2026`), OLAP/DWH (`hw-olap-dwh`), Airflow DAG'и (`hw-airflow`), ClickHouse (`hw-clickhouse`), MongoDB (`hw-mongodb`), очереди (`hw-queue`).
- Контрольная работа (`db/cw-1`) и Redis/Valkey ДЗ с презентацией (`presentation/`).

## Технологии

- PostgreSQL 15/16 (DDL, PL/pgSQL, роли, репликация, WAL)
- Docker / Docker Compose
- Flyway — миграции
- Apache Airflow 2.10.5 (LocalExecutor), ClickHouse, MongoDB, Redis/Valkey
- Prometheus + postgres_exporter + Grafana — мониторинг

## Запуск

Sem 2, основной стек мониторинга:

```bash
cd sem2
export DB_NAME=autoservice DB_USER=postgres DB_PASSWORD=postgres  # свои значения
docker compose up -d
```

Отдельные ДЗ запускаются из своих папок, например:

```bash
cd sem2/db/hw-airflow && docker compose up -d     # Airflow: localhost:8080
cd sem2/db/hw-clickhouse && docker compose up -d  # ClickHouse + Postgres
```

Sem 1 — SQL-скрипты выполняются в любом psql/клиенте по порядку: `create_tables.sql` → `insert_data.sql` → запросы из `.md` файлов.

## Структура проекта

```
sem1/                  — БД «Автосервис»: схема, ER, нормальные формы, SQL по темам
sem2/
  docker-compose.yml   — Postgres + postgres_exporter + Prometheus + Grafana
  db/migrations/       — Flyway V1–V10
  db/hw-*/             — ДЗ: WAL, репликация, OLAP/DWH, Airflow, ClickHouse, MongoDB
  db/cw-1/             — контрольная работа
  presentation/        — Redis/Valkey (PDF-презентация, ДЗ)
  queries.yaml         — реестр SQL-запросов
```
