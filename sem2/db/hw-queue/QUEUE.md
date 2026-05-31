# ДЗ по очередям PostgreSQL

## 1. Схема БД

Для очереди добавлена миграция [V6__create_queue_tasks.sql](../migrations/V6__create_queue_tasks.sql).

Бизнес-логика находится в предметной области автосервиса:

```sql
CREATE TABLE autoservice_schema.queue_business_event
(
    id          BIGSERIAL PRIMARY KEY,
    task_id     INT REFERENCES autoservice_schema.task (id),
    event_type  TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Очередь хранится в отдельной схеме `queue`:

```sql
CREATE TABLE queue.tasks
(
    id           BIGSERIAL PRIMARY KEY,
    task_type    TEXT NOT NULL,
    payload      JSONB NOT NULL DEFAULT '{}'::jsonb,
    priority     INT NOT NULL DEFAULT 0,
    status       TEXT NOT NULL DEFAULT 'Ready',
    attempts     INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 5,
    scheduled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    started_at   TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    worker_name  TEXT,
    error        TEXT
);
```

Для быстрого выбора задач используется частичный индекс:

```sql
CREATE INDEX idx_queue_tasks_ready
ON queue.tasks (priority DESC, scheduled_at ASC, created_at ASC, id ASC)
WHERE status = 'Ready';
```

## 2. Продьюсер

Код находится в [queue-java](queue-java).

Продьюсер в цикле создает задачи:

- `NORMAL_REPAIR_CHECK`, `priority = 0` - 80%;
- `CRITICAL_REPAIR_CHECK`, `priority = 100` - 20%.

В одной транзакции он:

1. выбирает случайную задачу ремонта из `autoservice_schema.task`;
2. создает событие в `autoservice_schema.queue_business_event`;
3. создает задачу в `queue.tasks`;
4. отправляет `NOTIFY autoservice_queue_tasks`.

Если вставка бизнес-события или задачи упадет, транзакция откатится целиком.

## 3. Консьюмеры

Два консьюмера запускаются как два независимых процесса с разными `CONSUMER_NAME`.

Задача берется запросом:

```sql
WITH picked AS (
    SELECT id
    FROM queue.tasks
    WHERE status = 'Ready'
      AND scheduled_at <= now()
    ORDER BY priority DESC, created_at ASC, id ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED
)
UPDATE queue.tasks t
SET status = 'Running',
    started_at = now(),
    worker_name = :workerName
FROM picked
WHERE t.id = picked.id
RETURNING t.id, t.priority;
```

`FOR UPDATE SKIP LOCKED` нужен, чтобы два воркера не взяли одну и ту же задачу.

После имитации обработки через `sleep` задача становится `Completed` или уходит в retry.

## 4. Запуск

Сначала поднимаем PostgreSQL и применяем миграции:

```bash
cd sem2
docker compose up -d postgres flyway
```

Собираем Java-приложение:

```bash
cd sem2/db/hw-queue/queue-java
mvn -q -DskipTests package
```

Запускаем продьюсера с высокой интенсивностью:

```bash
cd sem2/db/hw-queue/queue-java
APP_MODE=producer PRODUCER_RATE=300 java -jar target/queue-java-1.0.0.jar
```

Запускаем двух консьюмеров:

```bash
cd sem2/db/hw-queue/queue-java
APP_MODE=consumer CONSUMER_NAME=consumer-1 CONSUMER_SLEEP_MS=100 java -jar target/queue-java-1.0.0.jar
```

```bash
cd sem2/db/hw-queue/queue-java
APP_MODE=consumer CONSUMER_NAME=consumer-2 CONSUMER_SLEEP_MS=100 java -jar target/queue-java-1.0.0.jar
```

Запускаем мониторинг:

```bash
APP_MODE=monitor MONITOR_INTERVAL_MS=5000 java -jar target/queue-java-1.0.0.jar
```

## 5. Мониторинг лага и throughput

Лаг очереди считается как время ожидания самой старой задачи в `Ready`:

```sql
SELECT
    coalesce(
        extract(epoch FROM now() - min(created_at) FILTER (WHERE status = 'Ready')),
        0
    )::int AS lag_seconds
FROM queue.tasks;
```

Пропускная способность считается по задачам, завершенным за последние 10 секунд:

```sql
SELECT
    count(*) FILTER (
        WHERE status IN ('Completed', 'Failed')
          AND completed_at >= now() - interval '10 seconds'
    ) / 10.0 AS throughput_per_sec
