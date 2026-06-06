import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/database_helper.dart';
import '../models/customer.dart';
import 'order_provider.dart';

final customerListProvider =
    NotifierProvider<CustomerNotifier, List<Customer>>(CustomerNotifier.new);

class CustomerNotifier extends Notifier<List<Customer>> {
  @override
  List<Customer> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final customers = await DatabaseHelper.instance.getAllCustomers();
    state = customers;
  }

  Future<void> addCustomer(Customer customer) async {
    final id = await DatabaseHelper.instance.insertCustomer(customer);
    final newCustomer = customer.copyWith(id: id);
    state = [...state, newCustomer]..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> updateCustomer(Customer customer) async {
    await DatabaseHelper.instance.updateCustomer(customer);
    state = state.map((c) => c.id == customer.id ? customer : c).toList();
  }

  Future<void> deleteCustomer(int id) async {
    await DatabaseHelper.instance.deleteCustomer(id);
    state = state.where((c) => c.id != id).toList();
  }
}

final orderCountProvider = Provider.family<int, int>((ref, customerId) {
  final orders = ref.watch(orderListProvider);
  return orders.where((o) => o.customerId == customerId).length;
});
