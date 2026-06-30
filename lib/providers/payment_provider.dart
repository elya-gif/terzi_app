import 'package:flutter_riverpod/legacy.dart';
import '../models/payment_record.dart';
import '../services/firestore_sync_service.dart';

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
    final payments =
        await FirestoreSyncService.instance.getPaymentsByOrder(orderId);
    state = payments;
  }

  Future<void> addPayment(PaymentRecord payment) async {
    final id = await FirestoreSyncService.instance.nextId('payments');
    final saved = PaymentRecord(
      id: id,
      orderId: payment.orderId,
      amount: payment.amount,
      paidAt: payment.paidAt,
    );
    state = [...state, saved];
    await FirestoreSyncService.instance.upsertPayment(saved);
  }

  void reload() => _load();
}
