import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';
import '../models/fitting.dart';
import '../models/measurement.dart';
import '../models/order.dart';
import '../models/payment_record.dart';
import '../services/notification_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('terzi.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        chest REAL,
        waist REAL,
        hips REAL,
        upper_height REAL,
        lower_height REAL,
        arm_length REAL,
        skirt_length REAL,
        pant_length REAL,
        vest_length REAL,
        jacket_length REAL,
        tunic_length REAL,
        upper_body_length REAL,
        short_length REAL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        customer_name TEXT NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        paid_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        delivery_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE fittings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        customer_name TEXT NOT NULL,
        order_id INTEGER,
        product_name TEXT,
        fitting_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (order_id) REFERENCES orders (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        paid_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id)
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE measurements ADD COLUMN upper_height REAL');
      await db.execute('ALTER TABLE measurements ADD COLUMN lower_height REAL');
      await db.execute('ALTER TABLE measurements ADD COLUMN skirt_length REAL');
      await db.execute('ALTER TABLE measurements ADD COLUMN pant_length REAL');
      await db.execute('ALTER TABLE measurements ADD COLUMN vest_length REAL');
      await db.execute('ALTER TABLE measurements ADD COLUMN jacket_length REAL');
      await db.execute('ALTER TABLE measurements ADD COLUMN tunic_length REAL');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fittings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER NOT NULL,
          customer_name TEXT NOT NULL,
          fitting_date TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers (id)
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE measurements ADD COLUMN upper_body_length REAL');
      await db.execute('ALTER TABLE measurements ADD COLUMN short_length REAL');
      await db.execute('ALTER TABLE fittings ADD COLUMN order_id INTEGER');
      await db.execute('ALTER TABLE fittings ADD COLUMN product_name TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE orders ADD COLUMN paid_amount REAL NOT NULL DEFAULT 0');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          paid_at TEXT NOT NULL,
          FOREIGN KEY (order_id) REFERENCES orders (id)
        )
      ''');
    }
  }

  // --- Müşteri işlemleri ---

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'name ASC');
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    await db.delete('measurements', where: 'customer_id = ?', whereArgs: [id]);
    // Önce müşteriye ait siparişlerin ödemelerini sil
    final orders = await db.query('orders', columns: ['id'], where: 'customer_id = ?', whereArgs: [id]);
    for (final o in orders) {
      await db.delete('payments', where: 'order_id = ?', whereArgs: [o['id']]);
    }
    await db.delete('orders', where: 'customer_id = ?', whereArgs: [id]);
    await db.delete('fittings', where: 'customer_id = ?', whereArgs: [id]);
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // --- Ölçü işlemleri ---

  Future<int> insertMeasurement(Measurement measurement) async {
    final db = await database;
    return await db.insert('measurements', measurement.toMap());
  }

  Future<List<Measurement>> getMeasurements(int customerId) async {
    final db = await database;
    final maps = await db.query(
      'measurements',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Measurement.fromMap(m)).toList();
  }

  Future<int> updateMeasurement(Measurement measurement) async {
    final db = await database;
    return await db.update(
      'measurements',
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }

  // --- Sipariş işlemleri ---

  Future<int> insertOrder(Order order) async {
    final db = await database;
    return await db.insert('orders', order.toMap());
  }

  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final maps = await db.query('orders', orderBy: 'delivery_date ASC');
    return maps.map((m) => Order.fromMap(m)).toList();
  }

  Future<List<Order>> getOrdersByCustomer(int customerId) async {
    final db = await database;
    final maps = await db.query(
      'orders',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'delivery_date ASC',
    );
    return maps.map((m) => Order.fromMap(m)).toList();
  }

  Future<int> updateOrder(Order order) async {
    final db = await database;
    return await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    await db.delete('payments', where: 'order_id = ?', whereArgs: [id]);
    return await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  // --- Ödeme işlemleri ---

  Future<int> insertPayment(PaymentRecord payment) async {
    final db = await database;
    return await db.insert('payments', payment.toMap());
  }

  Future<List<PaymentRecord>> getPaymentsByOrder(int orderId) async {
    final db = await database;
    final maps = await db.query(
      'payments',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'paid_at ASC',
    );
    return maps.map((m) => PaymentRecord.fromMap(m)).toList();
  }

  // --- Prova işlemleri ---

  Future<int> insertFitting(Fitting fitting) async {
    final db = await database;
    return await db.insert('fittings', fitting.toMap());
  }

  Future<List<Fitting>> getFittings(int customerId) async {
    final db = await database;
    final maps = await db.query(
      'fittings',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'fitting_date ASC',
    );
    return maps.map((m) => Fitting.fromMap(m)).toList();
  }

  Future<List<Fitting>> getAllFittings() async {
    final db = await database;
    final maps = await db.query('fittings', orderBy: 'fitting_date ASC');
    return maps.map((m) => Fitting.fromMap(m)).toList();
  }

  Future<void> deleteFittingsByOrder(int orderId) async {
    final db = await database;
    final fittings = await db.query('fittings',
        columns: ['id'], where: 'order_id = ?', whereArgs: [orderId]);
    for (final f in fittings) {
      await NotificationService.instance.cancelFittingReminder(f['id'] as int);
    }
    await db.delete('fittings', where: 'order_id = ?', whereArgs: [orderId]);
  }

  Future<int> updateFitting(Fitting fitting) async {
    final db = await database;
    return await db.update(
      'fittings',
      fitting.toMap(),
      where: 'id = ?',
      whereArgs: [fitting.id],
    );
  }

  Future<int> deleteFitting(int id) async {
    final db = await database;
    return await db.delete('fittings', where: 'id = ?', whereArgs: [id]);
  }
}
