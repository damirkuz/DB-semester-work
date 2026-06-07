const hwDb = db.getSiblingDB("autoservice_nosql");

function assertEq(actual, expected, message) {
  if (actual !== expected) {
    throw new Error(`${message}: expected ${expected}, got ${actual}`);
  }
}

function assertTrue(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

const customersCount = hwDb.customers.countDocuments();
const vehiclesCount = hwDb.vehicles.countDocuments();
const ordersCount = hwDb.repair_orders.countDocuments();

assertEq(customersCount, 4, "customers count");
assertEq(vehiclesCount, 4, "vehicles count");
assertEq(ordersCount, 6, "repair_orders count");

const orderWithRefs = hwDb.repair_orders.findOne({ status: "Completed" });
assertTrue(orderWithRefs !== null, "completed order exists");
assertTrue(
  hwDb.customers.countDocuments({ _id: orderWithRefs.customer_id }) === 1,
  "repair_order.customer_id references existing customer",
);
assertTrue(
  hwDb.vehicles.countDocuments({ _id: orderWithRefs.vehicle_id }) === 1,
  "repair_order.vehicle_id references existing vehicle",
);

const projectionResult = hwDb.customers
  .find({ "contacts.city": "Kazan" }, { _id: 0, full_name: 1, "contacts.phone": 1 })
  .toArray();
assertEq(projectionResult.length, 2, "projection find result size");
assertTrue(!("_id" in projectionResult[0]), "projection hides _id");

hwDb.customers.updateOne(
  { loyalty_level: "standard" },
  { $addToSet: { tags: "smoke_checked" }, $currentDate: { updated_at: true } },
);

hwDb.repair_orders.updateMany(
  { status: "Diagnostics" },
  { $set: { status: "InProgress" }, $currentDate: { updated_at: true } },
);

assertTrue(
  hwDb.customers.countDocuments({ tags: "smoke_checked" }) >= 1,
  "customer update added smoke_checked tag",
);
assertEq(
  hwDb.repair_orders.countDocuments({ status: "Diagnostics" }),
  0,
  "repair order update moved diagnostics orders",
);

const aggregateResult = hwDb.repair_orders
  .aggregate([
    { $unwind: "$services" },
    {
      $group: {
        _id: "$branch.name",
        orders: { $addToSet: "$_id" },
        revenue: { $sum: "$services.price" },
        avg_service_price: { $avg: "$services.price" },
      },
    },
    {
      $project: {
        _id: 0,
        branch: "$_id",
        orders_count: { $size: "$orders" },
        revenue: { $round: ["$revenue", 2] },
        avg_service_price: { $round: ["$avg_service_price", 2] },
      },
    },
    { $sort: { revenue: -1 } },
  ])
  .toArray();

assertTrue(aggregateResult.length >= 2, "aggregate returns branch rows");

printjson({
  status: "ok",
  counts: {
    customers: customersCount,
    vehicles: vehiclesCount,
    repair_orders: ordersCount,
  },
  projection_rows: projectionResult.length,
  aggregate_top_branch: aggregateResult[0],
});
