package ru.kuzdikenov.queue;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.Random;

@Component
class Producer {
    private final JdbcTemplate jdbc;
    private final TransactionTemplate tx;
    private final Random random = new Random();
    private final int ratePerSecond;
    private final int maxAttempts;
    private TaskIdRange taskIdRange;

    Producer(
            JdbcTemplate jdbc,
            TransactionTemplate tx,
            @Value("${app.producer.rate-per-second}") int ratePerSecond,
            @Value("${app.max-attempts}") int maxAttempts
    ) {
        this.jdbc = jdbc;
        this.tx = tx;
        this.ratePerSecond = ratePerSecond;
        this.maxAttempts = maxAttempts;
    }

    void run() throws InterruptedException {
        long delayMs = Math.max(1, 1000 / ratePerSecond);
        long created = 0;

        while (true) {
            createBusinessEventAndTask();
            created++;

            if (created % 100 == 0) {
                System.out.printf("producer created %d tasks%n", created);
            }

            Thread.sleep(delayMs);
        }
    }

    private void createBusinessEventAndTask() {
        tx.executeWithoutResult(status -> {
            Long serviceTaskId = pickServiceTaskId();
            boolean critical = random.nextDouble() < 0.20;
            int priority = critical ? 100 : 0;
            String taskType = critical ? "CRITICAL_REPAIR_CHECK" : "NORMAL_REPAIR_CHECK";

            Long eventId = jdbc.queryForObject("""
                    INSERT INTO autoservice_schema.queue_business_event(task_id, event_type)
                    VALUES (?, ?)
                    RETURNING id
                    """, Long.class, serviceTaskId, taskType);

            jdbc.update("""
                    INSERT INTO queue.tasks(task_type, payload, priority, max_attempts)
                    VALUES (
                        ?,
                        jsonb_build_object('service_task_id', ?, 'business_event_id', ?),
                        ?,
                        ?
                    )
                    """, taskType, serviceTaskId, eventId, priority, maxAttempts);

            jdbc.execute("NOTIFY autoservice_queue_tasks, 'new_task'");
        });
    }

    private Long pickServiceTaskId() {
        TaskIdRange range = getTaskIdRange();
        long candidate = range.minId() + random.nextLong(range.maxId() - range.minId() + 1);

        Long serviceTaskId = jdbc.query("""
                SELECT id
                FROM autoservice_schema.task
                WHERE id >= ?
                ORDER BY id
                LIMIT 1
                """, rs -> rs.next() ? rs.getLong("id") : null, candidate);

        return serviceTaskId != null ? serviceTaskId : range.minId();
    }

    private TaskIdRange getTaskIdRange() {
        if (taskIdRange == null) {
            taskIdRange = jdbc.queryForObject("""
                    SELECT min(id) AS min_id, max(id) AS max_id
                    FROM autoservice_schema.task
                    """, (rs, rowNum) -> {
                long minId = rs.getLong("min_id");
                long maxId = rs.getLong("max_id");

                if (rs.wasNull()) {
                    throw new IllegalStateException("autoservice_schema.task is empty");
                }

                return new TaskIdRange(minId, maxId);
            });
        }

        return taskIdRange;
    }

    private record TaskIdRange(long minId, long maxId) {
    }
}
