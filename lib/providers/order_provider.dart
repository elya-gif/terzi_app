import 'package:flutter_riverpod/legacy.dart';
import '../db/database_helper.dart';
import '../models/order.dart';

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
  }

  Future<void> updateOrder(Order order) async {
    await DatabaseHelper.instance.updateOrder(order);
    state = state.map((o) => o.id == order.id ? order : o).toList();
  }

  Future<void> updateStatus(Order order, OrderStatus status) async {
    final updated = order.copyWith(status: status);
    await DatabaseHelper.instance.updateOrder(updated);
    state = state.map((o) => o.id == order.id ? updated : o).toList();
  }

  Future<void> deleteOrder(int id) async {
    await DatabaseHelper.instance.deleteOrder(id);
    state = state.where((o) => o.id != id).toList();
  }
}
