import 'package:flutter_riverpod/legacy.dart';
import '../db/database_helper.dart';
import '../models/order.dart';
import '../services/notification_service.dart';

final orderListProvider =
    StateNotifierProvider<OrderNotifier, List<Order>>((ref) {
  return OrderNotifier();
});

class OrderNotifier extends StateNotifier<List<Order>> {
  OrderNotifier() : super([]) {
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
    // Teslim edildi ise bildirimi iptal et, aksi halde yeniden planla
    if (order.status == OrderStatus.delivered) {
      await NotificationService.instance.cancelReminder(order.id!);
    } else {
      await NotificationService.instance.cancelReminder(order.id!);
      await NotificationService.instance.scheduleDeliveryReminder(order);
    }
  }

  Future<void> updateStatus(Order order, OrderStatus status) async {
    final updated = order.copyWith(status: status);
    await DatabaseHelper.instance.updateOrder(updated);
    state = state.map((o) => o.id == order.id ? updated : o).toList();
    if (status == OrderStatus.delivered) {
      await NotificationService.instance.cancelReminder(order.id!);
    }
  }

  Future<void> deleteOrder(int id) async {
    await DatabaseHelper.instance.deleteOrder(id);
    await NotificationService.instance.cancelReminder(id);
    state = state.where((o) => o.id != id).toList();
  }
}
