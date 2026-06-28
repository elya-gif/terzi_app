import 'package:flutter_riverpod/legacy.dart';
import '../db/database_helper.dart';
import '../models/payment_record.dart';

final paymentProvider = StateNotifierProvider.family<
    PaymentNotifier, List<PaymentRecord>, int>((ref, orderId) {
  return PaymentNotifier(orderId);
});

class PaymentNotifier extends StateNotifier<List<PaymentRecord>> {
  final int orderId;

  PaymentNotifier(this.orderId) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final payments = await DatabaseHelper.instance.getPaymentsByOrder(orderId);
    state = payments;
  }

  Future<void> addPayment(PaymentRecord payment) async {
    final id = await DatabaseHelper.instance.insertPayment(payment);
    state = [...state, PaymentRecord(
      id: id,
      orderId: payment.orderId,
      amount: payment.amount,
      paidAt: payment.paidAt,
    )];
  }

  void reload() => _load();
}
