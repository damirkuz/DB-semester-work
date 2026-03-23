# Redis / Valkey — Запуск-гайд

## Быстрый запуск (docker run)

### Redis

```bash
docker run -d --name redis -p 6379:6379 redis:7
```

### Valkey (open-source форк Redis)

```bash
docker run -d --name valkey -p 6379:6379 valkey/valkey:8
```

## Запуск через Docker Compose

Создайте файл `docker-compose.yml`:

```yaml
services:
  redis:
    image: redis:7
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes

volumes:
  redis-data:
```

Запуск:

```bash
docker compose up -d
```

Параметр `--appendonly yes` включает AOF (журнал операций) — данные сохраняются на диск и не теряются при перезапуске контейнера.

## Подключение

### CLI (redis-cli)

```bash
docker exec -it redis redis-cli
```

## Остановка и удаление

```bash
# Остановить контейнер
docker stop redis

# Удалить контейнер
docker rm redis

# Или через Docker Compose
docker compose down
```