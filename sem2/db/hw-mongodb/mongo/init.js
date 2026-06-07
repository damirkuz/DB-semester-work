const hwDb = db.getSiblingDB("autoservice_nosql");

hwDb.customers.drop();
hwDb.vehicles.drop();
hwDb.repair_orders.drop();

const customerIds = [
  ObjectId("665000000000000000000001"),
  ObjectId("665000000000000000000002"),
  ObjectId("665000000000000000000003"),
  ObjectId("665000000000000000000004"),
];

const vehicleIds = [
  ObjectId("665000000000000000000101"),
  ObjectId("665000000000000000000102"),
  ObjectId("665000000000000000000103"),
  ObjectId("665000000000000000000104"),
];

hwDb.customers.insertMany([
  {
    _id: customerIds[0],
    full_name: "Damir Kuzdikenov",
    loyalty_level: "vip",
    contacts: {
      phone: "+79000000001",
      city: "Kazan",
      preferred_channel: "telegram",
    },
    tags: ["vip", "mobile_app"],
  },
  {
    _id: customerIds[1],
    full_name: "Alina Petrova",
    loyalty_level: "standard",
    contacts: {
      phone: "+79000000002",
      city: "Kazan",
      preferred_channel: "phone",
    },
    tags: ["regular"],
  },
  {
    _id: customerIds[2],
    full_name: "Timur Safin",
    loyalty_level: "new",
    contacts: {
      phone: "+79000000003",
      city: "Innopolis",
      preferred_channel: "email",
    },
    tags: ["new", "fleet"],
  },
  {
    _id: customerIds[3],
    full_name: "Bulat Akhmetov",
    loyalty_level: "standard",
    contacts: {
      phone: "+79000000004",
      city: "Naberezhnye Chelny",
      preferred_channel: "sms",
    },
    tags: ["regular", "discount"],
  },
]);

hwDb.vehicles.insertMany([
  {
    _id: vehicleIds[0],
    owner_id: customerIds[0],
    vin: "VINNOSQL0000001",
    model: "CommonCar",
    plate_number: "A001AA",
    specs: { engine: "V8", color: "Black", year: 2021 },
    service_history: [
      { date: ISODate("2026-04-10T09:00:00Z"), mileage: 42000, note: "Oil service" },
      { date: ISODate("2026-05-21T11:00:00Z"), mileage: 43600, note: "Brake check" },
    ],
  },
  {
    _id: vehicleIds[1],
    owner_id: customerIds[1],
    vin: "VINNOSQL0000002",
    model: "RareCar",
    plate_number: "B002BB",
    specs: { engine: "Hybrid", color: "White", year: 2023 },
    service_history: [{ date: ISODate("2026-05-18T10:30:00Z"), mileage: 12000, note: "Diagnostics" }],
  },
  {
    _id: vehicleIds[2],
    owner_id: customerIds[2],
    vin: "VINNOSQL0000003",
    model: "FleetVan",
    plate_number: "C003CC",
    specs: { engine: "Diesel", color: "Blue", year: 2020 },
    service_history: [{ date: ISODate("2026-05-03T08:30:00Z"), mileage: 81000, note: "Suspension" }],
  },
  {
    _id: vehicleIds[3],
    owner_id: customerIds[3],
    vin: "VINNOSQL0000004",
    model: "CommonCar",
    plate_number: "D004DD",
    specs: { engine: "V6", color: "Silver", year: 2022 },
    service_history: [],
  },
]);

hwDb.repair_orders.insertMany([
  {
    customer_id: customerIds[0],
    vehicle_id: vehicleIds[0],
    status: "Completed",
    created_at: ISODate("2026-06-01T08:00:00Z"),
    branch: { id: 1, name: "Kazan Center" },
    services: [
      { name: "Engine diagnostics", price: 3200 },
      { name: "Oil replacement", price: 2100 },
    ],
    used_parts: [
      { sku: "OIL-5W40", quantity: 1, price: 1800 },
      { sku: "FILTER-OIL", quantity: 1, price: 650 },
    ],
  },
  {
    customer_id: customerIds[1],
    vehicle_id: vehicleIds[1],
    status: "Diagnostics",
    created_at: ISODate("2026-06-02T09:30:00Z"),
    branch: { id: 1, name: "Kazan Center" },
    services: [{ name: "Computer diagnostics", price: 2500 }],
    used_parts: [],
  },
  {
    customer_id: customerIds[2],
    vehicle_id: vehicleIds[2],
    status: "Completed",
    created_at: ISODate("2026-06-02T12:20:00Z"),
    branch: { id: 2, name: "Innopolis Fleet" },
    services: [
      { name: "Suspension repair", price: 7400 },
      { name: "Wheel alignment", price: 1900 },
    ],
    used_parts: [{ sku: "ARM-FRONT", quantity: 2, price: 4200 }],
  },
  {
    customer_id: customerIds[3],
    vehicle_id: vehicleIds[3],
    status: "Ready",
    created_at: ISODate("2026-06-03T14:10:00Z"),
    branch: { id: 3, name: "Chelny South" },
    services: [{ name: "Body inspection", price: 1600 }],
    used_parts: [],
  },
  {
    customer_id: customerIds[0],
    vehicle_id: vehicleIds[0],
    status: "Completed",
    created_at: ISODate("2026-06-04T16:00:00Z"),
    branch: { id: 1, name: "Kazan Center" },
    services: [{ name: "Brake pads replacement", price: 4800 }],
    used_parts: [{ sku: "BRAKE-PADS", quantity: 1, price: 3700 }],
  },
  {
    customer_id: customerIds[2],
    vehicle_id: vehicleIds[2],
    status: "Diagnostics",
    created_at: ISODate("2026-06-05T10:45:00Z"),
    branch: { id: 2, name: "Innopolis Fleet" },
    services: [{ name: "Fleet pre-trip check", price: 2300 }],
    used_parts: [],
  },
]);

hwDb.customers.createIndex({ "contacts.city": 1 });
hwDb.vehicles.createIndex({ owner_id: 1 });
hwDb.repair_orders.createIndex({ customer_id: 1, vehicle_id: 1 });
hwDb.repair_orders.createIndex({ status: 1, created_at: -1 });

printjson({
  customers: hwDb.customers.countDocuments(),
  vehicles: hwDb.vehicles.countDocuments(),
  repair_orders: hwDb.repair_orders.countDocuments(),
});
