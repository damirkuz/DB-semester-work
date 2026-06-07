const hwDb = db.getSiblingDB("autoservice_nosql");

print("1. Find with projection: Kazan customers");
printjson(
  hwDb.customers
    .find(
      { "contacts.city": "Kazan" },
      { _id: 0, full_name: 1, loyalty_level: 1, "contacts.phone": 1 },
    )
    .toArray(),
);

print("2. Find: expensive completed repair orders");
printjson(
  hwDb.repair_orders
    .find({
      status: "Completed",
      "services.price": { $gte: 3000 },
    })
    .sort({ created_at: -1 })
    .toArray(),
);

print("3. Update one customer tag");
printjson(
  hwDb.customers.updateOne(
    { full_name: "Alina Petrova" },
    { $addToSet: { tags: "loyalty_candidate" }, $currentDate: { updated_at: true } },
  ),
);

print("4. Update diagnostics orders");
printjson(
  hwDb.repair_orders.updateMany(
    { status: { $in: ["Diagnostics", "InProgress"] } },
    { $set: { status: "InProgress" }, $currentDate: { updated_at: true } },
  ),
);

print("5. Aggregate: revenue by branch");
printjson(
  hwDb.repair_orders
    .aggregate([
      { $unwind: "$services" },
      {
        $group: {
          _id: "$branch.name",
          orders: { $addToSet: "$_id" },
          revenue: { $sum: "$services.price" },
          avg_service_price: { $avg: "$services.price" },
          services_count: { $sum: 1 },
        },
      },
      {
        $project: {
          _id: 0,
          branch: "$_id",
          orders_count: { $size: "$orders" },
          services_count: 1,
          revenue: { $round: ["$revenue", 2] },
          avg_service_price: { $round: ["$avg_service_price", 2] },
        },
      },
      { $sort: { revenue: -1 } },
    ])
    .toArray(),
);