FROM queue.tasks;
```

Общий запрос монитора:

```sql
SELECT
    count(*) FILTER (WHERE status = 'Ready') AS ready,
    count(*) FILTER (WHERE status = 'Running') AS running,
    count(*) FILTER (WHERE status = 'Completed') AS completed,
    count(*) FILTER (WHERE status = 'Failed') AS failed,
    count(*) FILTER (WHERE status = 'Ready' AND priority = 100) AS ready_priority_100,
    count(*) FILTER (WHERE status = 'Ready' AND priority = 0) AS ready_priority_0,
    count(*) FILTER (WHERE status = 'Completed' AND priority = 100) AS completed_priority_100,
    count(*) FILTER (WHERE status = 'Completed' AND priority = 0) AS completed_priority_0,
    coalesce(extract(epoch FROM now() - min(created_at) FILTER (WHERE status = 'Ready')), 0)::int AS lag_seconds,
    coalesce(extract(epoch FROM now() - min(created_at) FILTER (
        WHERE status = 'Ready' AND priority = 100
    )), 0)::int AS oldest_ready_priority_100,
    coalesce(extract(epoch FROM now() - min(created_at) FILTER (
        WHERE status = 'Ready' AND priority = 0
    )), 0)::int AS oldest_ready_priority_0,
    count(*) FILTER (
        WHERE status IN ('Completed', 'Failed')
          AND completed_at >= now() - interval '10 seconds'
    ) / 10.0 AS throughput_per_sec,
    coalesce(avg(extract(epoch FROM started_at - created_at))
        FILTER (WHERE priority = 100 AND started_at IS NOT NULL), 0)::numeric(10,2) AS avg_wait_priority_100,
    coalesce(avg(extract(epoch FROM started_at - created_at))
        FILTER (WHERE priority = 0 AND started_at IS NOT NULL), 0)::numeric(10,2) AS avg_wait_priority_0
FROM queue.tasks;
```

Пример логов при продьюсере на 300 задач в секунду и двух консьюмерах:

```text
ready=106 running=2 completed=25 failed=0 lag=2s throughput=2.5/s ready_p100=8 ready_p0=98 completed_p100=16 completed_p0=9 oldest_ready_p100=1s oldest_ready_p0=2s avg_wait_p100=0.12s avg_wait_p0=0.54s
ready=363 running=2 completed=53 failed=0 lag=4s throughput=5.3/s ready_p100=24 ready_p0=339 completed_p100=44 completed_p0=9 oldest_ready_p100=2s oldest_ready_p0=4s avg_wait_p100=0.41s avg_wait_p0=0.54s
ready=818 running=2 completed=107 failed=0 lag=8s throughput=10.7/s ready_p100=76 ready_p0=742 completed_p100=98 completed_p0=9 oldest_ready_p100=5s oldest_ready_p0=8s avg_wait_p100=1.11s avg_wait_p0=0.54s
```

Очередь растет, потому что продьюсер создает задачи быстрее, чем два консьюмера их обрабатывают. Из-за сортировки `ORDER BY priority DESC, created_at ASC` критические задачи с `priority = 100` выбираются раньше обычных задач с `priority = 0`, даже если были созданы позже. Это видно по логам: количество завершенных критических задач быстро становится намного больше, чем обычных (`completed_p100 > completed_p0`), а обычные задачи копятся в ожидании (`ready_p0` растет).

Проверочный SQL по приоритетам:

```sql
SELECT
    priority,
    count(*) FILTER (WHERE status = 'Ready') AS ready,
    count(*) FILTER (WHERE status = 'Completed') AS completed,
    round(avg(extract(epoch FROM started_at - created_at))
        FILTER (WHERE started_at IS NOT NULL), 2) AS avg_started_wait,
    coalesce(round(extract(epoch FROM now() - min(created_at) FILTER (WHERE status = 'Ready')), 2), 0)
        AS oldest_ready_wait
FROM queue.tasks
GROUP BY priority
ORDER BY priority DESC;
```

## 6. Retry

Если обработка завершилась ошибкой, воркер увеличивает `attempts`.

Если лимит попыток не исчерпан, задача возвращается в `Ready`, а `scheduled_at` переносится в будущее:

```sql
now() + power(2, attempts) * interval '5 minutes'
```

Если попытки закончились, задача получает статус `Failed`.

Проверка:

```sql
SELECT id, status, attempts, scheduled_at, error
FROM queue.tasks
WHERE attempts > 0
ORDER BY id DESC
LIMIT 10;
```

## 7. LISTEN / NOTIFY

Консьюмер подписывается на канал:

```sql
LISTEN autoservice_queue_tasks;
```

Продьюсер после вставки задачи вызывает:

```sql
NOTIFY autoservice_queue_tasks, 'new_task';
```

Если задач нет, консьюмер ждет уведомление до 1000 мс и затем повторно проверяет очередь. Так он не делает постоянный polling каждую миллисекунду.

## 8. Bloat и VACUUM

Очередь часто обновляет строки: `Ready -> Running -> Completed/Failed`. Для PostgreSQL это создает мертвые версии строк из-за MVCC, поэтому для `queue.tasks` настроен более агрессивный autovacuum:

```sql
ALTER TABLE queue.tasks SET (
    autovacuum_vacuum_scale_factor = 0.01,
    autovacuum_analyze_scale_factor = 0.005,
    autovacuum_vacuum_threshold = 50,
    autovacuum_analyze_threshold = 50
);
```

Размер таблицы можно проверить так:

```sql
SELECT
    pg_size_pretty(pg_total_relation_size('queue.tasks')) AS total_size,
    pg_size_pretty(pg_relation_size('queue.tasks')) AS table_size;
```

Ручная очистка во время теста:

```sql
VACUUM ANALYZE queue.tasks;
```
