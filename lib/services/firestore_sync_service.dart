import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/fitting.dart';
import '../models/measurement.dart';
import '../models/order.dart';
import '../models/payment_record.dart';

class FirestoreSyncService {
  static final FirestoreSyncService instance = FirestoreSyncService._();
  FirestoreSyncService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? _collection(String name) {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection(name);
  }

  Future<void> _upsert(String collection, String id, Map<String, dynamic> data) async {
    final ref = _collection(collection)?.doc(id);
    if (ref == null) return;
    try {
      await ref.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreSyncService upsert($collection/$id) failed: $e');
    }
  }

  Future<void> _delete(String collection, String id) async {
    final ref = _collection(collection)?.doc(id);
    if (ref == null) return;
    try {
      await ref.delete();
    } catch (e) {
      debugPrint('FirestoreSyncService delete($collection/$id) failed: $e');
    }
  }

  // --- ID üretimi (eski SQLite autoincrement yerine) ---
  /// `meta/counters` dokümanında transaction ile sıradaki int id'yi üretir.
  /// Sayaç yoksa koleksiyondaki mevcut max id'den seed eder (eski sync
  /// dokümanlarıyla çakışmayı önler). Dönen değer küçük int kalır;
  /// bildirim id aritmetiği (order.id+10000 vb.) bozulmaz.
  Future<int> nextId(String collection) async {
    final uid = _uid;
    if (uid == null) {
      // Oturum yoksa yazma yapılmaz; güvenli fallback (32-bit sınırında).
      return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
    final counterRef =
        _db.collection('users').doc(uid).collection('meta').doc('counters');
    return _db.runTransaction<int>((tx) async {
      final snap = await tx.get(counterRef);
      int current;
      final data = snap.data();
      if (snap.exists && data != null && data[collection] != null) {
        current = (data[collection] as num).toInt();
      } else {
        current = await _maxExistingId(uid, collection);
      }
      final next = current + 1;
      tx.set(counterRef, {collection: next}, SetOptions(merge: true));
      return next;
    });
  }

  Future<int> _maxExistingId(String uid, String collection) async {
    try {
      final q = await _db
          .collection('users')
          .doc(uid)
          .collection(collection)
          .orderBy('id', descending: true)
          .limit(1)
          .get();
      if (q.docs.isEmpty) return 0;
      return (q.docs.first.data()['id'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('FirestoreSyncService _maxExistingId($collection) failed: $e');
      return 0;
    }
  }

  // --- Okuma (eski DatabaseHelper.getX yerine) ---
  Future<List<Customer>> getAllCustomers() async {
    final coll = _collection('customers');
    if (coll == null) return [];
    final snap = await coll.get();
    final list = snap.docs.map((d) => Customer.fromMap(d.data())).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<List<Order>> getAllOrders() async {
    final coll = _collection('orders');
    if (coll == null) return [];
    final snap = await coll.get();
    final list = snap.docs.map((d) => Order.fromMap(d.data())).toList();
    list.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
    return list;
  }

  Future<List<Fitting>> getAllFittings() async {
    final coll = _collection('fittings');
    if (coll == null) return [];
    final snap = await coll.get();
    final list = snap.docs.map((d) => Fitting.fromMap(d.data())).toList();
    list.sort((a, b) => a.fittingDate.compareTo(b.fittingDate));
    return list;
  }

  Future<List<Fitting>> getFittings(int customerId) async {
    final coll = _collection('fittings');
    if (coll == null) return [];
    final snap =
        await coll.where('customer_id', isEqualTo: customerId).get();
    final list = snap.docs.map((d) => Fitting.fromMap(d.data())).toList();
    list.sort((a, b) => a.fittingDate.compareTo(b.fittingDate));
    return list;
  }

  Future<List<Measurement>> getMeasurements(int customerId) async {
    final coll = _collection('measurements');
    if (coll == null) return [];
    final snap =
        await coll.where('customer_id', isEqualTo: customerId).get();
    final list = snap.docs.map((d) => Measurement.fromMap(d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<PaymentRecord>> getPaymentsByOrder(int orderId) async {
    final coll = _collection('payments');
    if (coll == null) return [];
    final snap = await coll.where('order_id', isEqualTo: orderId).get();
    final list =
        snap.docs.map((d) => PaymentRecord.fromMap(d.data())).toList();
    list.sort((a, b) => a.paidAt.compareTo(b.paidAt));
    return list;
  }

  // --- Müşteri ---
  Future<void> upsertCustomer(Customer customer) =>
      _upsert('customers', customer.id.toString(), customer.toMap());

  Future<void> deleteCustomer(int id) => _delete('customers', id.toString());

  /// Müşteriyle ilişkili tüm sipariş/ölçü/prova/ödeme dokümanlarını siler,
  /// ardından müşteriyi siler. sqflite tarafındaki cascade silmeyle eşleşir.
  Future<void> deleteCustomerCascade(int customerId) async {
    final uid = _uid;
    if (uid == null) return;
    final userDoc = _db.collection('users').doc(uid);

    try {
      final orderDocs = await userDoc
          .collection('orders')
          .where('customer_id', isEqualTo: customerId)
          .get();
      final paymentDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final orderDoc in orderDocs.docs) {
        final ps = await userDoc
            .collection('payments')
            .where('order_id', isEqualTo: orderDoc.data()['id'])
            .get();
        paymentDocs.addAll(ps.docs);
      }
      final measurementDocs = await userDoc
          .collection('measurements')
          .where('customer_id', isEqualTo: customerId)
          .get();
      final fittingDocs = await userDoc
          .collection('fittings')
          .where('customer_id', isEqualTo: customerId)
          .get();

      final batch = _db.batch();
      for (final d in paymentDocs) {
        batch.delete(d.reference);
      }
      for (final d in orderDocs.docs) {
        batch.delete(d.reference);
      }
      for (final d in measurementDocs.docs) {
        batch.delete(d.reference);
      }
      for (final d in fittingDocs.docs) {
        batch.delete(d.reference);
      }
      batch.delete(userDoc.collection('customers').doc(customerId.toString()));
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreSyncService deleteCustomerCascade failed: $e');
    }
  }

  // --- Ölçü ---
  Future<void> upsertMeasurement(Measurement measurement) =>
      _upsert('measurements', measurement.id.toString(), measurement.toMap());

  // --- Sipariş ---
  Future<void> upsertOrder(Order order) =>
      _upsert('orders', order.id.toString(), order.toMap());

  Future<void> deleteOrder(int id) => _delete('orders', id.toString());

  // --- Prova ---
  Future<void> upsertFitting(Fitting fitting) =>
      _upsert('fittings', fitting.id.toString(), fitting.toMap());

  Future<void> deleteFitting(int id) => _delete('fittings', id.toString());

  Future<void> deleteFittingsByOrder(int orderId) async {
    final coll = _collection('fittings');
    if (coll == null) return;
    try {
      final docs = await coll.where('order_id', isEqualTo: orderId).get();
      if (docs.docs.isEmpty) return;
      final batch = _db.batch();
      for (final d in docs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreSyncService deleteFittingsByOrder failed: $e');
    }
  }

  // --- Ödeme ---
  Future<void> upsertPayment(PaymentRecord payment) =>
      _upsert('payments', payment.id.toString(), payment.toMap());

  Future<void> deletePaymentsByOrder(int orderId) async {
    final coll = _collection('payments');
    if (coll == null) return;
    try {
      final docs = await coll.where('order_id', isEqualTo: orderId).get();
      if (docs.docs.isEmpty) return;
      final batch = _db.batch();
      for (final d in docs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreSyncService deletePaymentsByOrder failed: $e');
    }
  }
}
