BEGIN;

CREATE SCHEMA IF NOT EXISTS queue;

CREATE TABLE IF NOT EXISTS autoservice_schema.queue_business_event
(
    id          BIGSERIAL PRIMARY KEY,
    task_id     INT REFERENCES autoservice_schema.task (id),
    event_type  TEXT                     NOT NULL,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS queue.tasks
(
    id           BIGSERIAL PRIMARY KEY,
    task_type    TEXT                     NOT NULL,
    payload      JSONB                    NOT NULL DEFAULT '{}'::jsonb,
    priority     INT                      NOT NULL DEFAULT 0,
    status       TEXT                     NOT NULL DEFAULT 'Ready',
    attempts     INT                      NOT NULL DEFAULT 0,
    max_attempts INT                      NOT NULL DEFAULT 5,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    started_at   TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    worker_name  TEXT,
    error        TEXT,
    CONSTRAINT queue_tasks_status_check
        CHECK (status IN ('Ready', 'Running', 'Completed', 'Failed')),
    CONSTRAINT queue_tasks_attempts_check
        CHECK (attempts >= 0 AND max_attempts > 0),
    CONSTRAINT queue_tasks_priority_check
        CHECK (priority >= 0)
);

CREATE INDEX IF NOT EXISTS idx_queue_tasks_ready
    ON queue.tasks (priority DESC, scheduled_at ASC, created_at ASC, id ASC)
    WHERE status = 'Ready';

CREATE INDEX IF NOT EXISTS idx_queue_tasks_completed_at
    ON queue.tasks (completed_at)
    WHERE status IN ('Completed', 'Failed');

CREATE INDEX IF NOT EXISTS idx_queue_tasks_running_started_at
    ON queue.tasks (started_at)
    WHERE status = 'Running';

ALTER TABLE queue.tasks SET (
    autovacuum_vacuum_scale_factor = 0.01,
    autovacuum_analyze_scale_factor = 0.005,
    autovacuum_vacuum_threshold = 50,
    autovacuum_analyze_threshold = 50
);

COMMIT;
