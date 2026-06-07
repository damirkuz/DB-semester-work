# ДЗ MongoDB

## 1. Что нужно было сделать

По заданию нужно:

- поднять MongoDB в `docker compose`;
- создать минимум 3 коллекции;
- связать хотя бы 2 коллекции через `ObjectId`;
- хранить вложенные JSON-объекты или массивы хотя бы в одной коллекции;
- наполнить коллекции данными;
- написать 2 `find`-запроса, один из них с projection;
- написать 2 `update`-запроса;
- написать 1 `aggregate`-запрос.

## 2. Структура

- [docker-compose.yml](docker-compose.yml) - MongoDB;
- [mongo/init.js](mongo/init.js) - создание коллекций, индексов и тестовых данных;
- [mongo/queries.js](mongo/queries.js) - `find`, `update`, `aggregate`;
- [mongo/smoke_test.js](mongo/smoke_test.js) - проверка сценария;
- [scripts/run_mongo_smoke.sh](scripts/run_mongo_smoke.sh) - быстрый запуск проверки.

## 3. Модель данных

Используется база autoservice_nosql

Коллекции:

- `customers` - клиенты автосервиса;
- `vehicles` - автомобили, связаны с `customers` через `owner_id`;
- `repair_orders` - ремонтные заказы, связаны с `customers` через `customer_id` и с `vehicles` через `vehicle_id`.

Вложенные JSON-объекты и массивы:

- `customers.contacts`;
- `customers.tags`;
- `vehicles.specs`;
- `vehicles.service_history`;
- `repair_orders.branch`;
- `repair_orders.services`;
- `repair_orders.used_parts`.

## 4. Запуск

Поднять MongoDB:

```bash
cd sem2/db/hw-mongodb
docker compose up -d mongodb
```

Выполнить запросы:

```bash
docker compose exec -T mongodb \
  mongosh "mongodb://root:root@localhost:27017/admin" \
  --file /homework/mongo/queries.js
```

Smoke-тест:

```bash
cd sem2/db/hw-mongodb
./scripts/run_mongo_smoke.sh
```

## 5. Запросы

`find` с projection:

```javascript
db.customers.find(
  { "contacts.city": "Kazan" },
  { _id: 0, full_name: 1, loyalty_level: 1, "contacts.phone": 1 }
)
```

Второй `find` ищет дорогие завершенные ремонтные заказы:

```javascript
db.repair_orders.find({
  status: "Completed",
  "services.price": { $gte: 3000 }
})
```

`update`-запросы добавляют тег клиенту и переводят диагностические заказы в работу. `aggregate` считает выручку по филиалам через `$unwind`, `$group`, `$project`, `$sort`.

## 6. Пример результата

Smoke-тест:

```javascript
{
  status: 'ok',
  counts: {
    customers: 4,
    vehicles: 4,
    repair_orders: 6
  },
  projection_rows: 2,
  aggregate_top_branch: {
    branch: 'Kazan Center',
    orders_count: 3,
    revenue: 12600,
    avg_service_price: 3150
  }
}
```

Фрагмент результата `queries.js`:

```text
1. Find with projection: Kazan customers
Damir Kuzdikenov, Alina Petrova

3. Update one customer tag
matchedCount: 1

4. Update diagnostics orders
matchedCount: 2

5. Aggregate: revenue by branch
Kazan Center      12600
Innopolis Fleet   11600
Chelny South       1600
```