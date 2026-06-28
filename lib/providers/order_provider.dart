import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/legacy.dart';
import '../db/database_helper.dart';
import '../models/order.dart';
import '../models/payment_record.dart';
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
    final orders = await DatabaseHelper.instance.getAllOrders();
    state = orders;
  }

  Future<void> addOrder(Order order) async {
    final id = await DatabaseHelper.instance.insertOrder(order);
    final newOrder = order.copyWith(id: id);
    state = [...state, newOrder]
      ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
    await NotificationService.instance.scheduleDeliveryReminder(newOrder);
  }

  Future<void> updateOrder(Order order) async {
    await DatabaseHelper.instance.updateOrder(order);
    state = state.map((o) => o.id == order.id ? order : o).toList();
    if (order.status == OrderStatus.delivered) {
      await NotificationService.instance.cancelReminder(order.id!);
      await DatabaseHelper.instance.deleteFittingsByOrder(order.id!);
      _ref.read(allFittingsProvider.notifier).reload();
    } else {
      await NotificationService.instance.cancelReminder(order.id!);
      await NotificationService.instance.scheduleDeliveryReminder(order);
    }
  }

  Future<void> updateStatus(Order order, OrderStatus status, {double? paidAmount}) async {
    final updated = order.copyWith(status: status, paidAmount: paidAmount ?? order.paidAmount);
    await DatabaseHelper.instance.updateOrder(updated);
    state = state.map((o) => o.id == order.id ? updated : o).toList();
    if (status == OrderStatus.delivered) {
      await NotificationService.instance.cancelReminder(order.id!);
      await DatabaseHelper.instance.deleteFittingsByOrder(order.id!);
      _ref.read(allFittingsProvider.notifier).reload();
    }
  }

  Future<void> addPaymentToOrder(Order order, double amount) async {
    final newPaid = (order.paidAmount + amount).clamp(0, order.price).toDouble();
    final updated = order.copyWith(paidAmount: newPaid);
    await DatabaseHelper.instance.updateOrder(updated);
    await DatabaseHelper.instance.insertPayment(PaymentRecord(
      orderId: order.id!,
      amount: amount,
      paidAt: DateTime.now(),
    ));
    state = state.map((o) => o.id == order.id ? updated : o).toList();
  }

  Future<void> deleteOrder(int id) async {
    await DatabaseHelper.instance.deleteOrder(id);
    await NotificationService.instance.cancelReminder(id);
    state = state.where((o) => o.id != id).toList();
  }
}
