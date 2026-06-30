import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/legacy.dart';
import '../models/order.dart';
import '../models/payment_record.dart';
import '../services/firestore_sync_service.dart';
import '../services/notification_service.dart';
import 'fitting_provider.dart';

final orderListProvider =
    StateNotifierProvider<OrderNotifier, List<Order>>((ref) {
  return OrderNotifier(ref);
});

class OrderNotifier extends StateNotifier<List<Order>> {
  final Ref _ref;
  OrderNotifier(this._ref) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final orders = await FirestoreSyncService.instance.getAllOrders();
    state = orders;
  }

  Future<void> addOrder(Order order) async {
    final id = await FirestoreSyncService.instance.nextId('orders');
    final newOrder = order.copyWith(id: id);
    state = [...state, newOrder]
      ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
    await NotificationService.instance.scheduleDeliveryReminder(newOrder);
    await FirestoreSyncService.instance.upsertOrder(newOrder);
  }

  Future<void> updateOrder(Order order) async {
    state = state.map((o) => o.id == order.id ? order : o).toList();
    await FirestoreSyncService.instance.upsertOrder(order);
    if (order.status == OrderStatus.delivered) {
      await NotificationService.instance.cancelReminder(order.id!);
      await FirestoreSyncService.instance.deleteFittingsByOrder(order.id!);
      _ref.read(allFittingsProvider.notifier).reload();
    } else {
      await NotificationService.instance.cancelReminder(order.id!);
      await NotificationService.instance.scheduleDeliveryReminder(order);
    }
  }

  Future<void> updateStatus(Order order, OrderStatus status, {double? paidAmount}) async {
    final updated = order.copyWith(status: status, paidAmount: paidAmount ?? order.paidAmount);
    state = state.map((o) => o.id == order.id ? updated : o).toList();
    await FirestoreSyncService.instance.upsertOrder(updated);
    if (status == OrderStatus.delivered) {
      await NotificationService.instance.cancelReminder(order.id!);
      await FirestoreSyncService.instance.deleteFittingsByOrder(order.id!);
      _ref.read(allFittingsProvider.notifier).reload();
    }
  }

  Future<void> addPaymentToOrder(Order order, double amount) async {
    final newPaid = (order.paidAmount + amount).clamp(0, order.price).toDouble();
    final updated = order.copyWith(paidAmount: newPaid);
    final paymentId =
        await FirestoreSyncService.instance.nextId('payments');
    final now = DateTime.now();
    state = state.map((o) => o.id == order.id ? updated : o).toList();
    await FirestoreSyncService.instance.upsertOrder(updated);
    await FirestoreSyncService.instance.upsertPayment(PaymentRecord(
      id: paymentId,
      orderId: order.id!,
      amount: amount,
      paidAt: now,
    ));
  }

  Future<void> deleteOrder(int id) async {
    await NotificationService.instance.cancelReminder(id);
    state = state.where((o) => o.id != id).toList();
    await FirestoreSyncService.instance.deletePaymentsByOrder(id);
    await FirestoreSyncService.instance.deleteOrder(id);
  }
}
