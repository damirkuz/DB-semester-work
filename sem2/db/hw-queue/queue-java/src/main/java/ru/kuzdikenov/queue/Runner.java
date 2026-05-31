package ru.kuzdikenov.queue;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
class Runner implements CommandLineRunner {
    private final Producer producer;
    private final Consumer consumer;
    private final Monitor monitor;
    private final String mode;

    Runner(
            Producer producer,
            Consumer consumer,
            Monitor monitor,
            @Value("${app.mode}") String mode
    ) {
        this.producer = producer;
        this.consumer = consumer;
        this.monitor = monitor;
        this.mode = mode;
    }

    @Override
    public void run(String... args) throws Exception {
        switch (mode) {
            case "producer" -> producer.run();
            case "consumer" -> consumer.run();
            case "monitor" -> monitor.run();
            default -> throw new IllegalArgumentException("Unknown app.mode=" + mode);
        }
    }
}
